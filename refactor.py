import sys
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add import if missing
    import_stmt = "import '../../utils/medication_dialog_helper.dart';"
    if import_stmt not in content:
        # insert after package:flutter/material.dart
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_stmt)
    
    # Remove _scanPrescriptionIntoFields
    # We will use regex to remove from Future<void> _scanPrescriptionIntoFields to the end of its block
    content = re.sub(r'Future<void> _scanPrescriptionIntoFields.*?onSelectionsSelected\(selected\);\n\s*\}\n\s*\}\s*catch\s*\(e\)\s*\{.*?\n\s*\}\n\s*\}', '', content, flags=re.DOTALL)
    
    # Remove _showAddMedicationDialog
    content = re.sub(r'void _showAddMedicationDialog.*?editScheduleId,\n\s*\}\).*?onPressed: \(\) \{\n\s*if \(!isSubmitting\).*?\n\s*\}\n\s*\}\n\s*\}\n\s*,\n\s*\)\s*,\n\s*\)\s*;\n\s*\}', '', content, flags=re.DOTALL)

    # Replace call sites
    # onPressed: _showAddMedicationDialog,
    content = content.replace("onPressed: _elderlyList.isEmpty\n                        ? null\n                        : _showAddMedicationDialog,",
                              "onPressed: _elderlyList.isEmpty\n                        ? null\n                        : () => MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _currentElderlyId!, onSuccess: _loadElderlyDetails),")
    content = content.replace("onPressed: _currentElderlyId == null\n                        ? null\n                        : _showAddMedicationDialog,",
                              "onPressed: _currentElderlyId == null\n                        ? null\n                        : () => MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _currentElderlyId!, onSuccess: _loadElderlyDetails),")
    
    # _showAddMedicationDialog();
    content = content.replace("_showAddMedicationDialog();", "MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _currentElderlyId!, onSuccess: _loadElderlyDetails);")
    
    # Edit call
    content = re.sub(r'_showAddMedicationDialog\(\s*initialName: med\.name,\s*initialDosage: med\.dosage,\s*initialInstruction: med\.instruction,\s*initialTime: med\.times\.isNotEmpty \? med\.times\.first : null,\s*editScheduleId: int\.tryParse\(med\.id\),\s*\);',
                     'MedicationDialogHelper.showAddMedicationDialog(context: context, elderlyId: _currentElderlyId!, onSuccess: _loadElderlyDetails, initialName: med.name, initialDosage: med.dosage, initialInstruction: med.instruction, initialTime: med.times.isNotEmpty ? med.times.first : null, editScheduleId: int.tryParse(med.id));', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

process_file(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\screens\caregiver\caregiver_home_screen.dart')
