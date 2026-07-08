from django.db import models

class Account(models.Model):
    accountid = models.AutoField(db_column='accountID', primary_key=True)  # Field name made lowercase.
    usename = models.CharField(unique=True, max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS')
    password = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS')
    role = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Account'


class Caregiver(models.Model):
    caregiverid = models.AutoField(db_column='caregiverID', primary_key=True)  # Field name made lowercase.
    accountid = models.ForeignKey(Account, models.DO_NOTHING, db_column='accountID', blank=True, null=True)  # Field name made lowercase.
    fullname = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS')
    email = models.CharField(unique=True, max_length=100, db_collation='SQL_Latin1_General_CP1_CI_AS')
    phone = models.CharField(unique=True, max_length=15, db_collation='SQL_Latin1_General_CP1_CI_AS')

    class Meta:
        managed = False
        db_table = 'Caregiver'


class CaregiverElderly(models.Model):
    id = models.AutoField(db_column='ID', primary_key=True)  # Field name made lowercase.
    caregiverid = models.ForeignKey(Caregiver, models.DO_NOTHING, db_column='caregiverID', blank=True, null=True)  # Field name made lowercase.
    elderlyid = models.ForeignKey('Elderly', models.DO_NOTHING, db_column='elderlyID', blank=True, null=True)  # Field name made lowercase.

    class Meta:
        managed = False
        db_table = 'Caregiver_elderly'



class Elderly(models.Model):
    elderlyid = models.AutoField(db_column='elderlyID', primary_key=True)  # Field name made lowercase.
    fullname = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS')
    date_of_birthday = models.DateField(blank=True, null=True)
    gender = models.BooleanField(blank=True, null=True)
    qr_token = models.CharField(max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    qr_expired_at = models.DateTimeField(blank=True, null=True)
    medical_note = models.TextField(db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    blood_type = models.CharField(max_length=10, db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    height = models.FloatField(blank=True, null=True)
    weight = models.FloatField(blank=True, null=True)
    allergies = models.TextField(db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)
    underlying_conditions = models.TextField(db_collation='SQL_Latin1_General_CP1_CI_AS', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Elderly'