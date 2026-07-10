from django.shortcuts import render
from django.http import JsonResponse
from rest_framework import generics, status
from rest_framework.response import Response
from .models import Medication, MedicationSchedule, MedicalDocument, Appointment
from .serializers import MedicationSerializer, MedicationScheduleSerializer, MedicalDocumentSerializer, AppointmentSerializer
from users.models import Elderly
from datetime import datetime
from PIL import Image, ImageFilter, ImageOps
# ================= LEGACY VIEWS =================
def getmedication(request):
    if request.method == "GET":
        medication = Medication.objects.all()
        serializer = MedicationSerializer(medication, many=True)
        return JsonResponse(serializer.data, safe=False)
    return JsonResponse({'error': 'Invalid request method'}, status=400)

def getmedicationschedule(request):
    if request.method == "GET":
        medicationschedule = MedicationSchedule.objects.all()
        serializer = MedicationScheduleSerializer(medicationschedule, many=True)
        return JsonResponse(serializer.data, safe=False)
    return JsonResponse({'error': 'Invalid request method'}, status=400)

def getmedicaldocument(request):
    if request.method == "GET":
        medicaldocument = MedicalDocument.objects.all()
        serializer = MedicalDocumentSerializer(medicaldocument, many=True)
        return JsonResponse(serializer.data, safe=False)
    return JsonResponse({'error': 'Invalid request method'}, status=400)

# ================= NEW API VIEWS =================

class ElderlyMedicationScheduleView(generics.RetrieveAPIView):
    """GET /api/medication/elderly-schedule/?elderly_id=<id>"""
    def get(self, request):
        elderly_id = request.query_params.get('elderly_id')
        if not elderly_id:
            return Response({"error": "Thiếu elderly_id"}, status=status.HTTP_400_BAD_REQUEST)
        
        schedules = MedicationSchedule.objects.filter(elderlyid=elderly_id).select_related('medicationid')
        data = []
        for s in schedules:
            m = s.medicationid
            data.append({
                "schedule_id": s.medication_scheduleid,
                "time": s.time.strftime("%H:%M") if s.time else "",
                "frequency": s.frequency or "",
                "start_date": str(s.start_date.date()) if s.start_date else "",
                "end_date": str(s.end_date.date()) if s.end_date else "",
                "medication": {
                    "id": m.medicationid,
                    "name": m.name or "",
                    "dosage": m.dosage or "",
                    "instruction": m.instruction or "",
                    "description": m.description or "",
                } if m else None
            })
        return Response({"schedules": data}, status=status.HTTP_200_OK)

class CreateMedicationView(generics.CreateAPIView):
    """POST /api/medication/create/"""
    def post(self, request):
        elderly_id = request.data.get('elderly_id')
        name = request.data.get('name')
        dosage = request.data.get('dosage', '')
        instruction = request.data.get('instruction', '')
        time_str = request.data.get('time')
        frequency = request.data.get('frequency', '')
        description = request.data.get('description', '')
        start_date_str = request.data.get('start_date')
        end_date_str = request.data.get('end_date')

        try:
            elderly = Elderly.objects.get(elderlyid=elderly_id)
        except Elderly.DoesNotExist:
            return Response({"error": "Không tìm thấy người cao tuổi"}, status=status.HTTP_404_NOT_FOUND)

        medication = Medication.objects.create(
            name=name,
            dosage=dosage,
            instruction=instruction,
            description=description
        )

        time_obj = None
        if time_str:
            try:
                time_obj = datetime.strptime(time_str, "%H:%M").time()
            except ValueError:
                pass

        start_date_obj = None
        if start_date_str:
            try:
                start_date_obj = datetime.strptime(start_date_str, "%Y-%m-%d")
            except ValueError:
                pass

        end_date_obj = None
        if end_date_str:
            try:
                end_date_obj = datetime.strptime(end_date_str, "%Y-%m-%d")
            except ValueError:
                pass

        schedule = MedicationSchedule.objects.create(
            medicationid=medication,
            elderlyid=elderly,
            time=time_obj,
            frequency=frequency,
            start_date=start_date_obj,
            end_date=end_date_obj
        )

        return Response({"message": "Đã thêm lịch uống thuốc"}, status=status.HTTP_201_CREATED)


class UpdateMedicationView(generics.UpdateAPIView):
    """PUT /api/medication/schedule/<id>/update/"""
    def put(self, request, schedule_id):
        try:
            schedule = MedicationSchedule.objects.get(medication_scheduleid=schedule_id)
        except MedicationSchedule.DoesNotExist:
            return Response({"error": "Không tìm thấy lịch"}, status=status.HTTP_404_NOT_FOUND)

        medication = schedule.medicationid
        if medication:
            name = request.data.get('name')
            dosage = request.data.get('dosage')
            instruction = request.data.get('instruction')
            description = request.data.get('description')
            if name is not None: medication.name = name
            if dosage is not None: medication.dosage = dosage
            if instruction is not None: medication.instruction = instruction
            if description is not None: medication.description = description
            medication.save()

        time_str = request.data.get('time')
        frequency = request.data.get('frequency')
        start_date_str = request.data.get('start_date')
        end_date_str = request.data.get('end_date')
        
        if time_str:
            try:
                schedule.time = datetime.strptime(time_str, "%H:%M").time()
            except ValueError:
                pass
        if frequency is not None:
            schedule.frequency = frequency

        if start_date_str:
            try:
                schedule.start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
            except ValueError:
                pass

        if end_date_str:
            try:
                schedule.end_date = datetime.strptime(end_date_str, "%Y-%m-%d")
            except ValueError:
                pass
        
        schedule.save()
        return Response({"message": "Cập nhật thành công"}, status=status.HTTP_200_OK)

class DeleteMedicationView(generics.DestroyAPIView):
    """DELETE /api/medication/schedule/<id>/delete/"""
    def delete(self, request, schedule_id):
        try:
            schedule = MedicationSchedule.objects.get(medication_scheduleid=schedule_id)
            med = schedule.medicationid
            schedule.delete()
            if med:
                med.delete()
            return Response({"message": "Xóa thành công"}, status=status.HTTP_200_OK)
        except MedicationSchedule.DoesNotExist:
            return Response({"error": "Không tìm thấy lịch"}, status=status.HTTP_404_NOT_FOUND)

class ScanPrescriptionView(generics.CreateAPIView):
    """POST /api/medication/scan-prescription/"""
    def post(self, request):
        import os, json, tempfile
        import google.generativeai as genai
        from PIL import Image

        image_file = request.FILES.get('image')
        if not image_file:
            return Response({"error": "Vui lòng tải lên hình ảnh đơn thuốc (image field)"}, status=status.HTTP_400_BAD_REQUEST)

        # Thay chuỗi rỗng bên dưới bằng API Key của bạn nếu không dùng biến môi trường
        api_key = os.environ.get("GEMINI_API_KEY", "")
        if not api_key:
            return Response({"error": "Chưa cấu hình GEMINI_API_KEY. Mở views.py và điền key vào hoặc set biến môi trường."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        suffix = '.' + (image_file.name.split('.')[-1] if '.' in image_file.name else 'jpg')
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            for chunk in image_file.chunks():
                tmp.write(chunk)
            tmp_path = tmp.name

        try:
            genai.configure(api_key=api_key)
            img = Image.open(tmp_path)

            prompt = """Bạn là một dược sĩ/trợ lý y tế chuyên nghiệp. Hãy trích xuất danh sách thuốc và thông tin tái khám từ ảnh đơn thuốc này.
            Trả về CHỈ một chuỗi JSON hợp lệ (KHÔNG chứa markdown ```json, không giải thích).
            Định dạng JSON chuẩn:
            {
              "medications": [
                {
                  "name": "tên thuốc",
                  "dosage": "liều lượng mỗi lần uống (VD: 1 viên, 5ml)",
                  "instruction": "hướng dẫn (VD: Uống sau ăn, Trước ăn)",
                  "time": "thời gian gợi ý (VD: 08:00, 20:00)",
                  "frequency": "tần suất (VD: Sáng, Tối, Hàng ngày)"
                }
              ],
              "appointment": {
                "doctor_name": "tên bác sĩ hoặc null",
                "clinic": "tên phòng khám/bệnh viện hoặc null",
                "phone": "số điện thoại hoặc null",
                "appointment_date": "YYYY-MM-DD hoặc null",
                "appointment_time": "HH:MM hoặc null",
                "note": "ghi chú tái khám hoặc null"
              }
            }"""

            model = genai.GenerativeModel('gemini-flash-latest')
            response = model.generate_content([prompt, img])
            text = response.text.strip()
            
            # Xóa các markdown blocks nếu model lỡ sinh ra
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]
            
            data = json.loads(text.strip())

            medications = data.get('medications', [])
            if not medications:
                return Response({"error": "Không nhận ra thuốc trong ảnh. Vui lòng chụp rõ hơn."}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)

            return Response({
                "message": "Quét thành công",
                "medications": medications,
                "appointment": data.get('appointment'),
                "raw_text": text[:500]
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": f"Lỗi phân tích ảnh Gemini: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        finally:
            try:
                os.unlink(tmp_path)
            except Exception:
                pass


class CreateAppointmentView(generics.CreateAPIView):
    """POST /api/medication/appointment/create/"""
    def post(self, request):
        elderly_id = request.data.get('elderly_id')
        if not elderly_id:
            return Response({"error": "Thiếu elderly_id"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            elderly = Elderly.objects.get(elderlyid=elderly_id)
        except Elderly.DoesNotExist:
            return Response({"error": "Không tìm thấy người cao tuổi"}, status=status.HTTP_404_NOT_FOUND)
        
        date_str = request.data.get('appointment_date', '')
        time_str = request.data.get('appointment_time', '08:00')
        
        try:
            appointment_date = datetime.strptime(date_str, "%Y-%m-%d").date() if date_str else None
        except ValueError:
            appointment_date = None

        try:
            appointment_time = datetime.strptime(time_str, "%H:%M").time()
        except ValueError:
            appointment_time = datetime.strptime('08:00', "%H:%M").time()

        appointment = Appointment.objects.create(
            elderlyid=elderly,
            appointment_date=appointment_date,
            appointment_time=appointment_time,
            doctor_name=request.data.get('doctor_name', ''),
            location=request.data.get('location', ''),
            note=request.data.get('note', ''),
        )
        
        # Create notification for caregivers
        from notification.models import Notification, NotificationDetail
        from users.models import CaregiverElderly
        from django.utils import timezone
        
        caregivers = CaregiverElderly.objects.filter(elderlyid=elderly)
        for ce in caregivers:
            if ce.caregiverid:
                time_formatted = appointment_time.strftime("%H:%M") if appointment_time else "08:00"
                date_formatted = appointment_date.strftime("%d/%m/%Y") if appointment_date else "Chưa rõ"
                location_str = request.data.get('location', '')
                location_str = location_str if location_str else "bệnh viện/phòng khám"
                doctor_str = request.data.get('doctor_name', '')
                doctor_str = doctor_str if doctor_str else "Bác sĩ"
                
                notif = Notification.objects.create(
                    caregiverid=ce.caregiverid,
                    title=f"Lịch khám bệnh: {elderly.fullname}",
                    message=f"Thời gian: {time_formatted} ngày {date_formatted}\nTại: {location_str}\nPhụ trách: {doctor_str}",
                    created_at=timezone.now()
                )
                NotificationDetail.objects.create(
                    notificationid=notif,
                    is_read=False
                )

        
        return Response({
            "message": "Tạo lịch khám thành công",
            "appointment_id": appointment.appointmentid
        }, status=status.HTTP_201_CREATED)

class AppointmentListView(generics.ListAPIView):
    """GET /api/medication/appointment/list/?elderly_id=<id>"""
    serializer_class = AppointmentSerializer

    def get_queryset(self):
        elderly_id = self.request.query_params.get('elderly_id')
        if elderly_id:
            return Appointment.objects.filter(elderlyid=elderly_id).order_by('appointment_date')
        return Appointment.objects.all().order_by('appointment_date')

class UpdateAppointmentView(generics.UpdateAPIView):
    """PUT /api/medication/appointment/<id>/update/"""
    queryset = Appointment.objects.all()
    serializer_class = AppointmentSerializer
    
    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        
        date_str = request.data.get('appointment_date')
        time_str = request.data.get('appointment_time')
        
        if date_str:
            try:
                instance.appointment_date = datetime.strptime(date_str, "%Y-%m-%d").date()
            except ValueError:
                pass
        
        if time_str:
            try:
                instance.appointment_time = datetime.strptime(time_str, "%H:%M").time()
            except ValueError:
                pass
                
        if 'doctor_name' in request.data:
            instance.doctor_name = request.data.get('doctor_name')
        if 'location' in request.data:
            instance.location = request.data.get('location')
        if 'note' in request.data:
            instance.note = request.data.get('note')
            
        instance.save()
        return Response({"message": "Cập nhật thành công"}, status=status.HTTP_200_OK)

class DeleteAppointmentView(generics.DestroyAPIView):
    """DELETE /api/medication/appointment/<id>/delete/"""
    queryset = Appointment.objects.all()
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response({"message": "Xóa lịch khám thành công"}, status=status.HTTP_200_OK)


import uuid
from django.core.files.storage import default_storage

class ElderlyMedicalDocumentListView(generics.ListAPIView):
    """GET /api/medication/elderly-document/list/?elderly_id=<id>"""
    serializer_class = MedicalDocumentSerializer

    def get_queryset(self):
        elderly_id = self.request.query_params.get('elderly_id')
        if elderly_id:
            return MedicalDocument.objects.filter(elderlyid=elderly_id).order_by('-upload_at')
        return MedicalDocument.objects.none()

class UploadMedicalDocumentView(generics.CreateAPIView):
    """POST /api/medication/elderly-document/upload/"""
    def post(self, request):
        elderly_id = request.data.get('elderly_id')
        document_type = request.data.get('document_type', 'Khác')
        file_obj = request.FILES.get('file')

        if not elderly_id or not file_obj:
            return Response({"error": "Thiếu elderly_id hoặc file"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            elderly = Elderly.objects.get(elderlyid=elderly_id)
        except Elderly.DoesNotExist:
            return Response({"error": "Không tìm thấy elderly"}, status=status.HTTP_404_NOT_FOUND)
        
        # Save file
        file_extension = file_obj.name.split('.')[-1]
        file_name = f"documents/{elderly_id}_{uuid.uuid4().hex[:8]}.{file_extension}"
        file_path = default_storage.save(file_name, file_obj)
        file_url = f"/media/{file_path}"

        doc = MedicalDocument.objects.create(
            elderlyid=elderly,
            document_type=document_type,
            file_url=file_url,
            upload_at=timezone.now()
        )
        
        serializer = MedicalDocumentSerializer(doc)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
