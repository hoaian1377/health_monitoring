import sys
with open('lib/utils/medication_dialog_helper.dart', 'r', encoding='utf-8') as f:
    text = f.read()

mapping = {
    'Ä ang': 'Đang',
    'Ch«. n': 'Chọn',
    'Li¬� u': 'Liều',
    'Giã» ': 'GiỜ',
    'giã» ': 'giỜ',
    'ch© n': 'chọn',
    'Ä‘Æ°âË§ng': 'đường',
    'Ä ã': 'Đã',
    'Chẻ’': 'Chỉ',
    'huy¢Ë�t': 'huyết',
    'ng\u00a0y': 'ngày',
    'thà\u00a0nh': 'thành',
    'Ä’i'them': 'đổi',
    'vïªªn': 'viên',
    'Ãªch': 'Cách',
    'dÃ¹ng': 'dùng',
}

for k, v in mapping.items():
    text = text.replace(k, v)

with open('lib/utils/medication_dialog_helper.dart', 'w', encoding='utf-8') as f:
    f.write(text)
