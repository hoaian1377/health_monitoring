import sys
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove the broken method declaration
    content = re.sub(r'void MedicationDialogHelper\.showAddMedicationDialog\(context: context, elderlyId: int\.parse\(widget\.elderlyId\), onSuccess: _loadData, \{.*?editScheduleId,\n\s*\}\).*?onPressed: \(\) \{\n\s*if \(!isSubmitting\).*?\n\s*\}\n\s*\}\n\s*\}\n\s*,\n\s*\)\s*,\n\s*\)\s*;\n\s*\}', '', content, flags=re.DOTALL)

    # Fix the call sites
    content = content.replace('int.parse(widget.elderlyId)', '_selectedElderlyId!')
    content = content.replace('_loadData', '() => _loadMedicationSchedules(_selectedElderlyId!)')

    # Remove the broken _scanPrescriptionIntoFields that was missed
    content = re.sub(r'Future<void> _scanPrescriptionIntoFields.*?onSelectionsSelected\(selected\);\n\s*\}\n\s*\}\s*catch\s*\(e\)\s*\{.*?\n\s*\}\n\s*\}', '', content, flags=re.DOTALL)

    # Replace the separate Quét toa thuốc tile
    content = re.sub(r'void _showScanPrescriptionDialog.*?doseAmountCtrl\.text = doseMatch\.group\(1\)!\;\n\s*\}\n\s*\}\n\s*\}\n\s*\}\n\s*\)\s*\)\s*;\n\s*\}\n\s*\)\s*;\n\s*\}', '', content, flags=re.DOTALL)
    
    # Replace the call to _showScanPrescriptionDialog()
    content = content.replace('_showScanPrescriptionDialog();', 'MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _selectedElderlyId!, onSuccess: () => _loadMedicationSchedules(_selectedElderlyId!));')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

process_file(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\screens\caregiver\medicine_management_screen.dart')
