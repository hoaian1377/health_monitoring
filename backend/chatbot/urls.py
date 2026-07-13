from django.urls import path
from . import views

urlpatterns = [
    path('', views.ElderlyChatbotView.as_view(), name='chatbot'),
]
