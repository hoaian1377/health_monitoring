import glob, os

for file in glob.glob('lib/screens/caregiver/*.dart'):
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("import '../utils/api_service.dart';", "import '../../utils/api_service.dart';")
    content = content.replace("import '../utils/alarm_service.dart';", "import '../../utils/alarm_service.dart';")
    content = content.replace("import 'change_password_screen.dart';", "import '../common/change_password_screen.dart';")
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)
print('Fixed imports in caregiver screens.')
