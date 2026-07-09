import os

def check_dir(d):
    for root, dirs, files in os.walk(d):
        for f in files:
            if f.endswith('.dart'):
                filepath = os.path.join(root, f)
                with open(filepath, 'r', encoding='utf-8', errors='replace') as file:
                    for i, line in enumerate(file):
                        if '' in line:
                            print(f"{filepath}:{i+1}: {line.strip()}")

check_dir('lib/screens/caregiver')
check_dir('lib/screens/elderly')
check_dir('lib/utils')
