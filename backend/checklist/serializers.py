from rest_framework import serializers
from .models import Checklist, ChecklistItem


class ChecklistItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChecklistItem
        fields = [
            'checklist_itemid',
            'checklistid',
            'content',
            'is_complete',
            'note',
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
