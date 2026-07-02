from rest_framework import serializers
from .models import TreatmentHistory


class TreatmentHistorySerializer(serializers.ModelSerializer):
    elderly_name = serializers.SerializerMethodField()

    class Meta:
        model = TreatmentHistory
        fields = [
            'treatment_historyid',
            'elderlyid',
            'elderly_name',
            'diagnosis',
            'treatment',
            'treatment_type',
            'doctor_name',
            'hospital',
            'start_date',
            'end_date',
            'result',
            'notes',
            'status',
            'created_at',
        ]

    def get_elderly_name(self, obj):
        return obj.elderlyid.fullname if obj.elderlyid else None
