from django.db import models
from users.models import Elderly


class TreatmentHistory(models.Model):
    """Lịch sử điều trị của người cao tuổi"""
    treatment_historyid = models.AutoField(db_column='treatment_historyID', primary_key=True)
    elderlyid = models.ForeignKey(
        Elderly, models.DO_NOTHING, db_column='elderlyID',
        blank=True, null=True
    )
    # Chẩn đoán
    diagnosis = models.CharField(
        max_length=500, db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Chẩn đoán bệnh'
    )
    # Điều trị
    treatment = models.CharField(
        max_length=500, db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Phương pháp / tên điều trị'
    )
    treatment_type = models.CharField(
        max_length=100, db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Nội trú / Ngoại trú / Phẫu thuật / Theo dõi'
    )
    # Bác sĩ & cơ sở y tế
    doctor_name = models.CharField(
        max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Tên bác sĩ điều trị'
    )
    hospital = models.CharField(
        max_length=255, db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Tên bệnh viện / cơ sở y tế'
    )
    # Thời gian
    start_date = models.DateField(blank=True, null=True, help_text='Ngày bắt đầu')
    end_date = models.DateField(blank=True, null=True, help_text='Ngày kết thúc')
    # Kết quả & ghi chú
    result = models.TextField(
        db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Kết quả điều trị'
    )
    notes = models.TextField(
        db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='Ghi chú thêm'
    )
    # Trạng thái
    status = models.CharField(
        max_length=20, db_collation='SQL_Latin1_General_CP1_CI_AS',
        blank=True, null=True,
        help_text='ongoing | completed | cancelled'
    )
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Treatment_history'
        ordering = ['-start_date']

    def __str__(self):
        name = self.elderlyid.fullname if self.elderlyid else 'N/A'
        return f"{name} – {self.diagnosis or self.treatment} ({self.start_date})"
