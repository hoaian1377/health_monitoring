import sys

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    mapping = {
        'Ä ang': 'Đang',
        'Thuá»‘c': 'Thuốc',
        'Chá» n': 'Chọn',
        'Nháº­p': 'Nhập',
        'Chá»‰': 'Chỉ',
        'nháº­p': 'nhập',
        'nhá»¯ng': 'những',
        'gÃ¬': 'gì',
        'tháº­t': 'thật',
        'cáº§n': 'cần',
        'Ä Ã£': 'Đã',
        'thÃªm': 'thêm',
        'thÃ\xa0nh': 'thành',
        'thành': 'thành',
        'TrÆ°á»›c': 'Trước',
        'trÆ°á»›c': 'trước',
        'bá»¯a': 'bữa',
        'huyáº¿t': 'huyết',
        'Ã¡p': 'áp',
        'giá» ': 'giờ',
        'Giá» ': 'Giờ',
        'Tiá»ƒu': 'Tiểu',
        'Ä‘Æ°á» ng': 'đường',
        'CÃ¡ch': 'Cách',
        'dÃ¹ng': 'dùng',
        'HÃ\xa0ng': 'Hàng',
        'NgÃ\xa0y': 'Ngày',
        'ngÃ\xa0y': 'ngày',
        'lá»‹ch': 'lịch',
        'CÃ²n': 'Còn',
        'Tá»•ng': 'Tổng',
        'Liá» u': 'Liều',
        'lÆ°á»£ng': 'lượng',
        'Chá» n': 'Chọn',
        'Ã­t': 'ít',
        'thao': 'thao',
        'tÃ¡c': 'tác',
        'chá» n': 'chọn',
        'thay': 'thay',
        'Ä‘á»•i': 'đổi',
        'Ä‘á»ƒ': 'để',
        'báº¯t': 'bắt',
        'Huyết': 'Huyết',
        'áp': 'áp',
        'Khác': 'Khác',
        'đầu': 'đầu',
    }
    
    for k, v in mapping.items():
        content = content.replace(k, v)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_file(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\utils\medication_dialog_helper.dart')
