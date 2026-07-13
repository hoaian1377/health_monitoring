from rest_framework import generics, status
from rest_framework.response import Response
import unicodedata
import re
from users.models import Elderly
from healthmetric.models import HealthMetrics
from medication.models import MedicationSchedule, Appointment, MedicalDocument
from django.utils import timezone
class ElderlyChatbotView(generics.CreateAPIView):
    """POST /api/chatbot/"""
    def post(self, request):
        elderly_id = request.data.get('elderly_id')
        message = request.data.get('message')
        
        if not elderly_id or not message:
            return Response({"error": "Thiếu elderly_id hoặc message"}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            elderly = Elderly.objects.get(elderlyid=elderly_id)
        except Elderly.DoesNotExist:
            return Response({"response": "Dạ, cháu không nhận diện được tài khoản của ông/bà, vui lòng đăng nhập lại ạ."}, status=status.HTTP_200_OK)
            
        now = timezone.now()
        
        def remove_accents(input_str):
            s = re.sub(r'[àáạảãâầấậẩẫăằắặẳẵ]', 'a', input_str)
            s = re.sub(r'[èéẹẻẽêềếệểễ]', 'e', s)
            s = re.sub(r'[ìíịỉĩ]', 'i', s)
            s = re.sub(r'[òóọỏõôồốộổỗơờớợởỡ]', 'o', s)
            s = re.sub(r'[ùúụủũưừứựửữ]', 'u', s)
            s = re.sub(r'[ỳýỵỷỹ]', 'y', s)
            s = re.sub(r'[đ]', 'd', s)
            s = re.sub(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]', 'A', s)
            s = re.sub(r'[ÈÉẸẺẼÊỀẾỆỂỄ]', 'E', s)
            s = re.sub(r'[ÌÍỊỈĨ]', 'I', s)
            s = re.sub(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]', 'O', s)
            s = re.sub(r'[ÙÚỤỦŨƯỪỨỰỬỮ]', 'U', s)
            s = re.sub(r'[ỲÝỴỶỸ]', 'Y', s)
            s = re.sub(r'[Đ]', 'D', s)
            return s.lower()
            
        msg_norm = remove_accents(message)
        
        response_text = ""
        pronoun = "ông" if elderly.gender == 'Nam' else "bà"
        
        def has_kw(kws):
            return any(kw in msg_norm for kw in kws)

        # 1. Intent: Medical Documents / Prescriptions
        if has_kw(['giay to', 'toa thuoc', 'don thuoc', 'ho so', 'ket qua', 'xet nghiem']):
            doc = MedicalDocument.objects.filter(elderlyid=elderly).order_by('-upload_at').first()
            if doc:
                date_str = doc.upload_at.strftime("%d/%m/%Y") if doc.upload_at else "gần đây"
                response_text = f"Dạ, tài liệu gần nhất của {pronoun} là '{doc.document_type}' tại {doc.hospital}, bác sĩ {doc.doctor_name} cung cấp vào ngày {date_str}. {pronoun.capitalize()} có thể xem chi tiết ở mục Hồ sơ ạ."
            else:
                response_text = f"Dạ, hiện tại cháu chưa tìm thấy giấy tờ khám bệnh hay toa thuốc nào của {pronoun} ạ."
                
        # 2. Intent: Appointment / Visit
        elif has_kw(['lich kham', 'tai kham', 'benh vien', 'di kham']):
            appointments = Appointment.objects.filter(elderlyid=elderly, appointment_date__gte=now.date()).order_by('appointment_date')
            if not appointments.exists():
                response_text = f"Dạ, hiện tại {pronoun} không có lịch hẹn khám hay tái khám nào sắp tới ạ."
            else:
                app_list = []
                for a in appointments:
                    time_str = str(a.appointment_time)[:5] if a.appointment_time else "tùy lúc"
                    app_list.append(f"ngày {a.appointment_date.strftime('%d/%m/%Y')} lúc {time_str} tại {a.location}")
                response_text = f"Dạ, {pronoun} có lịch khám vào " + ", ".join(app_list) + f". Bác sĩ sẽ theo dõi cho {pronoun} ạ."
                
        # 3. Intent: Health Metrics
        elif has_kw(['huyet ap', 'duong huyet', 'can nang', 'nhip tim', 'chi so', 'suc khoe', 'do']):
            latest_metric = HealthMetrics.objects.filter(elderlyid=elderly).order_by('-recorded_at').first()
            if latest_metric:
                date_str = latest_metric.recorded_at.strftime("%d/%m/%Y") if latest_metric.recorded_at else "gần đây"
                parts = []
                if latest_metric.blood_pressure: parts.append(f"huyết áp {latest_metric.blood_pressure}")
                if latest_metric.blood_sugar: parts.append(f"đường huyết {latest_metric.blood_sugar} mmol/L")
                if latest_metric.heart_rate: parts.append(f"nhịp tim {latest_metric.heart_rate} bpm")
                if latest_metric.weight: parts.append(f"cân nặng {latest_metric.weight} kg")
                
                if parts:
                    response_text = f"Dạ, theo lần đo gần nhất vào ngày {date_str}, " + ", ".join(parts) + f". {pronoun.capitalize()} nhớ giữ gìn sức khỏe nhé!"
                else:
                    response_text = f"Dạ, bản ghi sức khỏe gần nhất của {pronoun} chưa có số liệu chi tiết ạ."
            else:
                response_text = f"Dạ, cháu chưa tìm thấy dữ liệu đo sức khỏe nào của {pronoun} ạ."
                
        # 4. Intent: Medication
        elif has_kw(['thuoc', 'uong gi', 'lieu luong', 'uong thuoc']):
            schedules = MedicationSchedule.objects.filter(elderlyid=elderly)
            if not schedules.exists():
                response_text = f"Dạ, hiện tại {pronoun} không có lịch uống thuốc nào được ghi nhận ạ."
            else:
                med_list = []
                for s in schedules:
                    if s.medicationid:
                        med_list.append(f"{s.medicationid.name} uống lúc {s.time} ({s.frequency})")
                if med_list:
                    response_text = f"Dạ, lịch uống thuốc của {pronoun} gồm có: " + ", ".join(med_list) + f". {pronoun.capitalize()} nhớ uống đúng giờ nhé!"
                else:
                    response_text = f"Dạ, hiện tại {pronoun} không có chi tiết lịch uống thuốc nào ạ."

        # 5. Intent: Doctor
        elif has_kw(['bac si']):
            app = Appointment.objects.filter(elderlyid=elderly).order_by('-appointment_date').first()
            if app and app.doctor_name:
                response_text = f"Dạ, bác sĩ theo dõi gần nhất của {pronoun} là Bác sĩ {app.doctor_name} tại {app.location} ạ."
            else:
                doc = MedicalDocument.objects.filter(elderlyid=elderly).order_by('-upload_at').first()
                if doc and doc.doctor_name:
                    response_text = f"Dạ, bác sĩ ghi trong hồ sơ gần nhất của {pronoun} là Bác sĩ {doc.doctor_name} tại {doc.hospital} ạ."
                else:
                    response_text = f"Dạ, cháu chưa tìm thấy thông tin bác sĩ điều trị của {pronoun} ạ."
                    
        # 6. Fallback / Greeting
        else:
            if has_kw(['chao', 'khoe khong', 'ten gi', 'ai do']):
                response_text = f"Dạ cháu chào {pronoun}, cháu là trợ lý ảo chăm sóc sức khỏe. Cháu có thể giúp {pronoun} xem lịch khám, đơn thuốc, sức khỏe và lịch uống thuốc ạ!"
            else:
                response_text = f"Dạ cháu chưa hiểu ý lắm. {pronoun.capitalize()} có thể hỏi cháu các câu như: 'Lịch khám của tôi', 'Xem đơn thuốc', hoặc 'Chỉ số huyết áp' nhé!"
            
        return Response({"response": response_text}, status=status.HTTP_200_OK)
