import json
import base64

with open('lib/utils/medication_dialog_helper.dart', 'rb') as f:
    lines = f.readlines()

mapping = [
    (b'\xc3\x84 ang', 'Đang'),
    (b'Ch\xc3\xa1\xc2\xbb n', 'Chọn'),
    (b'Li\xc3\xa1\xc2\xbb u', 'Liều'),
    (b'Gi\xc3\xa1\xc2\xbb ', 'Giờ'),
    (b'gi\xc3\xa1\xc2\xbb ', 'giờ'),
    (b'ch\xc3\xa1\xc2\xbb n', 'chọn'),
    (b'\xc3\x84\xc2\x91\xc3\x86\xc2\xb0\xc3\xa1\xc2\xbb\xc2\x9dng', 'đường'),
    (b'\xc3\x84 \xc3\x83\xc2\xa3', 'Đã'),
]

for i, b_line in enumerate(lines):
    for bad_bytes, good_str in mapping:
        if bad_bytes in b_line:
            print(f"Line {i+1}: {b_line.decode('utf-8', errors='replace').strip()}")
            break
