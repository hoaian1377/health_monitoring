from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from users.models import Account, Elderly, Caregiver, CaregiverElderly
from notification.models import Notification
from datetime import datetime, timezone

class DashboardStatsView(APIView):
    def get(self, request):
        total_users = Account.objects.count()
        total_elderly = Elderly.objects.count()
        total_caregivers = Caregiver.objects.count()
        total_admin = Account.objects.filter(role__iexact='admin').count()
        
        # Alerts today
        today = datetime.now().date()
        alerts_today = Notification.objects.filter(created_at__date=today).count()
        
        # SOS today (assuming SOS is a specific title/message keyword)
        sos_today = Notification.objects.filter(created_at__date=today, title__icontains='sos').count()

        return Response({
            'totalUsers': total_users,
            'totalElderly': total_elderly,
            'totalCaregiver': total_caregivers,
            'totalAdmin': total_admin,
            'alertsToday': alerts_today,
            'sosToday': sos_today,
        }, status=status.HTTP_200_OK)

class AdminUserListView(APIView):
    def get(self, request):
        accounts = Account.objects.all()
        data = []
        for acc in accounts:
            fullName = acc.usename
            email = ''
            phone = ''
            birthday = ''
            gender = ''
            avatar = ''
            
            if acc.role == 'elderly':
                elderly = Elderly.objects.filter(accountid=acc).first()
                if elderly:
                    fullName = elderly.fullname
                    birthday = str(elderly.date_of_birthday) if elderly.date_of_birthday else ''
                    gender = 'Nam' if elderly.gender else 'Nữ'
            elif acc.role == 'caregiver':
                cg = Caregiver.objects.filter(accountid=acc).first()
                if cg:
                    fullName = cg.fullname
                    email = cg.email
                    phone = cg.phone
                    birthday = str(cg.date_of_birth) if cg.date_of_birth else ''
                    gender = 'Nam' if cg.gender else 'Nữ'

            data.append({
                'id': str(acc.accountid),
                'fullName': fullName,
                'email': email,
                'phone': phone,
                'avatar': avatar,
                'birthday': birthday,
                'gender': gender,
                'role': acc.role,
                'status': 'active', # Default to active as db doesn't support
                'createdAt': str(acc.created_at) if acc.created_at else '',
            })
            
        # filters
        search = request.GET.get('search', '').lower()
        role = request.GET.get('role', 'All').lower()
        
        if search:
            data = [u for u in data if search in u['fullName'].lower() or search in u['email'].lower()]
        if role != 'all':
            data = [u for u in data if u['role'].lower() == role]
            
        return Response(data, status=status.HTTP_200_OK)

class AdminUserDetailView(APIView):
    def put(self, request, user_id):
        return Response({'message': 'User updated'}, status=status.HTTP_200_OK)
        
    def delete(self, request, user_id):
        Account.objects.filter(accountid=user_id).delete()
        return Response({'message': 'User deleted'}, status=status.HTTP_200_OK)

class AdminUserStatusView(APIView):
    def put(self, request, user_id):
        # Database doesn't support status, mock it
        return Response({'message': 'User status updated'}, status=status.HTTP_200_OK)

import os
from django.conf import settings
from django.core.management import call_command
from django.http import FileResponse

class StatisticsChartView(APIView):
    def get(self, request):
        total_admin = Account.objects.filter(role__iexact='admin').count()
        total_elderly = Elderly.objects.count()
        total_caregivers = Caregiver.objects.count()
        
        roles_distribution = [
            {'name': 'Admin', 'count': total_admin, 'color': '#64748B'},
            {'name': 'Elderly', 'count': total_elderly, 'color': '#0EA5E9'},
            {'name': 'Caregiver', 'count': total_caregivers, 'color': '#10B981'},
        ]

        # For alerts over the last 6 months
        # Group notifications by month
        from django.db.models import Count
        from django.db.models.functions import TruncMonth
        from dateutil.relativedelta import relativedelta

        six_months_ago = datetime.now() - relativedelta(months=5)
        six_months_ago = six_months_ago.replace(day=1)

        monthly_alerts = Notification.objects.filter(created_at__gte=six_months_ago) \
            .annotate(month=TruncMonth('created_at')) \
            .values('month') \
            .annotate(count=Count('notificationid')) \
            .order_by('month')

        monthly_data = []
        for i in range(5, -1, -1):
            target_date = datetime.now() - relativedelta(months=i)
            month_str = target_date.strftime('%m/%Y')
            
            # Find in query results
            count = 0
            for item in monthly_alerts:
                if item['month'] and item['month'].month == target_date.month and item['month'].year == target_date.year:
                    count = item['count']
                    break
            
            monthly_data.append({
                'month': month_str,
                'alerts': count
            })

        return Response({
            'roles': roles_distribution,
            'monthlyAlerts': monthly_data
        }, status=status.HTTP_200_OK)


class BackupListView(APIView):
    def get_backup_dir(self):
        backup_dir = os.path.join(settings.BASE_DIR, 'backups')
        if not os.path.exists(backup_dir):
            os.makedirs(backup_dir)
        return backup_dir

    def get(self, request):
        backup_dir = self.get_backup_dir()
        files = []
        for filename in os.listdir(backup_dir):
            if filename.endswith('.json'):
                filepath = os.path.join(backup_dir, filename)
                stat = os.stat(filepath)
                files.append({
                    'id': filename,
                    'name': filename,
                    'size': f"{stat.st_size / 1024:.2f} KB",
                    'date': datetime.fromtimestamp(stat.st_mtime).strftime('%d/%m/%Y %H:%M')
                })
        # Sort by date descending
        files.sort(key=lambda x: os.path.getmtime(os.path.join(backup_dir, x['name'])), reverse=True)
        return Response(files, status=status.HTTP_200_OK)

    def post(self, request):
        backup_dir = self.get_backup_dir()
        filename = f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        filepath = os.path.join(backup_dir, filename)
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                call_command('dumpdata', exclude=['admin', 'contenttypes', 'auth', 'sessions'], stdout=f)
            return Response({'message': 'Backup created successfully', 'filename': filename}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class DownloadBackupView(APIView):
    def get(self, request, filename):
        backup_dir = os.path.join(settings.BASE_DIR, 'backups')
        filepath = os.path.join(backup_dir, filename)
        if os.path.exists(filepath):
            response = FileResponse(open(filepath, 'rb'), as_attachment=True, filename=filename)
            return response
        return Response({'error': 'File not found'}, status=status.HTTP_404_NOT_FOUND)
        
class BackupRestoreView(APIView):
    def post(self, request, backup_id):
        backup_dir = os.path.join(settings.BASE_DIR, 'backups')
        filepath = os.path.join(backup_dir, backup_id)
        if os.path.exists(filepath):
            try:
                call_command('loaddata', filepath)
                return Response({'message': 'Restored successfully'}, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        return Response({'error': 'File not found'}, status=status.HTTP_404_NOT_FOUND)

class LatestAlertsView(APIView):
    def get(self, request):
        # Fetch latest 10 notifications
        notifications = Notification.objects.all().order_by('-created_at')[:10]
        data = []
        for notif in notifications:
            elderly_name = "Không xác định"
            # Get associated caregiver and their elderly? Notification belongs to caregiver.
            if getattr(notif, 'caregiverid', None):
                cg = notif.caregiverid
                ce = CaregiverElderly.objects.filter(caregiverid=cg).first()
                if ce and ce.elderlyid:
                    elderly_name = ce.elderlyid.fullname
            
            data.append({
                'id': notif.notificationid,
                'elderlyName': elderly_name,
                'type': notif.title or 'Thông báo',
                'time': notif.created_at.strftime('%H:%M %d/%m/%Y') if notif.created_at else '',
                'status': 'Chưa xử lý', # DB doesn't have status, mock it
            })
            
        return Response(data, status=status.HTTP_200_OK)
