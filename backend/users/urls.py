from django.urls import path
from .views import RegisterView, LoginView, CreateElderlyView, LoginByQrView
urlpatterns = [
    path('register/',RegisterView.as_view()),
    path('login/', LoginView.as_view()),
    path('elderly/', CreateElderlyView.as_view()),
    path('login-qr/', LoginByQrView.as_view()),
]