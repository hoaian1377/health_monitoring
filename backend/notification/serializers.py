from rest_framework import serializers
from .models import Notification, NotificationDetail

class NotificationDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationDetail
        fields = '__all__'

class NotificationSerializer(serializers.ModelSerializer):
    details = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = '__all__'

    def get_details(self, obj):
        details = NotificationDetail.objects.filter(notificationid=obj)
        return NotificationDetailSerializer(details, many=True).data
