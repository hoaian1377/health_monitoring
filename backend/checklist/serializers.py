from rest_framework import serializers
from .models import Checklist, ChecklistItem


class ChecklistItemSerializer(serializers.ModelSerializer):
    appointment_id = serializers.IntegerField(source='checklistid.appointmentid_id', read_only=True)

    class Meta:
        model = ChecklistItem
        fields = [
            'checklist_itemid',
            'checklistid',
            'title',
            'item_type',
            'time_string',
            'details',
            'is_complete',
            'hospital',
            'doctor',
            'appointment_date',
            'file_path',
            'appointment_id',
        ]


class ChecklistSerializer(serializers.ModelSerializer):
    items = ChecklistItemSerializer(
        source='checklistitem_set', many=True, read_only=True
    )

    class Meta:
        model = Checklist
        fields = [
            'checklistid',
            'appointmentid',
            'elderlyid',
            'title',
            'created_at',
            'items',
        ]
