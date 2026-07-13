from rest_framework import serializers
from django.contrib.auth.hashers import make_password, check_password
from django.utils import timezone
from .models import Account, Caregiver, Elderly
import re

class RegisterSerialzier(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only = True)
    fullname = serializers.CharField()
    email = serializers.EmailField()
    phone = serializers.CharField()

    def validate_username(self, value):
        if Account.objects.filter(usename=value).exists():
            raise serializers.ValidationError("Tên đăng nhập đã tồn tại.")
        return value

    def validate_phone(self, value):
        digits = re.sub(r'\D', '', value)
        if len(digits) < 10 or len(digits) > 11:
            raise serializers.ValidationError("Số điện thoại phải có 10-11 chữ số.")
        if not digits.startswith('0'):
            raise serializers.ValidationError("Số điện thoại phải bắt đầu bằng số 0.")
        if Caregiver.objects.filter(phone=value).exists():
            raise serializers.ValidationError("Số điện thoại đã được đăng ký.")
        return value

    def validate_email(self, value):
        email_regex = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        if not email_regex.match(value):
            raise serializers.ValidationError("Email không đúng định dạng.")
        if Caregiver.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email đã được đăng ký.")
        return value

    def validate_password(self, value):
        if len(value) < 8:
            raise serializers.ValidationError("Mật khẩu phải có ít nhất 8 ký tự.")
        if not re.search(r'[A-Z]', value):
            raise serializers.ValidationError("Mật khẩu phải có ít nhất 1 chữ in hoa.")
        if not re.search(r'[a-z]', value):
            raise serializers.ValidationError("Mật khẩu phải có ít nhất 1 chữ in thường.")
        if not re.search(r'[0-9]', value):
            raise serializers.ValidationError("Mật khẩu phải có ít nhất 1 chữ số.")
        if not re.search(r'[!@#$%^&*()_+\-=\[\]{};:,.<>?/\\|`~]', value):
            raise serializers.ValidationError("Mật khẩu phải có ít nhất 1 ký tự đặc biệt.")
        return value
    
    def create(self, validated_data):
        account = Account.objects.create(
            usename=validated_data['username'],
            password=make_password(validated_data['password']),
            role='caregiver',
            created_at=timezone.now()
        )

        Caregiver.objects.create(
            accountid=account,
            fullname=validated_data['fullname'],
            email=validated_data['email'],
            phone=validated_data['phone']
        )

        return account

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only = True)

    def validate(self, data):
        try:
            user = Account.objects.get(usename=data['username'])
            if not check_password(data['password'], user.password):
                raise serializers.ValidationError("Tên đăng nhập hoặc mật khẩu không chính xác.")
        except Account.DoesNotExist:
            raise serializers.ValidationError("Tên đăng nhập hoặc mật khẩu không chính xác.")
        
        data['user'] = user
        return data

class GetAccountSerializer(serializers.ModelSerializer):
    class Meta:
        model = Account
        fields = ['id', 'username', 'role', 'created_at']