from django.urls import path
from .views import (
    DashboardStatsView,
    AdminUserListView,
    AdminUserDetailView,
    AdminUserStatusView,
    BackupListView,
    BackupRestoreView,
    LatestAlertsView,
)

urlpatterns = [
    path('dashboard-stats/', DashboardStatsView.as_view()),
    path('latest-alerts/', LatestAlertsView.as_view()),
    path('users/', AdminUserListView.as_view()),
    path('users/<int:user_id>/', AdminUserDetailView.as_view()),
    path('users/<int:user_id>/status/', AdminUserStatusView.as_view()),
    path('backups/', BackupListView.as_view()),
    path('restore/<int:backup_id>/', BackupRestoreView.as_view()),
]
