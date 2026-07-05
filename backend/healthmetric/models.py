from django.db import models

# Create your models here.

class HealthMetrics(models.Model):
    health_metricid = models.AutoField(db_column='health_metricID', primary_key=True)  # Field name made lowercase.
    elderlyid = models.ForeignKey('users.Elderly', models.DO_NOTHING, db_column='elderlyID', blank=True, null=True)  # Field name made lowercase.
    heart_rate = models.IntegerField(blank=True, null=True)
    blood_pressure = models.CharField(max_length=20, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    blood_sugar = models.FloatField(blank=True, null=True)
    recorded_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Health_metrics'
