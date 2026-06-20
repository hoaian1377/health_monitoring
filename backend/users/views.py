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

            # Fetch caregiver info
            caregiver_info = {}
            if user.role and user.role.lower() == 'caregiver':
                try:
                    from .models import Caregiver
                    caregiver = Caregiver.objects.get(accountid=user.accountid)
                    caregiver_info = {
                        'fullname': caregiver.fullname,
                        'email': caregiver.email,
                        'phone': caregiver.phone,
                    }
                except Caregiver.DoesNotExist:
                    pass

            return Response({
                'message':'Đăng nhập thành công',  
                'user':{
                    'id': user.accountid,
                    'username': user.usename,
                    'role': user.role,
                    'created_at': user.created_at,
                    **caregiver_info,
                },
                'access_token': str(access),
                'refresh_token': str(refresh),
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

import uuid
from datetime import datetime
from .models import Elderly, CaregiverElderly, Caregiver

class CreateElderlyView(generics.CreateAPIView):
    def post(self, request):
        caregiver_account_id = request.data.get('caregiver_account_id')
        fullname = request.data.get('fullname')
        dob_str = request.data.get('dob') # Expected: dd/mm/yyyy
        gender_str = request.data.get('gender')
        medical_note = request.data.get('medical_note', '')

        try:
            caregiver = Caregiver.objects.get(accountid=caregiver_account_id)
        except Caregiver.DoesNotExist:
            return Response({"error": "Caregiver not found"}, status=status.HTTP_404_NOT_FOUND)

        dob = None
        if dob_str:
            try:
                dob = datetime.strptime(dob_str, "%d/%m/%Y").date()
            except ValueError:
                pass
        
        is_male = (gender_str == 'Nam')
        qr_token = str(uuid.uuid4())
        from datetime import timedelta
        from django.utils import timezone as tz

        elderly = Elderly.objects.create(
            fullname=fullname,
            date_of_birthday=dob,
            gender=is_male,
            medical_note=medical_note,
            qr_token=qr_token,
            qr_expired_at=tz.now() + timedelta(days=365 * 100)  # QR cố định, hạn 100 năm
        )

        CaregiverElderly.objects.create(
            caregiverid=caregiver,
            elderlyid=elderly
        )

        return Response({
            "message": "Tạo hồ sơ thành công",
            "qr_token": qr_token
        }, status=status.HTTP_201_CREATED)

class LoginByQrView(generics.CreateAPIView):
    def post(self, request):
        qr_token = request.data.get('qr_token')
        if not qr_token:
            return Response({"error": "Thiếu qr_token"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            elderly = Elderly.objects.get(qr_token=qr_token)
        except Elderly.DoesNotExist:
            return Response({"error": "Mã QR không hợp lệ hoặc đã hết hạn."}, status=status.HTTP_404_NOT_FOUND)
        
        return Response({
            "message": "Đăng nhập thành công",
            "elderly": {
                "id": elderly.elderlyid,
                "fullname": elderly.fullname,
                "dob": str(elderly.date_of_birthday) if elderly.date_of_birthday else None,
                "gender": "Nam" if elderly.gender else "Nữ",
                "medical_note": elderly.medical_note,
            }
        }, status=status.HTTP_200_OK)