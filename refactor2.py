import sys
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add import if missing
    import_stmt = "import '../../utils/medication_dialog_helper.dart';"
    if import_stmt not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_stmt)
    
    # Remove _scanPrescriptionIntoFields
    content = re.sub(r'Future<void> _scanPrescriptionIntoFields.*?onSelectionsSelected\(selected\);\n\s*\}\n\s*\}\s*catch\s*\(e\)\s*\{.*?\n\s*\}\n\s*\}', '', content, flags=re.DOTALL)
    
    # Remove _showAddMedicationDialog
    content = re.sub(r'void _showAddMedicationDialog.*?editScheduleId,\n\s*\}\).*?onPressed: \(\) \{\n\s*if \(!isSubmitting\).*?\n\s*\}\n\s*\}\n\s*\}\n\s*,\n\s*\)\s*,\n\s*\)\s*;\n\s*\}', '', content, flags=re.DOTALL)

    # Check elderlyId reference. Is it widget.elderlyId?
    # Replace call sites
    content = content.replace("onPressed: _showAddMedicationDialog,",
                              "onPressed: () => MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: int.parse(widget.elderlyId), onSuccess: _loadData),")
    
    content = content.replace("_showAddMedicationDialog(", "MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: int.parse(widget.elderlyId), onSuccess: _loadData, ")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

process_file(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\screens\caregiver\medicine_management_screen.dart')
