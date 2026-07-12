from django.shortcuts import render
from rest_framework import generics, status
from rest_framework.response import Response
from django.contrib.auth.hashers import check_password, make_password
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
                    
                    gender_str = ''
                    if caregiver.gender is not None:
                        gender_str = 'Nam' if caregiver.gender else 'Nữ'

                    caregiver_info = {
                        'fullname': caregiver.fullname,
                        'email': caregiver.email,
                        'phone': caregiver.phone,
                        'gender': gender_str,
                        'dob': str(caregiver.date_of_birth) if caregiver.date_of_birth else '',
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
                "gender": "Nam" if elderly.gender else "Nu",
                "medical_note": elderly.medical_note,
                "blood_type": elderly.blood_type,
                "height": elderly.height,
                "weight": elderly.weight,
                "allergies": elderly.allergies,
                "underlying_conditions": elderly.underlying_conditions,
            }
        }, status=status.HTTP_200_OK)

# ── Lấy danh sách người cao tuổi của caregiver ─────────────────────────────
class GetElderlyListView(generics.RetrieveAPIView):
    """GET /api/users/elderly-list/?caregiver_account_id=<id>"""
    def get(self, request):
        caregiver_account_id = request.query_params.get('caregiver_account_id')
        if not caregiver_account_id:
            return Response({"error": "Thiếu caregiver_account_id"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            caregiver = Caregiver.objects.get(accountid=caregiver_account_id)
        except Caregiver.DoesNotExist:
            return Response({"error": "Caregiver not found"}, status=status.HTTP_404_NOT_FOUND)

        relations = CaregiverElderly.objects.filter(caregiverid=caregiver).select_related('elderlyid')
        elderly_list = []
        for rel in relations:
            e = rel.elderlyid
            if e:
                elderly_list.append({
                    "id": e.elderlyid,
                    "fullname": e.fullname,
                    "dob": str(e.date_of_birthday) if e.date_of_birthday else None,
                    "gender": "Nam" if e.gender else "Nu",
                    "medical_note": e.medical_note or "",
                    "blood_type": e.blood_type or "",
                    "height": e.height,
                    "weight": e.weight,
                    "allergies": e.allergies or "",
                    "underlying_conditions": e.underlying_conditions or "",
                    "qr_token": e.qr_token or "",
                })
        return Response({"elderly_list": elderly_list}, status=status.HTTP_200_OK)

# ── Cập nhật thông tin người cao tuổi ──────────────────────────────────────
class UpdateElderlyView(generics.UpdateAPIView):
    """PUT /api/users/elderly/<elderly_id>/update/"""
    def put(self, request, elderly_id):
        try:
            elderly = Elderly.objects.get(elderlyid=elderly_id)
        except Elderly.DoesNotExist:
            return Response({"error": "Không tìm thấy người cao tuổi"}, status=status.HTTP_404_NOT_FOUND)

        fullname = request.data.get('fullname', elderly.fullname)
        dob_str = request.data.get('dob')
        gender_str = request.data.get('gender')
        medical_note = request.data.get('medical_note', elderly.medical_note)
        blood_type = request.data.get('blood_type', elderly.blood_type)
        height = request.data.get('height', elderly.height)
        weight = request.data.get('weight', elderly.weight)
        allergies = request.data.get('allergies', elderly.allergies)
        underlying_conditions = request.data.get('underlying_conditions', elderly.underlying_conditions)

        if fullname:
            elderly.fullname = fullname
        if dob_str:
            try:
                elderly.date_of_birthday = datetime.strptime(dob_str, "%d/%m/%Y").date()
            except ValueError:
                pass
        if gender_str is not None:
            elderly.gender = (gender_str == 'Nam')
        elderly.medical_note = medical_note
        elderly.blood_type = blood_type
        elderly.height = height
        elderly.weight = weight
        elderly.allergies = allergies
        elderly.underlying_conditions = underlying_conditions
        elderly.save()

        return Response({
            "message": "Cap nhat thanh cong",
            "elderly": {
                "id": elderly.elderlyid,
                "fullname": elderly.fullname,
                "dob": str(elderly.date_of_birthday) if elderly.date_of_birthday else None,
                "gender": "Nam" if elderly.gender else "Nu",
                "medical_note": elderly.medical_note,
                "blood_type": elderly.blood_type,
                "height": elderly.height,
                "weight": elderly.weight,
                "allergies": elderly.allergies,
                "underlying_conditions": elderly.underlying_conditions,
                "qr_token": elderly.qr_token,
            }
        }, status=status.HTTP_200_OK)

# ── Đổi mật khẩu ───────────────────────────────────────────────────────────
class ChangePasswordView(generics.UpdateAPIView):
    """PUT /api/users/change-password/"""
    def put(self, request):
        account_id = request.data.get('account_id')
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')

        if not all([account_id, old_password, new_password]):
            return Response({"error": "Vui lòng cung cấp đủ thông tin"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            account = Account.objects.get(accountid=account_id)
        except Account.DoesNotExist:
            return Response({"error": "Tài khoản không tồn tại"}, status=status.HTTP_404_NOT_FOUND)

        if not check_password(old_password, account.password) and account.password != old_password:
            return Response({"error": "Mật khẩu hiện tại không đúng"}, status=status.HTTP_400_BAD_REQUEST)

        account.password = make_password(new_password)
        account.save()
        return Response({"message": "Đổi mật khẩu thành công"}, status=status.HTTP_200_OK)

# ── Quên mật khẩu ──────────────────────────────────────────────────────────
class ForgotPasswordView(generics.UpdateAPIView):
    """PUT /api/users/forgot-password/"""
    def put(self, request):
        phone = request.data.get('phone')
        new_password = request.data.get('new_password')

        if not all([phone, new_password]):
            return Response({"error": "Vui lòng cung cấp đủ thông tin"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            caregiver = Caregiver.objects.get(phone=phone)
            account = caregiver.accountid
            if not account:
                return Response({"error": "Tài khoản không tồn tại"}, status=status.HTTP_404_NOT_FOUND)
            
            account.password = make_password(new_password)
            account.save()
            return Response({"message": "Đặt lại mật khẩu thành công"}, status=status.HTTP_200_OK)
        except Caregiver.DoesNotExist:
            return Response({"error": "Số điện thoại chưa được đăng ký"}, status=status.HTTP_404_NOT_FOUND)

# ── Cập nhật hồ sơ Caregiver ───────────────────────────────────────────────
class UpdateCaregiverProfileView(generics.UpdateAPIView):
    """PUT /api/users/caregiver/update/"""
    def put(self, request):
        account_id = request.data.get('account_id')
        fullname = request.data.get('fullname')
        phone = request.data.get('phone')
        email = request.data.get('email')
        gender_str = request.data.get('gender')
        dob_str = request.data.get('dob')
        
        try:
            from .models import Caregiver
            caregiver = Caregiver.objects.get(accountid_id=account_id)
        except Caregiver.DoesNotExist:
            return Response({"error": "Không tìm thấy người chăm sóc"}, status=status.HTTP_404_NOT_FOUND)
            
        if fullname:
            caregiver.fullname = fullname
        if phone:
            caregiver.phone = phone
        if email:
            caregiver.email = email
            
        if gender_str is not None:
            caregiver.gender = (gender_str == 'Nam')
            
        if dob_str:
            try:
                caregiver.date_of_birth = datetime.strptime(dob_str, "%Y-%m-%d").date()
            except ValueError:
                pass
                
        caregiver.save()
        return Response({"message": "Cập nhật thành công"}, status=status.HTTP_200_OK)