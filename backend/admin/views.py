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

class BackupListView(APIView):
    def get(self, request):
        # Return empty for now as backup system isn't implemented
        return Response([], status=status.HTTP_200_OK)
        
class BackupRestoreView(APIView):
    def post(self, request, backup_id):
        return Response({'message': 'Restored'}, status=status.HTTP_200_OK)

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
