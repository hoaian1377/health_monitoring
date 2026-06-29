from django.urls import path
from . import views

urlpatterns = [
    path('notifications/', views.NotificationListView.as_view(), name='notification_list'),
    path('notifications/<int:pk>/', views.NotificationDetailView.as_view(), name='notification_detail'),
    path('generate-mock/', views.GenerateMockNotificationsView.as_view(), name='generate_mock_notifications'),
]