

import re
from rest_framework import generics, status
from rest_framework.response import Response
from django.utils import timezone

from users.models import Elderly
from healthmetric.models import HealthMetrics
from medication.models import MedicationSchedule, Appointment, MedicalDocument


# ─── Tiện ích ────────────────────────────────────────────────────────────────

def _remove_accents(text: str) -> str:
    """Chuyển chuỗi tiếng Việt có dấu → không dấu, viết thường."""
    mapping = {
        r'[àáạảãâầấậẩẫăằắặẳẵ]': 'a',
        r'[èéẹẻẽêềếệểễ]': 'e',
        r'[ìíịỉĩ]': 'i',
        r'[òóọỏõôồốộổỗơờớợởỡ]': 'o',
        r'[ùúụủũưừứựửữ]': 'u',
        r'[ỳýỵỷỹ]': 'y',
        r'[đ]': 'd',
        r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]': 'a',
        r'[ÈÉẸẺẼÊỀẾỆỂỄ]': 'e',
        r'[ÌÍỊỈĨ]': 'i',
        r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]': 'o',
        r'[ÙÚỤỦŨƯỪỨỰỬỮ]': 'u',
        r'[ỲÝỴỶỸ]': 'y',
        r'[Đ]': 'd',
    }
    s = text
    for pattern, repl in mapping.items():
        s = re.sub(pattern, repl, s)
    return s.lower().strip()


from users.models import CaregiverElderly

# ─── Intent keywords ─────────────────────────────────────────────────────────

INTENT_KEYWORDS = {
    'emergency': [
        'cap cuu', 'kho tho', 'dau nguc', 'chong mat', 'ngat', 'bi te', 'khong khoe', 'dau dau', 'chay mau',
    ],
    'emergency_contact': [
        'nguoi than', 'nguoi cham soc', 'con trai', 'con gai', 'so dien thoai con', 'goi con', 'lien he',
    ],
    'pill_identification': [
        'thuoc nay la', 'vien thuoc nay', 'vien mau trang', 'vien mau vang', 'vien tron', 'co phai thuoc', 'dung thuoc',
    ],
    'medication_instruction': [
        'truoc an', 'sau an', 'uong nhieu nuoc', 'be vien', 'nghien thuoc', 'uong chung', 'tac dung phu', 'quen uong', 'uong nham', 'qua lieu',
    ],
    'medication': [
        'thuoc', 'uong gi', 'thuoc gi', 'uong thuoc', 'lich uong', 'hom nay uong', 'uong luc nao', 'don thuoc', 'toa thuoc', 'uong may vien', 'lieu luong', 'chua benh gi',
    ],
    'appointment': [
        'lich kham', 'tai kham', 'benh vien', 'di kham', 'hen kham', 'khi nao kham', 'kham o dau', 'may gio kham', 'hom nao di', 'lich hen', 'cuoc hen', 'ngay mai kham', 'tuan nay kham',
    ],
    'health_metrics': [
        'huyet ap', 'duong huyet', 'can nang', 'nhip tim', 'chi so', 'suc khoe', 'nhiet do', 'do huyet ap', 'do duong', 'lan do', 'ket qua do',
    ],
    'medical_records': [
        'benh an', 'ho so', 'ho so benh', 'giay to', 'ket qua', 'xet nghiem', 'ket qua xet nghiem', 'chan doan', 'bi benh gi', 'giay kham', 'ket qua kham', 'benh ly',
    ],
    'medical_history': [
        'tung bi benh', 'nhap vien', 'phau thuat', 'benh nen', 'bi cao huyet ap', 'bi tieu duong', 'mac benh gi',
    ],
    'allergy': [
        'di ung', 'tien su di ung',
    ],
    'doctor': [
        'bac si', 'ai dieu tri', 'ai kham', 'bac sy',
    ],
    'personal_info': [
        'toi ten', 'bao nhieu tuoi', 'ngay sinh', 'nam hay nu', 'toi o dau', 'dia chi',
    ],
    'time': [
        'ngay may', 'thu may', 'may gio', 'ngay nao',
    ],
    'app_support': [
        'lam sao xem', 'khong biet dung', 'huong dan su dung', 'giup toi su dung',
    ],
    'greeting': [
        'chao', 'xin chao', 'khoe khong', 'ten gi', 'ban la ai', 'ai do', 'hello', 'hi', 'giup gi', 'lam gi',
    ],
}

def _detect_intent(msg_norm: str) -> str:
    priority = [
        'emergency', 'emergency_contact', 'pill_identification', 'medication_instruction', 'medication',
        'appointment', 'health_metrics', 'medical_records', 'medical_history', 'allergy',
        'doctor', 'personal_info', 'time', 'app_support', 'greeting',
    ]
    for intent in priority:
        for kw in INTENT_KEYWORDS[intent]:
            if kw in msg_norm:
                return intent
    return 'unknown'

def _gather_context(elderly, now):
    ctx = {}
    ctx['appointments'] = list(Appointment.objects.filter(elderlyid=elderly, appointment_date__gte=now.date()).order_by('appointment_date', 'appointment_time'))
    ctx['medications'] = list(MedicationSchedule.objects.filter(elderlyid=elderly).select_related('medicationid'))
    ctx['health_metrics'] = HealthMetrics.objects.filter(elderlyid=elderly).order_by('-recorded_at').first()
    ctx['documents'] = list(MedicalDocument.objects.filter(elderlyid=elderly).select_related('appointmentid').order_by('-upload_at')[:5])
    ctx['past_appointments'] = list(Appointment.objects.filter(elderlyid=elderly, appointment_date__lte=now.date()).order_by('-appointment_date', '-appointment_time')[:5])
    
    doctor = None
    latest_app = Appointment.objects.filter(elderlyid=elderly).exclude(doctor_name__isnull=True).exclude(doctor_name='').order_by('-appointment_date').first()
    if latest_app:
        doctor = {'name': latest_app.doctor_name, 'location': latest_app.location or ''}
    else:
        latest_doc = MedicalDocument.objects.filter(elderlyid=elderly).exclude(doctor_name__isnull=True).exclude(doctor_name='').order_by('-upload_at').first()
        if latest_doc:
            doctor = {'name': latest_doc.doctor_name, 'location': latest_doc.hospital or ''}
    ctx['doctor'] = doctor

    caregiver = CaregiverElderly.objects.filter(elderlyid=elderly).select_related('caregiverid').first()
    ctx['caregiver'] = caregiver.caregiverid if caregiver else None
    
    ctx['elderly'] = elderly
    return ctx

def _build_response(intent: str, ctx: dict, pronoun: str) -> str:
    import datetime
    now = timezone.now()
    elderly = ctx['elderly']

    if intent == 'emergency':
        caregiver = ctx['caregiver']
        phone = caregiver.phone if caregiver and hasattr(caregiver, 'phone') else "người thân"
        return (f"Dạ, nếu {pronoun} đang thấy không khỏe hoặc gặp tình trạng khẩn cấp, "
                f"hãy nhờ người xung quanh gọi ngay cấp cứu 115 hoặc gọi cho số điện thoại {phone} ạ!", [])

    if intent == 'emergency_contact':
        caregiver = ctx['caregiver']
        if not caregiver:
            return (f"Dạ, hiện tại hệ thống chưa cập nhật thông tin người chăm sóc của {pronoun} ạ.", [])
        phone = caregiver.phone if hasattr(caregiver, 'phone') else "chưa có SĐT"
        name = caregiver.fullname if hasattr(caregiver, 'fullname') else "người thân"
        return (f"Dạ, người chăm sóc của {pronoun} là {name}. {pronoun.capitalize()} có thể liên hệ qua số điện thoại: {phone} ạ.", [])

    if intent == 'pill_identification':
        return (f"Dạ, hệ thống chat hiện tại không thể nhìn thấy viên thuốc của {pronoun}. "
                f"{pronoun.capitalize()} vui lòng thoát ra màn hình chính, nhờ người thân chụp ảnh đơn thuốc hoặc hỏi lại bác sĩ cho chắc chắn nhé ạ!", [])

    if intent == 'medication_instruction':
        return (f"Dạ, về cách uống thuốc chi tiết (bẻ viên, uống trước/sau ăn, tác dụng phụ), "
                f"{pronoun} vui lòng xem ghi chú trong phần Lịch Uống Thuốc, hoặc hỏi trực tiếp người chăm sóc/bác sĩ nhé. "
                f"Nếu quên uống thuốc, {pronoun} đừng uống bù gấp đôi liều mà hãy hỏi ý kiến bác sĩ ạ.", [])

    if intent == 'medication':
        meds = ctx['medications']
        if not meds:
            return (f"Dạ, hiện tại {pronoun} chưa có lịch uống thuốc nào được ghi nhận trong hệ thống ạ.", [])
        med_parts = []
        for s in meds:
            if s.medicationid:
                name = s.medicationid.name or "chưa rõ tên"
                dosage = f", liều {s.medicationid.dosage}" if s.medicationid.dosage else ""
                time_str = str(s.time)[:5] if s.time else "chưa rõ giờ"
                freq = f" ({s.frequency})" if s.frequency else ""
                instruction = f" – {s.medicationid.instruction}" if s.medicationid.instruction else ""
                clean_desc = s.medicationid.description or ""
                if '· dose_history:' in clean_desc:
                    clean_desc = clean_desc.split('· dose_history:')[0].strip()
                desc = f" ({clean_desc})" if clean_desc else ""
                med_parts.append(f"{name}{dosage} uống lúc {time_str}{freq}{instruction}{desc}")
        if not med_parts:
            return (f"Dạ, {pronoun} có lịch uống thuốc nhưng chưa có chi tiết tên thuốc trong hệ thống ạ.", [])
        return (f"Dạ, lịch uống thuốc của {pronoun} gồm có:\n• " + "\n• ".join(med_parts) + f"\n{pronoun.capitalize()} nhớ uống đúng giờ nhé ạ!", [])

    if intent == 'appointment':
        appointments = ctx['appointments']
        if not appointments:
            return (f"Dạ, hiện tại {pronoun} chưa có lịch hẹn khám hay tái khám nào sắp tới trong hệ thống ạ.", [])
        parts = []
        for a in appointments:
            time_str = str(a.appointment_time)[:5] if a.appointment_time else "chưa rõ giờ"
            date_str = a.appointment_date.strftime('%d/%m/%Y') if a.appointment_date else "chưa rõ ngày"
            loc = a.location or "chưa rõ địa điểm"
            doctor = f", bác sĩ {a.doctor_name}" if a.doctor_name else ""
            parts.append(f"ngày {date_str} lúc {time_str} tại {loc}{doctor}")
        return (f"Dạ, {pronoun} có lịch khám vào " + "; ".join(parts) + f". {pronoun.capitalize()} nhớ đi đúng giờ nhé ạ.", [])

    if intent == 'health_metrics':
        m = ctx['health_metrics']
        if not m:
            return (f"Dạ, hiện tại {pronoun} chưa có dữ liệu đo sức khỏe nào trong hệ thống ạ.", [])
        date_str = m.recorded_at.strftime("%d/%m/%Y %H:%M") if m.recorded_at else "gần đây"
        parts = []
        if m.blood_pressure: parts.append(f"huyết áp {m.blood_pressure} mmHg")
        if m.heart_rate: parts.append(f"nhịp tim {m.heart_rate} bpm")
        if m.blood_sugar: parts.append(f"đường huyết {m.blood_sugar} mmol/L")
        if m.temperature: parts.append(f"nhiệt độ {m.temperature}°C")
        if not parts:
            return (f"Dạ, bản ghi sức khỏe gần nhất của {pronoun} (ngày {date_str}) chưa có số liệu chi tiết ạ.", [])
        return (f"Dạ, theo lần đo gần nhất vào {date_str}: " + ", ".join(parts) + f". {pronoun.capitalize()} nhớ giữ gìn sức khỏe nhé ạ!", [])

    if intent == 'medical_records':
        docs = ctx.get('documents', [])
        past_apps = ctx.get('past_appointments', [])
        
        if not docs and not past_apps:
            return (f"Dạ, hiện tại chưa có thông tin bệnh án hoặc hồ sơ khám bệnh của {pronoun} trong hệ thống ạ.", [])
            
        latest_doc = docs[0] if docs else None
        latest_app = past_apps[0] if past_apps else None
        
        doc_date = None
        if latest_doc:
            if latest_doc.appointmentid and latest_doc.appointmentid.appointment_date:
                doc_date = latest_doc.appointmentid.appointment_date
            elif latest_doc.upload_at:
                doc_date = latest_doc.upload_at.date()
                
        app_date = latest_app.appointment_date if latest_app else None
        
        use_doc = False
        if latest_doc and not latest_app:
            use_doc = True
        elif latest_doc and latest_app:
            if doc_date and app_date:
                use_doc = doc_date >= app_date
            elif doc_date:
                use_doc = True
                
        if use_doc:
            doc = latest_doc
            date_str = doc_date.strftime("%d/%m/%Y") if doc_date else "gần đây"
            
            hospital = doc.hospital or (doc.appointmentid.location if doc.appointmentid else "") or "cơ sở y tế"
            doc_doctor_name = doc.doctor_name or (doc.appointmentid.doctor_name if doc.appointmentid else "")
            doctor = f" (bác sĩ {doc_doctor_name})" if doc_doctor_name else ""
            
            diagnosis = ""
            for d in docs:
                if d.diagnosis:
                    diagnosis = d.diagnosis
                    break
                if d.appointmentid and d.appointmentid.diagnosis:
                    diagnosis = d.appointmentid.diagnosis
                    break
            if not diagnosis:
                diagnosis = "chưa có chẩn đoán cụ thể"
                    
            result_text = ""
            for d in docs:
                if d.result:
                    result_text = f" (Ghi chú: {d.result})"
                    break
                if d.appointmentid and d.appointmentid.note:
                    result_text = f" (Ghi chú: {d.appointmentid.note})"
                    break
                    
            recent_date = doc.upload_at.date() if doc.upload_at else None
            doc_types = set()
            for d in docs:
                if (d.upload_at and recent_date and d.upload_at.date() == recent_date) or (not d.upload_at and not recent_date):
                    doc_types.add(d.document_type or "Hồ sơ y tế")
            
            doc_types_str = ", ".join(doc_types) if doc_types else "giấy tờ y tế"
            images = [d.file_url for d in docs if d.file_url]
            
            response_text = (
                f"Dạ, theo bệnh án gần nhất vào ngày {date_str}, {pronoun} đi khám tại {hospital}{doctor}. "
                f"Bác sĩ chẩn đoán {pronoun} bị {diagnosis}{result_text}. "
                f"Hồ sơ đợt khám này có lưu các giấy tờ gồm: {doc_types_str} ạ."
            )
            return (response_text, images)
        else:
            # Fallback to past appointment if it is newer
            app = latest_app
            date_str = app.appointment_date.strftime("%d/%m/%Y") if app.appointment_date else "gần đây"
            hospital = app.location or "cơ sở y tế"
            doctor = f" (bác sĩ {app.doctor_name})" if app.doctor_name else ""
            diagnosis = app.diagnosis or "chưa có chẩn đoán cụ thể"
            result_text = f" (Ghi chú: {app.note})" if app.note else ""
            
            response_text = (
                f"Dạ, theo lịch khám gần nhất vào ngày {date_str}, {pronoun} đi khám tại {hospital}{doctor}. "
                f"Bác sĩ chẩn đoán {pronoun} bị {diagnosis}{result_text}. "
                f"Đợt khám này chưa có giấy tờ nào được tải lên hệ thống ạ."
            )
            return (response_text, [])

    if intent == 'medical_history':
        cond = elderly.underlying_conditions if elderly.underlying_conditions else "hệ thống chưa ghi nhận bệnh nền nào"
        diagnosis_history = [doc.diagnosis for doc in ctx['documents'] if doc.diagnosis]
        diag_str = "Các chẩn đoán gần đây: " + ", ".join(diagnosis_history) if diagnosis_history else ""
        return (f"Dạ, theo hồ sơ thì {pronoun} có bệnh nền: {cond}. {diag_str}", [])

    if intent == 'allergy':
        alg = elderly.allergies if elderly.allergies else "hệ thống chưa ghi nhận thông tin dị ứng"
        return (f"Dạ, theo hồ sơ thì tiền sử dị ứng của {pronoun} là: {alg}.", [])

    if intent == 'doctor':
        doc_info = ctx['doctor']
        if not doc_info:
            return (f"Dạ, hiện tại {pronoun} chưa có thông tin bác sĩ điều trị trong hệ thống ạ.", [])
        loc = f" tại {doc_info['location']}" if doc_info['location'] else ""
        return (f"Dạ, bác sĩ theo dõi gần nhất của {pronoun} là Bác sĩ {doc_info['name']}{loc} ạ.", [])

    if intent == 'personal_info':
        name = elderly.fullname or "chưa cập nhật"
        dob = elderly.date_of_birthday.strftime('%d/%m/%Y') if elderly.date_of_birthday else "chưa cập nhật"
        gender = "Nam" if elderly.gender else "Nữ"
        return (f"Dạ, thông tin hồ sơ của {pronoun}: Tên là {name}, sinh ngày {dob}, giới tính {gender} ạ.", [])

    if intent == 'time':
        now_vn = now + datetime.timedelta(hours=7) # Convert to UTC+7 roughly
        time_str = now_vn.strftime('%H:%M, thứ %w ngày %d/%m/%Y').replace('thứ 0', 'Chủ nhật').replace('thứ 1', 'Thứ 2').replace('thứ 2', 'Thứ 3').replace('thứ 3', 'Thứ 4').replace('thứ 4', 'Thứ 5').replace('thứ 5', 'Thứ 6').replace('thứ 6', 'Thứ 7')
        return (f"Dạ, bây giờ là {time_str} ạ.", [])

    if intent == 'app_support':
        return (f"Dạ, cháu xin hướng dẫn {pronoun} ạ:\n"
                f"1. Để xem lịch khám, {pronoun} vào mục 'Lịch Khám' ở màn hình chính.\n"
                f"2. Để xem thuốc, {pronoun} lướt ngang ở trang chủ hoặc vào 'Đơn Thuốc'.\n"
                f"3. Để xem bệnh án, {pronoun} nhấn vào nút 'Hồ sơ bệnh án' trong tab Cá nhân ạ.", [])

    if intent == 'greeting':
        return (f"Dạ cháu chào {pronoun}, cháu là trợ lý ảo chăm sóc sức khỏe. Cháu có thể giúp {pronoun} xem Lịch khám, Đơn thuốc, Chỉ số sức khỏe, và gọi Người thân ạ. {pronoun.capitalize()} cần cháu giúp gì không ạ?", [])

    return (f"Dạ, cháu chưa hiểu rõ ý của {pronoun}. {pronoun.capitalize()} có thể hỏi cháu các câu như: \"Lịch khám của tôi\", \"Xem bệnh án\", \"Hôm nay uống thuốc gì\", \"Gọi người thân\". Cháu sẽ cố gắng giúp {pronoun} ạ!", [])


# ─── API View ─────────────────────────────────────────────────────────────────

class ElderlyChatbotView(generics.CreateAPIView):
   

    def post(self, request):
        elderly_id = request.data.get('elderly_id')
        message = request.data.get('message', '').strip()

        if not elderly_id or not message:
            return Response(
                {"error": "Thiếu elderly_id hoặc message"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            elderly = Elderly.objects.get(elderlyid=elderly_id)
        except Elderly.DoesNotExist:
            return Response(
                {
                    "response": "Dạ, cháu không nhận diện được tài khoản của ông/bà, "
                                "vui lòng đăng nhập lại ạ.",
                    "intent": "error",
                },
                status=status.HTTP_200_OK,
            )

        # Xác định đại từ xưng hô
        # gender = True → Nam (ông), False / None → Nữ (bà)
        pronoun = "ông" if elderly.gender else "bà"

        # Chuẩn hoá message
        msg_norm = _remove_accents(message)

        # Phát hiện intent
        intent = _detect_intent(msg_norm)

        # Thu thập context_data từ DB
        now = timezone.now()
        ctx = _gather_context(elderly, now)

        # Tạo câu trả lời CHỈ dựa trên context_data
        response_text, images = _build_response(intent, ctx, pronoun)

        return Response(
            {
                "response": response_text,
                "intent": intent,
                "images": images,
            },
            status=status.HTTP_200_OK,
        )
