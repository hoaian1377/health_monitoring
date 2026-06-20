from django.shortcuts import render
from rest_framework import generics, status
from rest_framework.response import Response
from .serializers import RegisterSerialzier, LoginSerializer
from rest_framework_simplejwt.tokens import RefreshToken, AccessToken
from .models import Account
# Create your views here.

class RegisterView(generics.CreateAPIView):
    queryset = Account.objects.all()
    serializer_class = RegisterSerialzier

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        return Response(
            {"message":"Đăng ký thành công"},
             status=status.HTTP_201_CREATED
        )

class LoginView(generics.CreateAPIView):
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            # Patch id so simplejwt works with custom user model
            user.id = user.accountid
            refresh = RefreshToken.for_user(user)
            access = AccessToken.for_user(user)
            return Response({
                'message':'Đăng nhập thành công',  
                'user':{'id':user.accountid, 'username':user.usename, 'role':user.role, 'created_at':user.created_at},          
                'access_token': str(access),
                'refresh_token': str(refresh),
            },status = status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)