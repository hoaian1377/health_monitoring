from django.urls import path
from . import views

urlpatterns = [
    # Legacy routes
    path('', views.getmedication, name='getmedication'),
    path('schedule/', views.getmedicationschedule, name='getmedicationschedule'),
    path('document/', views.getmedicaldocument, name='getmedicaldocument'),
    
    # New API routes
    path('elderly-schedule/', views.ElderlyMedicationScheduleView.as_view(), name='elderly_schedule'),
    path('create/', views.CreateMedicationView.as_view(), name='create_medication'),
    path('schedule/<int:schedule_id>/update/', views.UpdateMedicationView.as_view(), name='update_medication'),
    path('schedule/<int:schedule_id>/delete/', views.DeleteMedicationView.as_view(), name='delete_medication'),
    path('scan-prescription/', views.ScanPrescriptionView.as_view(), name='scan_prescription'),
    path('appointment/create/', views.CreateAppointmentView.as_view(), name='create_appointment'),
    path('appointment/list/', views.AppointmentListView.as_view(), name='list_appointment'),
    path('appointment/<int:pk>/update/', views.UpdateAppointmentView.as_view(), name='update_appointment'),
    path('appointment/<int:pk>/delete/', views.DeleteAppointmentView.as_view(), name='delete_appointment'),
    path('elderly-document/list/', views.ElderlyMedicalDocumentListView.as_view(), name='list_elderly_document'),
    path('elderly-document/upload/', views.UploadMedicalDocumentView.as_view(), name='upload_elderly_document'),
    path('chatbot/', views.ElderlyChatbotView.as_view(), name='elderly_chatbot'),
]
