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

