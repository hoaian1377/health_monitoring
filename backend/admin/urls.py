from django.urls import path
from .views import (
    DashboardStatsView,
    AdminUserListView,
    AdminUserDetailView,
    AdminUserStatusView,
    BackupListView,
    BackupRestoreView,
    LatestAlertsView,
    StatisticsChartView,
    DownloadBackupView,
)

urlpatterns = [
    path('dashboard-stats/', DashboardStatsView.as_view()),
    path('statistics-charts/', StatisticsChartView.as_view()),
    path('latest-alerts/', LatestAlertsView.as_view()),
    path('users/', AdminUserListView.as_view()),
    path('users/<int:user_id>/', AdminUserDetailView.as_view()),
    path('users/<int:user_id>/status/', AdminUserStatusView.as_view()),
    path('backups/', BackupListView.as_view()),
    path('backups/<str:filename>/download/', DownloadBackupView.as_view()),
    path('restore/<str:backup_id>/', BackupRestoreView.as_view()),
]
