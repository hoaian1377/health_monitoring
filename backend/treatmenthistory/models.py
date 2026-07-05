from django.db import models
from users.models import Elderly


class TreatmentHistory(models.Model):
    treatment_historyid = models.AutoField(db_column='treatment_historyID', primary_key=True)  # Field name made lowercase.
    elderlyid = models.ForeignKey(Elderly, models.DO_NOTHING, db_column='elderlyID')  # Field name made lowercase.
    diagnosis = models.CharField(max_length=500, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    treatment = models.CharField(max_length=500, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    treatment_type = models.CharField(max_length=100, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    doctor_name = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    hospital = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    result = models.TextField(db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    notes = models.TextField(db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    status = models.CharField(max_length=50, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Treatment_history'