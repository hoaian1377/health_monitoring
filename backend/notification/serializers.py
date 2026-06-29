from rest_framework import serializers
from .models import Notification, NotificationDetail

class NotificationDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationDetail
        fields = '__all__'

class NotificationSerializer(serializers.ModelSerializer):
    # Depending on how the related_name is defined in Django models. DO_NOTHING means no default reverse relation, but let's just serialize Notification for now.
    class Meta:
        model = Notification
        fields = '__all__'
