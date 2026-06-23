from django.urls import path
from . import views

urlpatterns = [
    path('', views.getmedication, name='getmedication'),
    path('schedule/', views.getmedicationschedule, name='getmedicationschedule'),
    path('document/', views.getmedicaldocument, name='getmedicaldocument'),
]
