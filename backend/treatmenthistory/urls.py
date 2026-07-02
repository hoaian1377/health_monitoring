from django.urls import path
from . import views

urlpatterns = [
    # List & Create
    path('', views.TreatmentHistoryListView.as_view(), name='treatment-history-list'),
    path('create/', views.TreatmentHistoryCreateView.as_view(), name='treatment-history-create'),

    # Detail, Update, Delete
    path('<int:pk>/', views.TreatmentHistoryDetailView.as_view(), name='treatment-history-detail'),
    path('<int:pk>/update/', views.TreatmentHistoryUpdateView.as_view(), name='treatment-history-update'),
    path('<int:pk>/delete/', views.TreatmentHistoryDeleteView.as_view(), name='treatment-history-delete'),

    # Quick status update
    path('<int:pk>/status/', views.update_treatment_status, name='treatment-history-status'),
]
