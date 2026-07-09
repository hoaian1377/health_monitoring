import sys

def remove_method(filepath, method_name):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    start_idx = -1
    for i, line in enumerate(lines):
        if method_name in line and "void" in line:
            start_idx = i
            break
            
    if start_idx == -1:
        print(f"Could not find {method_name} in {filepath}")
        return
        
    brace_count = 0
    in_method = False
    end_idx = -1
    
    for i in range(start_idx, len(lines)):
        line = lines[i]
        brace_count += line.count('{')
        brace_count -= line.count('}')
        
        if '{' in line:
            in_method = True
            
        if in_method and brace_count == 0:
            end_idx = i
            break
            
    if end_idx != -1:
        del lines[start_idx:end_idx+1]
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"Removed {method_name} from {filepath} (lines {start_idx+1}-{end_idx+1})")
    else:
        print(f"Could not find end of {method_name} in {filepath}")

remove_method(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\screens\caregiver\caregiver_home_screen.dart', '_showAddMedicationDialog')
remove_method(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\screens\caregiver\medicine_management_screen.dart', 'MedicationDialogHelper_remove_me')
