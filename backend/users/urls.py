from django.urls import path
from .views import RegisterView, LoginView, CreateElderlyView, LoginByQrView, GetElderlyListView, UpdateElderlyView

urlpatterns = [
    path('register/', RegisterView.as_view()),
    path('login/', LoginView.as_view()),
    path('elderly/', CreateElderlyView.as_view()),
    path('elderly-list/', GetElderlyListView.as_view()),
    path('elderly/<int:elderly_id>/update/', UpdateElderlyView.as_view()),
    path('login-qr/', LoginByQrView.as_view()),
]