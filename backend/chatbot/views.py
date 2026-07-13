

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


# ─── Intent keywords ─────────────────────────────────────────────────────────

# Mỗi intent = (tên, danh sách từ khoá)
INTENT_KEYWORDS = {
    'appointment': [
        'lich kham', 'tai kham', 'benh vien', 'di kham',
        'hen kham', 'khi nao kham', 'kham o dau', 'may gio kham',
        'hom nao di', 'lich hen', 'cuoc hen',
    ],
    'medication': [
        'thuoc', 'uong gi', 'lieu luong', 'uong thuoc',
        'lich uong', 'hom nay uong', 'uong luc nao', 'don thuoc',
        'toa thuoc', 'uong may vien',
    ],
    'health_metrics': [
        'huyet ap', 'duong huyet', 'can nang', 'nhip tim',
        'chi so', 'suc khoe', 'nhiet do', 'do huyet ap',
        'do duong', 'lan do', 'ket qua do',
    ],
    'medical_records': [
        'benh an', 'ho so', 'ho so benh', 'giay to',
        'ket qua', 'xet nghiem', 'chan doan', 'bi benh gi',
        'giay kham', 'ket qua kham', 'benh ly',
    ],
    'doctor': [
        'bac si', 'ai dieu tri', 'ai kham', 'bac sy',
    ],
    'greeting': [
        'chao', 'xin chao', 'khoe khong', 'ten gi',
        'ban la ai', 'ai do', 'hello', 'hi',
    ],
}


def _detect_intent(msg_norm: str) -> str:
    """Xác định intent từ message đã chuẩn hoá (không dấu, viết thường)."""
    # Ưu tiên theo thứ tự cụ thể → chung
    priority = [
        'appointment', 'medical_records', 'medication',
        'health_metrics', 'doctor', 'greeting',
    ]
    for intent in priority:
        for kw in INTENT_KEYWORDS[intent]:
            if kw in msg_norm:
                return intent
    return 'unknown'


# ─── Thu thập context_data ────────────────────────────────────────────────────

def _gather_context(elderly, now):
    """Truy vấn DB, trả về dict context_data cho từng loại."""
    ctx = {}

    # appointments (sắp tới)
    ctx['appointments'] = list(
        Appointment.objects.filter(
            elderlyid=elderly,
            appointment_date__gte=now.date(),
        ).order_by('appointment_date', 'appointment_time')
    )

    # medications
    ctx['medications'] = list(
        MedicationSchedule.objects.filter(
            elderlyid=elderly,
        ).select_related('medicationid')
    )

    # health_metrics (bản ghi gần nhất)
    ctx['health_metrics'] = (
        HealthMetrics.objects.filter(elderlyid=elderly)
        .order_by('-recorded_at')
        .first()
    )

    # documents (bệnh án / giấy tờ, gần nhất trước)
    ctx['documents'] = list(
        MedicalDocument.objects.filter(elderlyid=elderly)
        .order_by('-upload_at')[:5]
    )

    # doctor – tổng hợp từ appointment + document
    doctor = None
    latest_app = (
        Appointment.objects.filter(elderlyid=elderly)
        .exclude(doctor_name__isnull=True).exclude(doctor_name='')
        .order_by('-appointment_date').first()
    )
    if latest_app:
        doctor = {
            'name': latest_app.doctor_name,
            'location': latest_app.location or '',
            'source': 'appointment',
        }
    else:
        latest_doc = (
            MedicalDocument.objects.filter(elderlyid=elderly)
            .exclude(doctor_name__isnull=True).exclude(doctor_name='')
            .order_by('-upload_at').first()
        )
        if latest_doc:
            doctor = {
                'name': latest_doc.doctor_name,
                'location': latest_doc.hospital or '',
                'source': 'document',
            }
    ctx['doctor'] = doctor

    return ctx


# ─── Tạo câu trả lời ─────────────────────────────────────────────────────────

def _build_response(intent: str, ctx: dict, pronoun: str) -> str:
    # ── 1. Lịch khám ─────────────────────────────────────────────────────────
    if intent == 'appointment':
        appointments = ctx['appointments']
        if not appointments:
            return (
                f"Dạ, hiện tại {pronoun} chưa có lịch hẹn khám "
                f"hay tái khám nào sắp tới trong hệ thống ạ.",
                []
            )
        parts = []
        for a in appointments:
            time_str = str(a.appointment_time)[:5] if a.appointment_time else "chưa rõ giờ"
            date_str = a.appointment_date.strftime('%d/%m/%Y') if a.appointment_date else "chưa rõ ngày"
            loc = a.location or "chưa rõ địa điểm"
            doctor = f", bác sĩ {a.doctor_name}" if a.doctor_name else ""
            parts.append(f"ngày {date_str} lúc {time_str} tại {loc}{doctor}")
        return (
            f"Dạ, {pronoun} có lịch khám vào "
            + "; ".join(parts)
            + f". {pronoun.capitalize()} nhớ đi đúng giờ nhé ạ.",
            []
        )

    # ── 2. Thuốc ─────────────────────────────────────────────────────────────
    if intent == 'medication':
        meds = ctx['medications']
        if not meds:
            return (
                f"Dạ, hiện tại {pronoun} chưa có lịch uống thuốc nào "
                f"được ghi nhận trong hệ thống ạ.",
                []
            )
        med_parts = []
        for s in meds:
            if s.medicationid:
                name = s.medicationid.name or "chưa rõ tên"
                dosage = f", liều {s.medicationid.dosage}" if s.medicationid.dosage else ""
                time_str = str(s.time)[:5] if s.time else "chưa rõ giờ"
                freq = f" ({s.frequency})" if s.frequency else ""
                instruction = f" – {s.medicationid.instruction}" if s.medicationid.instruction else ""
                med_parts.append(f"{name}{dosage} uống lúc {time_str}{freq}{instruction}")
        if not med_parts:
            return (
                f"Dạ, {pronoun} có lịch uống thuốc nhưng chưa có "
                f"chi tiết tên thuốc trong hệ thống ạ.",
                []
            )
        return (
            f"Dạ, lịch uống thuốc của {pronoun} gồm có:\n• "
            + "\n• ".join(med_parts)
            + f"\n{pronoun.capitalize()} nhớ uống đúng giờ nhé ạ!",
            []
        )

    # ── 3. Chỉ số sức khỏe ───────────────────────────────────────────────────
    if intent == 'health_metrics':
        m = ctx['health_metrics']
        if not m:
            return (
                f"Dạ, hiện tại {pronoun} chưa có dữ liệu đo sức khỏe nào "
                f"trong hệ thống ạ.",
                []
            )
        date_str = m.recorded_at.strftime("%d/%m/%Y %H:%M") if m.recorded_at else "gần đây"
        parts = []
        if m.blood_pressure:
            parts.append(f"huyết áp {m.blood_pressure} mmHg")
        if m.heart_rate:
            parts.append(f"nhịp tim {m.heart_rate} bpm")
        if m.blood_sugar:
            parts.append(f"đường huyết {m.blood_sugar} mmol/L")
        if m.temperature:
            parts.append(f"nhiệt độ {m.temperature}°C")
        if not parts:
            return (
                f"Dạ, bản ghi sức khỏe gần nhất của {pronoun} "
                f"(ngày {date_str}) chưa có số liệu chi tiết ạ.",
                []
            )
        return (
            f"Dạ, theo lần đo gần nhất vào {date_str}: "
            + ", ".join(parts)
            + f". {pronoun.capitalize()} nhớ giữ gìn sức khỏe nhé ạ!",
            []
        )

    # ── 4. Hồ sơ / bệnh án ──────────────────────────────────────────────────
    if intent == 'medical_records':
        docs = ctx['documents']
        if not docs:
            return (
                f"Dạ, hiện tại chưa có thông tin bệnh án "
                f"hoặc hồ sơ khám bệnh của {pronoun} trong hệ thống ạ.",
                []
            )
        doc = docs[0]  # bản ghi gần nhất
        date_str = doc.upload_at.strftime("%d/%m/%Y") if doc.upload_at else "gần đây"
        doc_type = doc.document_type or "hồ sơ y tế"
        hospital = doc.hospital or "chưa rõ bệnh viện"
        doctor = f", bác sĩ {doc.doctor_name}" if doc.doctor_name else ""
        diagnosis = f"\nChẩn đoán: {doc.diagnosis}" if doc.diagnosis else ""
        result_text = f"\nKết quả: {doc.result}" if doc.result else ""

        # Thu thập ảnh từ tất cả documents có file_url
        images = []
        for d in docs:
            if d.file_url:
                images.append(d.file_url)

        return (
            f"Dạ, bệnh án gần nhất của {pronoun} là \"{doc_type}\", "
            f"được khám tại {hospital}{doctor} vào ngày {date_str} ạ."
            f"{diagnosis}{result_text}",
            images
        )

    # ── 5. Bác sĩ ────────────────────────────────────────────────────────────
    if intent == 'doctor':
        doc_info = ctx['doctor']
        if not doc_info:
            return (
                f"Dạ, hiện tại {pronoun} chưa có thông tin "
                f"bác sĩ điều trị trong hệ thống ạ.",
                []
            )
        loc = f" tại {doc_info['location']}" if doc_info['location'] else ""
        return (
            f"Dạ, bác sĩ theo dõi gần nhất của {pronoun} là "
            f"Bác sĩ {doc_info['name']}{loc} ạ.",
            []
        )

    # ── 6. Chào hỏi ──────────────────────────────────────────────────────────
    if intent == 'greeting':
        return (
            f"Dạ cháu chào {pronoun}, cháu là trợ lý ảo chăm sóc sức khỏe. "
            f"Cháu có thể giúp {pronoun} xem:\n"
            f"• Lịch khám\n"
            f"• Đơn thuốc & lịch uống thuốc\n"
            f"• Chỉ số sức khỏe\n"
            f"• Hồ sơ bệnh án\n"
            f"{pronoun.capitalize()} cứ hỏi cháu nhé ạ!",
            []
        )

    # ── 7. Không hiểu ────────────────────────────────────────────────────────
    return (
        f"Dạ, cháu chưa hiểu rõ ý của {pronoun}. "
        f"{pronoun.capitalize()} có thể hỏi cháu các câu như:\n"
        f"• \"Lịch khám của tôi\"\n"
        f"• \"Xem bệnh án\"\n"
        f"• \"Hôm nay uống thuốc gì\"\n"
        f"• \"Chỉ số huyết áp\"\n"
        f"Cháu sẽ cố gắng giúp {pronoun} ạ!",
        []
    )


# ─── API View ─────────────────────────────────────────────────────────────────

class ElderlyChatbotView(generics.CreateAPIView):
    """
    POST /api/chatbot/

    Body: { "elderly_id": int, "message": str }
    Response: { "response": str, "intent": str }
    """

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
