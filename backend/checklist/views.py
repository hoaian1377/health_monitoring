from rest_framework import generics, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from .models import Checklist, ChecklistItem
from .serializers import ChecklistSerializer, ChecklistItemSerializer


# ─── CHECKLIST VIEWS ───────────────────────────────────────────────────────────

class ChecklistCreateView(generics.CreateAPIView):
    """POST /api/checklist/create/"""
    queryset = Checklist.objects.all()
    serializer_class = ChecklistSerializer

    def perform_create(self, serializer):
        serializer.save(created_at=timezone.now())


class ChecklistListView(generics.ListAPIView):
    """GET /api/checklist/?appointment_id=<id>  hoặc  ?elderly_id=<id>"""
    serializer_class = ChecklistSerializer

    def get_queryset(self):
        qs = Checklist.objects.all()
        appointment_id = self.request.query_params.get('appointment_id')
        elderly_id = self.request.query_params.get('elderly_id')
        if appointment_id:
            qs = qs.filter(appointmentid_id=appointment_id)
        if elderly_id:
            qs = qs.filter(elderlyid_id=elderly_id)
        return qs.order_by('-created_at')


class ChecklistDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET/PUT/PATCH/DELETE /api/checklist/<pk>/"""
    queryset = Checklist.objects.all()
    serializer_class = ChecklistSerializer
    lookup_field = 'pk'


# ─── CHECKLIST ITEM VIEWS ──────────────────────────────────────────────────────

class ChecklistItemCreateView(generics.CreateAPIView):
    """POST /api/checklist/item/create/"""
    queryset = ChecklistItem.objects.all()
    serializer_class = ChecklistItemSerializer


class ChecklistItemListView(generics.ListAPIView):
    """GET /api/checklist/item/?checklist_id=<id>"""
    serializer_class = ChecklistItemSerializer

    def get_queryset(self):
        qs = ChecklistItem.objects.all()
        checklist_id = self.request.query_params.get('checklist_id')
        if checklist_id:
            qs = qs.filter(checklistid_id=checklist_id)
        return qs.order_by('checklist_itemid')


class ChecklistItemDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET/PUT/PATCH/DELETE /api/checklist/item/<pk>/"""
    queryset = ChecklistItem.objects.all()
    serializer_class = ChecklistItemSerializer
    lookup_field = 'pk'


@api_view(['POST'])
def toggle_checklist_item(request, pk):
    """POST /api/checklist/item/<pk>/toggle/
    Đổi trạng thái is_complete của một checklist item.
    """
    try:
        item = ChecklistItem.objects.get(pk=pk)
    except ChecklistItem.DoesNotExist:
        return Response({'error': 'Không tìm thấy checklist item.'}, status=status.HTTP_404_NOT_FOUND)

    item.is_complete = not item.is_complete
    item.save()
    return Response({
        'checklist_itemid': item.checklist_itemid,
        'is_complete': item.is_complete,
        'message': 'Đã hoàn thành' if item.is_complete else 'Đã bỏ hoàn thành',
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
def bulk_create_checklist_items(request, checklist_id):
    """POST /api/checklist/<checklist_id>/items/bulk/
    Tạo nhiều checklist items cùng lúc.
    Body: { "items": [{"content": "...", "note": "..."}, ...] }
    """
    try:
        checklist = Checklist.objects.get(pk=checklist_id)
    except Checklist.DoesNotExist:
        return Response({'error': 'Không tìm thấy checklist.'}, status=status.HTTP_404_NOT_FOUND)

    items_data = request.data.get('items', [])
    if not items_data:
        return Response({'error': 'Danh sách items trống.'}, status=status.HTTP_400_BAD_REQUEST)

    created = []
    for item_data in items_data:
        item = ChecklistItem.objects.create(
            checklistid=checklist,
            content=item_data.get('content', ''),
            note=item_data.get('note', ''),
            is_complete=False,
        )
        created.append({'checklist_itemid': item.checklist_itemid, 'content': item.content})

    return Response({
        'message': f'Đã tạo {len(created)} mục.',
        'items': created,
    }, status=status.HTTP_201_CREATED)
