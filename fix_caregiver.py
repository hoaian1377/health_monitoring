import sys
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove _showScanPrescriptionDialog
    content = re.sub(r'void _showScanPrescriptionDialog.*?doseAmountCtrl\.text = doseMatch\.group\(1\)!\;\n\s*\}\n\s*\}\n\s*\}\n\s*\}\n\s*\)\s*\)\s*;\n\s*\}\n\s*\)\s*;\n\s*\}', '', content, flags=re.DOTALL)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

process_file(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\screens\caregiver\caregiver_home_screen.dart')
