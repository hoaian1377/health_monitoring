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

    class Meta:
        model = Appointment
        fields = '__all__'

    def get_documents(self, obj):
        docs = MedicalDocument.objects.filter(appointmentid=obj)
        return MedicalDocumentSerializer(docs, many=True).data
