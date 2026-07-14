from django.shortcuts import render
from rest_framework import generics, status
from rest_framework.response import Response
from django.contrib.auth.hashers import check_password, make_password
from .serializers import RegisterSerialzier, LoginSerializer
from rest_framework_simplejwt.tokens import RefreshToken, AccessToken
from .models import Account
from datetime import timedelta
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
            
            if serializer.validated_data.get('remember_me', False):
                refresh.set_exp(lifetime=timedelta(days=30))
                
            access = AccessToken.for_user(user)

            # Fetch info based on role
            user_info = {}
            if user.role and user.role.lower() == 'caregiver':
                try:
                    from .models import Caregiver
                    caregiver = Caregiver.objects.get(accountid=user.accountid)
                    
                    gender_str = ''
                    if caregiver.gender is not None:
                        gender_str = 'Nam' if caregiver.gender else 'Nữ'

                    user_info = {
                        'fullname': caregiver.fullname,
                        'email': caregiver.email,
                        'phone': caregiver.phone,
                        'gender': gender_str,
                        'dob': str(caregiver.date_of_birth) if caregiver.date_of_birth else '',
                    }
                except Caregiver.DoesNotExist:
                    pass
            elif user.role and user.role.lower() == 'elderly':
                try:
                    from .models import Elderly
                    elderly = Elderly.objects.get(accountid=user.accountid)
                    
                    gender_str = ''
                    if elderly.gender is not None:
                        gender_str = 'Nam' if elderly.gender else 'Nữ'

                    user_info = {
                        'elderly_id': elderly.elderlyid,
                        'fullname': elderly.fullname,
                        'gender': gender_str,
                        'dob': str(elderly.date_of_birthday) if elderly.date_of_birthday else '',
                    }
                except Elderly.DoesNotExist:
                    pass

            return Response({
                'message':'Đăng nhập thành công',  
                'user':{
                    'id': user.accountid,
                    'username': user.usename,
                    'role': user.role,
                    'created_at': user.created_at,
                    **user_info,
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
        raw_password = request.data.get('password', '')
        username = request.data.get('username')

        if not username or not raw_password:
            return Response({"error": "Thiếu tên đăng nhập hoặc mật khẩu"}, status=status.HTTP_400_BAD_REQUEST)

        # Check if username exists
        if Account.objects.filter(usename=username).exists():
            return Response({"error": "Tên đăng nhập đã tồn tại"}, status=status.HTTP_400_BAD_REQUEST)

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
        from django.contrib.auth.hashers import make_password

        # Create Account
        account = Account.objects.create(
            usename=username,
            password=make_password(raw_password),
            role='elderly',
            created_at=tz.now()
        )

        elderly = Elderly.objects.create(
            accountid=account,
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
                    "allergies": e.allergies or "",
                    "underlying_conditions": e.underlying_conditions or "",
                    "qr_token": e.qr_token or "",
                    "username": e.accountid.usename if e.accountid else "",
                })
        return Response({"elderly_list": elderly_list}, status=status.HTTP_200_OK)

# ── Cập nhật thông tin người cao tuổi ──────────────────────────────────────
class UpdateElderlyView(generics.UpdateAPIView):
    """GET/PUT /api/users/elderly/<elderly_id>/update/"""
    def get(self, request, elderly_id):
        try:
            e = Elderly.objects.get(elderlyid=elderly_id)
            return Response({
                "id": e.elderlyid,
                "fullname": e.fullname,
                "dob": str(e.date_of_birthday) if e.date_of_birthday else None,
                "gender": "Nam" if e.gender else "Nu",
                "medical_note": e.medical_note or "",
                "blood_type": e.blood_type or "",
                "allergies": e.allergies or "",
                "underlying_conditions": e.underlying_conditions or "",
                "qr_token": e.qr_token or "",
                "username": e.accountid.usename if e.accountid else "",
            }, status=status.HTTP_200_OK)
        except Elderly.DoesNotExist:
            return Response({"error": "Không tìm thấy người cao tuổi"}, status=status.HTTP_404_NOT_FOUND)

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
        
        raw_password = request.data.get('password')
        raw_username = request.data.get('username')
        
        if elderly.accountid:
            update_data = {}
            if raw_password:
                from django.contrib.auth.hashers import make_password
                update_data['password'] = make_password(raw_password)
            if raw_username:
                # Check if username exists and not the same
                if elderly.accountid.usename != raw_username and Account.objects.filter(usename=raw_username).exists():
                    return Response({"error": "Tên đăng nhập đã tồn tại"}, status=status.HTTP_400_BAD_REQUEST)
                update_data['usename'] = raw_username
            if update_data:
                Account.objects.filter(accountid=elderly.accountid.accountid).update(**update_data)
        else:
            if raw_username:
                if not raw_password:
                    return Response({"error": "Vui lòng nhập mật khẩu mới khi tạo tên đăng nhập"}, status=status.HTTP_400_BAD_REQUEST)
                from django.utils import timezone as tz
                from django.contrib.auth.hashers import make_password
                if Account.objects.filter(usename=raw_username).exists():
                    return Response({"error": "Tên đăng nhập đã tồn tại"}, status=status.HTTP_400_BAD_REQUEST)
                new_account = Account.objects.create(
                    usename=raw_username,
                    password=make_password(raw_password),
                    role='elderly',
                    created_at=tz.now()
                )
                elderly.accountid = new_account
        elderly.medical_note = medical_note
        elderly.blood_type = blood_type
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

        # Sử dụng update trực tiếp để đảm bảo lưu thay đổi vào DB thật
        Account.objects.filter(accountid=account.accountid).update(password=make_password(new_password))
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
            
            # Sử dụng update trực tiếp để đảm bảo lưu thay đổi vào DB thật
            Account.objects.filter(accountid=account.accountid).update(password=make_password(new_password))
            
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

# ── Lấy danh sách Người chăm sóc của Người cao tuổi ────────────────────────────
class GetCaregiversForElderlyView(generics.RetrieveAPIView):
    """GET /api/users/elderly/<int:elderly_id>/caregivers/"""
    def get(self, request, elderly_id):
        try:
            from .models import Elderly, CaregiverElderly
            elderly = Elderly.objects.get(elderlyid=elderly_id)
        except Elderly.DoesNotExist:
            return Response({"error": "Không tìm thấy Người cao tuổi"}, status=status.HTTP_404_NOT_FOUND)

        relations = CaregiverElderly.objects.filter(elderlyid=elderly).select_related('caregiverid')
        caregiver_list = []
        for rel in relations:
            c = rel.caregiverid
            if c:
                caregiver_list.append({
                    "id": c.caregiverid,
                    "fullname": c.fullname,
                    "phone": c.phone,
                    "email": c.email,
                })
        
        return Response({"caregivers": caregiver_list}, status=status.HTTP_200_OK)
