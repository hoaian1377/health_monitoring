from rest_framework import generics, status
from rest_framework.response import Response
from .models import Notification, NotificationDetail
from .serializers import NotificationSerializer, NotificationDetailSerializer
import datetime

class NotificationListView(generics.ListAPIView):
    """GET /api/notification/notifications/?caregiver_id=<id> hoặc ?elderly_id=<id>"""
    serializer_class = NotificationSerializer

    def get_queryset(self):
        caregiver_id = self.request.query_params.get('caregiver_id')
        elderly_id = self.request.query_params.get('elderly_id')

        if caregiver_id:
            return Notification.objects.filter(caregiverid=caregiver_id).order_by('-created_at')
        elif elderly_id:
            from users.models import CaregiverElderly
            caregivers = CaregiverElderly.objects.filter(elderlyid=elderly_id).values_list('caregiverid', flat=True)
            return Notification.objects.filter(caregiverid__in=caregivers).order_by('-created_at')
        return Notification.objects.all().order_by('-created_at')

class NotificationDetailView(generics.UpdateAPIView):
    """PUT /api/notification/notifications/<pk>/"""
    serializer_class = NotificationDetailSerializer
    queryset = NotificationDetail.objects.all()

    def put(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            instance.is_read = True
            instance.read_at = datetime.datetime.now()
            instance.save()
            return Response({"message": "Đã đánh dấu là đã đọc"}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class GenerateMockNotificationsView(generics.CreateAPIView):
    """POST /api/notification/generate-mock/?caregiver_id=<id> hoặc ?elderly_id=<id>"""
    def post(self, request):
        caregiver_id = request.query_params.get('caregiver_id')
        elderly_id = request.query_params.get('elderly_id')

        if not caregiver_id and elderly_id:
            from users.models import CaregiverElderly
            caregiver_id = CaregiverElderly.objects.filter(elderlyid=elderly_id).values_list('caregiverid', flat=True).first()

        if not caregiver_id:
            return Response({"error": "Thiếu caregiver_id hoặc elderly_id hợp lệ"}, status=status.HTTP_400_BAD_REQUEST)
        
        notif1 = Notification.objects.create(
            caregiverid_id=caregiver_id,
            title="Nhắc nhở uống thuốc",
            message="Người thân của bạn có lịch uống thuốc (Paracetamol) vào lúc 14:00 nhưng chưa xác nhận uống.",
            created_at=datetime.datetime.now()
        )
        NotificationDetail.objects.create(notificationid=notif1, is_read=False)

        notif2 = Notification.objects.create(
            caregiverid_id=caregiver_id,
            title="Chỉ số sinh tồn bất thường",
            message="Nhịp tim của người thân đang ở mức cao (110 bpm). Vui lòng kiểm tra ngay.",
            created_at=datetime.datetime.now()
        )
        NotificationDetail.objects.create(notificationid=notif2, is_read=False)
        
        return Response({"message": "Đã tạo thông báo giả lập thành công!"}, status=status.HTTP_201_CREATED)

class NotifyMissedMedicationView(generics.CreateAPIView):
    """POST /api/notification/notify-missed/
    Body: {"elderly_id": int, "medication_name": str}
    """
    def post(self, request):
        elderly_id = request.data.get('elderly_id')
        medication_name = request.data.get('medication_name')

        if not elderly_id or not medication_name:
            return Response({"error": "Thiếu elderly_id hoặc medication_name"}, status=status.HTTP_400_BAD_REQUEST)

        from users.models import CaregiverElderly
        caregiver_id = CaregiverElderly.objects.filter(elderlyid=elderly_id).values_list('caregiverid', flat=True).first()

        if not caregiver_id:
            return Response({"error": "Không tìm thấy caregiver cho elderly này"}, status=status.HTTP_404_NOT_FOUND)

        # Tránh tạo trùng lặp thông báo nếu đã gửi trong vòng 1 tiếng
        recent_notifs = Notification.objects.filter(
            caregiverid_id=caregiver_id,
            title="Quên uống thuốc",
            message__contains=medication_name,
            created_at__gte=datetime.datetime.now() - datetime.timedelta(hours=1)
        )
        
        if recent_notifs.exists():
            return Response({"message": "Đã gửi thông báo gần đây, bỏ qua."}, status=status.HTTP_200_OK)

        notif = Notification.objects.create(
            caregiverid_id=caregiver_id,
            title="Quên uống thuốc",
            message=f"Bác chưa xác nhận đã uống thuốc '{medication_name}' theo lịch. Hãy nhắc nhở bác!",
            created_at=datetime.datetime.now()
        )
        NotificationDetail.objects.create(notificationid=notif, is_read=False)

        return Response({"message": "Đã gửi thông báo quên uống thuốc cho Caregiver!"}, status=status.HTTP_201_CREATED)

