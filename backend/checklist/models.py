from django.db import models
from medication.models import Appointment
from users.models import Elderly


class Checklist(models.Model):
    checklistid = models.AutoField(db_column='checklistID', primary_key=True)
    appointmentid = models.ForeignKey(
        Appointment, models.DO_NOTHING, db_column='appointmentID',
        blank=True, null=True
    )
    elderlyid = models.ForeignKey(
        Elderly, models.DO_NOTHING, db_column='elderlyID',
        blank=True, null=True
    )
    title = models.CharField(
        max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Tiêu đề checklist'
    )
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Checklist'

    def __str__(self):
        return f"Checklist #{self.checklistid}"


class ChecklistItem(models.Model):
    checklist_itemid = models.AutoField(db_column='checklist_itemID', primary_key=True)
    checklistid = models.ForeignKey(
        Checklist, models.DO_NOTHING, db_column='checklistID',
        blank=True, null=True
    )
    content = models.CharField(
        max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Nội dung công việc'
    )
    is_complete = models.BooleanField(blank=True, null=True, default=False)
    note = models.TextField(
        db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Ghi chú thêm'
    )

    class Meta:
        managed = False
        db_table = 'Checklist_item'

    def __str__(self):
        status = '✓' if self.is_complete else '○'
        return f"{status} {self.content}"
