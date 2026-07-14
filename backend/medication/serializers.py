from rest_framework import serializers
from .models import MedicalDocument, Medication, MedicationSchedule, Appointment

class MedicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medication
        fields = '__all__'

class MedicationScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicationSchedule
        fields = '__all__'

class MedicalDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicalDocument
        fields = '__all__'

class AppointmentSerializer(serializers.ModelSerializer):
    documents = serializers.SerializerMethodField()
    is_confirmed = serializers.SerializerMethodField()

    class Meta:
        model = Appointment
        fields = '__all__'

    def get_documents(self, obj):
        docs = MedicalDocument.objects.filter(appointmentid=obj)
        return MedicalDocumentSerializer(docs, many=True).data

    def get_is_confirmed(self, obj):
        # Appointment is confirmed if there's any document uploaded for it
        # or if the elderly confirmed it via ChecklistItem
        if MedicalDocument.objects.filter(appointmentid=obj).exists():
            return True
        from checklist.models import Checklist, ChecklistItem
        checklists = Checklist.objects.filter(appointmentid=obj)
        for cl in checklists:
            item = ChecklistItem.objects.filter(checklistid=cl, item_type='appointment').first()
            if item and item.is_complete:
                return True
        return False
