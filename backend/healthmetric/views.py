from rest_framework import generics, status
from rest_framework.response import Response
from django.utils import timezone
from .models import HealthMetrics
from .serializers import HealthMetricsSerializer

class HealthMetricCreateView(generics.CreateAPIView):
    queryset = HealthMetrics.objects.all()
    serializer_class = HealthMetricsSerializer

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        if not data.get('recorded_at'):
            data['recorded_at'] = timezone.now()
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

class HealthMetricListView(generics.ListAPIView):
    serializer_class = HealthMetricsSerializer

    def get_queryset(self):
        queryset = HealthMetrics.objects.all()
        elderly_id = self.request.query_params.get('elderly_id', None)
        if elderly_id is not None:
            queryset = queryset.filter(elderlyid_id=elderly_id)
        return queryset.order_by('-recorded_at')
