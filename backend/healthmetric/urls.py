from django.urls import path
from .views import HealthMetricCreateView, HealthMetricListView

urlpatterns = [
    path('create/', HealthMetricCreateView.as_view(), name='healthmetric-create'),
    path('list/', HealthMetricListView.as_view(), name='healthmetric-list'),
]