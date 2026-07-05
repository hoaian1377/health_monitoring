from django.db import models
from medication.models import Appointment
from users.models import Elderly




class Checklist(models.Model):
    checklistid = models.AutoField(db_column='checklistID', primary_key=True)  # Field name made lowercase.
    elderlyid = models.ForeignKey(Elderly, models.DO_NOTHING, db_column='elderlyID')  # Field name made lowercase.
    appointmentid = models.ForeignKey(Appointment, models.DO_NOTHING, db_column='appointmentID', blank=True, null=True)  # Field name made lowercase.
    title = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Checklist'


class ChecklistItem(models.Model):
    checklist_itemid = models.AutoField(db_column='checklist_itemID', primary_key=True)  # Field name made lowercase.
    checklistid = models.ForeignKey(Checklist, models.DO_NOTHING, db_column='checklistID')  # Field name made lowercase.
    title = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS')
    item_type = models.CharField(max_length=50, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    time_string = models.CharField(max_length=50, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    details = models.TextField(db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    is_complete = models.BooleanField(blank=True, null=True)
    hospital = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    doctor = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    appointment_date = models.DateTimeField(blank=True, null=True)
    file_path = models.CharField(max_length=500, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Checklist_item'

