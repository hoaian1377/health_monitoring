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
        import os, json, tempfile, re
        import pytesseract
        from PIL import Image

        # Đường dẫn Tesseract trên Windows
        tesseract_paths = [
            r'C:\Program Files\Tesseract-OCR\tesseract.exe',
            r'C:\Program Files (x86)\Tesseract-OCR\tesseract.exe',
        ]
        for p in tesseract_paths:
            if os.path.exists(p):
                pytesseract.pytesseract.tesseract_cmd = p
                break

        image_file = request.FILES.get('image')
        if not image_file:
            return Response({"error": "Vui lòng tải lên hình ảnh đơn thuốc (image field)"}, status=status.HTTP_400_BAD_REQUEST)

        suffix = '.' + (image_file.name.split('.')[-1] if '.' in image_file.name else 'jpg')
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            for chunk in image_file.chunks():
                tmp.write(chunk)
            tmp_path = tmp.name

        try:
            img = Image.open(tmp_path)
            # Xoay ảnh đúng chiều
            img = ImageOps.exif_transpose(img)
            # Chuyển sang ảnh xám
            img = img.convert("L")
            # Làm nét
            img = img.filter(ImageFilter.SHARPEN)
            # Tăng độ tương phản
            img = img.point(lambda x: 255 if x > 150 else 0)
            try:
                text = pytesseract.image_to_string(
                    img,
                    lang="vie+eng",
                    config="--oem 3 --psm 6"
                )
            except Exception:
                text = pytesseract.image_to_string(
                    img,
                    lang="eng",
                    config="--oem 3 --psm 6"
                )

            # Làm sạch dữ liệu OCR
            text = text.replace("|", "I")
            text = text.replace("—", "-")
            text = text.replace("§", "5")

            lines = [l.strip() for l in text.splitlines() if l.strip()]

            # --- Phân tích thuốc ---
            medications = []
            med_keywords = ['mg', 'ml', 'gói', 'viên', 'tab', 'cap', 'syr', 'AUGMENTIN',
                           'AMOX', 'PARA', 'DEXA', 'OMEP', 'CEFI', 'AZIT', 'CIPRO']
            dose_map = {'sang': ('08:00', 'Sáng'), 'trua': ('12:00', 'Trưa'),
                        'chieu': ('16:00', 'Chiều'), 'toi': ('20:00', 'Tối'),
                        'sáng': ('08:00', 'Sáng'), 'trưa': ('12:00', 'Trưa'),
                        'chiều': ('16:00', 'Chiều'), 'tối': ('20:00', 'Tối')}

            current_time = '08:00'
            current_freq = 'Sáng'
            for line in lines:
                low = line.lower()
                # Detect time section headers
                for kw, (t, f) in dose_map.items():
                    if kw in low and len(line) < 30:
                        current_time = t
                        current_freq = f
                        break
                # Detect medication lines
                is_med = any(kw.lower() in low for kw in med_keywords) or re.search(r'\d+\s*mg|\d+\s*ml', low)
                if is_med and len(line) > 3:
                    # Extract dosage
                    dosage_match = re.search(r'(\d+[/\d]*\s*(?:viên|gói|ml|tab|cap))', line, re.IGNORECASE)
                    dosage = dosage_match.group(1) if dosage_match else '1 viên'
                    # Clean name
                    name = re.sub(r'\s+', ' ', line).strip()
                    # Avoid duplicate names
                    if not any(m['name'] == name for m in medications):
                        medications.append({
                            "name": name,
                            "dosage": dosage,
                            "instruction": "Uống sau ăn",
                            "time": current_time,
                            "frequency": current_freq,
                        })

            # --- Phân tích thông tin tái khám ---
            appointment = None
            full_text = text.lower()
            doctor = None
            clinic = None
            address = None
            phone = None
            appt_date = None
            appt_time = None
            note_lines = []

            for line in lines:
                low = line.lower()
                if any(k in low for k in ['bs.', 'bác sĩ', 'dr.', 'ths.', 'pkđk', 'phòng khám', 'bệnh viện', 'clinic']):
                    if not clinic:
                        clinic = line
                if any(k in low for k in ['bs.', 'bác sĩ', 'dr.', 'ths.', 'b.s']):
                    if not doctor:
                        doctor = line
                if re.search(r'\b0\d{9}\b', line):
                    phone = re.search(r'\b0\d{9}\b', line).group(0)
                if re.search(r'\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}', line):
                    date_match = re.search(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})', line)
                    if date_match:
                        d, m, y = date_match.groups()
                        y = y if len(y) == 4 else '20' + y
                        appt_date = f"{y}-{m.zfill(2)}-{d.zfill(2)}"
                if re.search(r'\b\d{1,2}:\d{2}\b', line):
                    appt_time = re.search(r'\b(\d{1,2}:\d{2})\b', line).group(1)
                if any(k in low for k in ['tái khám', 'tai kham', 'lưu ý', 'ăn nóng', 'ghi chú', 'note']):
                    note_lines.append(line)

            if any([doctor, clinic, phone, appt_date]):
                appointment = {
                    "doctor_name": doctor,
                    "clinic": clinic,
                    "address": address,
                    "phone": phone,
                    "appointment_date": appt_date,
                    "appointment_time": appt_time or '08:00',
                    "note": ' '.join(note_lines) if note_lines else None
                }

            # Nếu không nhận diện được thuốc nào, báo lỗi
            if not medications:
                return Response({"error": "Không nhận ra thuốc trong ảnh. Vui lòng chụp rõ hơn hoặc nhập thủ công."}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)

            return Response({
                "message": "Quét thành công",
                "medications": medications,
                "appointment": appointment,
                "raw_text": text[:500]  # debug
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": f"Lỗi phân tích ảnh: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
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
                notif = Notification.objects.create(
                    caregiverid=ce.caregiverid,
                    title="Lịch khám bệnh mới",
                    message=f"Đã thêm lịch khám cho {elderly.fullname} vào ngày {appointment_date} lúc {appointment_time}.",
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