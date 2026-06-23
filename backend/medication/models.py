from django.db import models
from users.models import Elderly

class Appointment(models.Model):
    appointmentid = models.AutoField(db_column='appointmentID', primary_key=True)
    elderlyid = models.ForeignKey(Elderly, models.DO_NOTHING, db_column='elderlyID', blank=True, null=True)
    appointment_date = models.DateField(blank=True, null=True)
    appointment_time = models.TimeField(blank=True, null=True)
    doctor_name = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    location = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    note = models.TextField(db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Appointment'

# Create your models here.
class MedicalDocument(models.Model):
    medical_documentid = models.AutoField(db_column='medical_documentID', primary_key=True)  # Field name made lowercase.
    elderlyid = models.ForeignKey(Elderly, models.DO_NOTHING, db_column='elderlyID', blank=True, null=True)  # Field name made lowercase.
    appointmentid = models.ForeignKey(Appointment, models.DO_NOTHING, db_column='appointmentID', blank=True, null=True)  # Field name made lowercase.
    document_type = models.CharField(max_length=50, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    file_url = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    upload_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Medical_document'


class Medication(models.Model):
    medicationid = models.AutoField(db_column='medicationID', primary_key=True)  # Field name made lowercase.
    name = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    dosage = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    instruction = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    description = models.TextField(db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)  # This field type is a guess.

    class Meta:
        managed = False
        db_table = 'Medication'


class MedicationSchedule(models.Model):
    medication_scheduleid = models.AutoField(db_column='medication_scheduleID', primary_key=True)  # Field name made lowercase.
    medicationid = models.ForeignKey(Medication, models.DO_NOTHING, db_column='medicationID', blank=True, null=True)  # Field name made lowercase.
    elderlyid = models.ForeignKey(Elderly, models.DO_NOTHING, db_column='elderlyID', blank=True, null=True)  # Field name made lowercase.
    time = models.TimeField(blank=True, null=True)
    frequency = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    start_date = models.DateTimeField(blank=True, null=True)
    end_date = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Medication_schedule'