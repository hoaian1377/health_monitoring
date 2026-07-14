from django.db import models

# Create your models here.

class Notification(models.Model):
    notificationid = models.AutoField(db_column='notificationID', primary_key=True)  # Field name made lowercase.
    caregiverid = models.ForeignKey('users.Caregiver', models.DO_NOTHING, db_column='caregiverID', blank=True, null=True)  # Field name made lowercase.
    elderlyid = models.ForeignKey('users.Elderly', models.DO_NOTHING, db_column='elderlyID', blank=True, null=True)
    title = models.CharField(max_length=1000, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    message = models.CharField(max_length=1000, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Notification'


class NotificationDetail(models.Model):
    notification_detailid = models.AutoField(db_column='notification_detailID', primary_key=True)  # Field name made lowercase.
    notificationid = models.ForeignKey(Notification, models.DO_NOTHING, db_column='notificationID', blank=True, null=True)  # Field name made lowercase.
    is_read = models.BooleanField(blank=True, null=True)
    read_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Notification_detail'
