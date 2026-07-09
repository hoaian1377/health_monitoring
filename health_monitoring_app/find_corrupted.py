import sys
import re

def print_corrupted(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    matches = re.finditer(r'[\x80-\uFFFF]', content)
    words = set()
    for match in matches:
        start = max(0, match.start() - 20)
        end = min(len(content), match.end() + 20)
        words.add(content[start:end].replace('\n', ' '))
    
    for w in list(words)[:50]:
        print(w)

print_corrupted(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\utils\medication_dialog_helper.dart')
