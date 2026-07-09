import sys
import re

sys.stdout.reconfigure(encoding='utf-8')

with open('lib/utils/medication_dialog_helper.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# find all strings enclosed in single quotes
matches = re.findall(r"'([^']*)'", content)

for match in matches:
    if any(ord(c) > 127 for c in match) or 'Kh' in match or 'Th' in match or 'ch' in match or 'ng' in match or 'nh' in match:
        print(match)
