from rest_framework import serializers
from django.contrib.auth.hashers import make_password, check_password
from django.utils import timezone
from .models import Account, Caregiver, Elderly

class RegisterSerialzier(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only = True)
    fullname = serializers.CharField()
    email = serializers.EmailField()
    phone = serializers.CharField()
    
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