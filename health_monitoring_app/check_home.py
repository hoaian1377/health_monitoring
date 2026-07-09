import sys
import re

sys.stdout.reconfigure(encoding='utf-8')

with open('lib/screens/caregiver/caregiver_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

matches = re.finditer(r'[ÃáÄÆá½§Ð]', content)
words = set()
for match in matches:
    start = max(0, match.start() - 20)
    end = min(len(content), match.end() + 20)
    words.add(content[start:end].replace('\n', ' '))

for w in list(words)[:50]:
    print(w.strip())
