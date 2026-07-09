import sys
import re

sys.stdout.reconfigure(encoding='utf-8')

with open('lib/utils/medication_dialog_helper.dart', 'r', encoding='utf-8') as f:
    content = f.read()

for i, line in enumerate(content.split('\n')):
    # check for weird sequences that could be corrupted text like '?' inside letters, or 'Khng', or 'thu vi?n'
    if re.search(r'[a-zA-Záàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ]\?', line) or 'Khng' in line or 'thu vi?n' in line or '?nh' in line:
        if not re.search(r'^\s*//', line):
            print(f"Line {i+1}: {line.strip()}")
