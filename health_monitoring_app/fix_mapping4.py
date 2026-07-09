import sys

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    mapping = {
        'Ä ang': 'Đang',
        'Ä‘Æ°á» ng': 'đường',
        'Chá» n': 'Chọn',
        'Liá» u': 'Liều',
        'giá» ': 'giờ',
        'Giá» ': 'Giờ',
        'chá» n': 'chọn',
        'Ä Ã£': 'Đã',
    }
    
    for k, v in mapping.items():
        content = content.replace(k, v)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_file(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\utils\medication_dialog_helper.dart')
