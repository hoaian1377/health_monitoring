from rest_framework import generics, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from users.models import Elderly
from .models import TreatmentHistory
from .serializers import TreatmentHistorySerializer


class TreatmentHistoryListView(generics.ListAPIView):
    """GET /api/treatmenthistory/?elderly_id=<id>
    Lấy danh sách lịch sử điều trị của một người cao tuổi.
    """
    serializer_class = TreatmentHistorySerializer

    def get_queryset(self):
        qs = TreatmentHistory.objects.all()
        elderly_id = self.request.query_params.get('elderly_id')
        status_filter = self.request.query_params.get('status')
        if elderly_id:
            qs = qs.filter(elderlyid_id=elderly_id)
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs.order_by('-start_date')


class TreatmentHistoryCreateView(generics.CreateAPIView):
    serializer_class = TreatmentHistorySerializer

    def post(self, request):
        elderly_id = request.data.get('elderly_id')
        if not elderly_id:
            return Response({'error': 'Thiếu elderly_id.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            elderly = Elderly.objects.get(elderlyid=elderly_id)
        except Elderly.DoesNotExist:
            return Response({'error': 'Không tìm thấy người cao tuổi.'}, status=status.HTTP_404_NOT_FOUND)

        record = TreatmentHistory.objects.create(
            elderlyid=elderly,
            diagnosis=request.data.get('diagnosis', ''),
            treatment=request.data.get('treatment', ''),
            treatment_type=request.data.get('treatment_type', ''),
            doctor_name=request.data.get('doctor_name', ''),
            hospital=request.data.get('hospital', ''),
            start_date=request.data.get('start_date'),
            end_date=request.data.get('end_date'),
            result=request.data.get('result', ''),
            notes=request.data.get('notes', ''),
            status=request.data.get('status', 'ongoing'),
            created_at=timezone.now(),
        )

        serializer = TreatmentHistorySerializer(record)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class TreatmentHistoryDetailView(generics.RetrieveAPIView):
    """GET /api/treatmenthistory/<pk>/
    Lấy chi tiết một bản ghi lịch sử điều trị.
    """
    queryset = TreatmentHistory.objects.all()
    serializer_class = TreatmentHistorySerializer
    lookup_field = 'pk'


class TreatmentHistoryUpdateView(generics.UpdateAPIView):
    """PUT/PATCH /api/treatmenthistory/<pk>/update/
    Cập nhật lịch sử điều trị.
    """
    queryset = TreatmentHistory.objects.all()
    serializer_class = TreatmentHistorySerializer
    lookup_field = 'pk'

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        allowed_fields = [
            'diagnosis', 'treatment', 'treatment_type', 'doctor_name',
            'hospital', 'start_date', 'end_date', 'result', 'notes', 'status',
        ]
        for field in allowed_fields:
            if field in request.data:
                setattr(instance, field, request.data[field])
        instance.save()
        return Response(TreatmentHistorySerializer(instance).data, status=status.HTTP_200_OK)


class TreatmentHistoryDeleteView(generics.DestroyAPIView):
    """DELETE /api/treatmenthistory/<pk>/delete/
    Xoá một bản ghi lịch sử điều trị.
    """
    queryset = TreatmentHistory.objects.all()
    serializer_class = TreatmentHistorySerializer
    lookup_field = 'pk'

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response({'message': 'Đã xoá lịch sử điều trị.'}, status=status.HTTP_200_OK)


@api_view(['POST'])
def update_treatment_status(request, pk):
    """POST /api/treatmenthistory/<pk>/status/
    Cập nhật nhanh trạng thái: ongoing | completed | cancelled
    Body: { "status": "completed" }
    """
    try:
        record = TreatmentHistory.objects.get(pk=pk)
    except TreatmentHistory.DoesNotExist:
        return Response({'error': 'Không tìm thấy bản ghi.'}, status=status.HTTP_404_NOT_FOUND)

    new_status = request.data.get('status')
    valid = ['ongoing', 'completed', 'cancelled']
    if new_status not in valid:
        return Response(
            {'error': f'Trạng thái không hợp lệ. Chọn một trong: {valid}'},
            status=status.HTTP_400_BAD_REQUEST
        )

    record.status = new_status
    if new_status == 'completed' and not record.end_date:
        from datetime import date
        record.end_date = date.today()
    record.save()

    return Response({
        'treatment_historyid': record.treatment_historyid,
        'status': record.status,
        'end_date': str(record.end_date) if record.end_date else None,
        'message': f'Đã cập nhật trạng thái thành "{new_status}".',
    }, status=status.HTTP_200_OK)
