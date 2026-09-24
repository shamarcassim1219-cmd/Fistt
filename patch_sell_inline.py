import re, sys
p = 'lib/screens/home_screen.dart'
s = open(p, encoding='utf-8').read()
m = re.findall(r'^[ \t]*centerIndex:\s*\d+,[ \t]*\n', s, re.M)
if len(m) == 0:
    sys.exit('centerIndex line not found (already patched?)')
if len(m) != 1:
    sys.exit('found %d centerIndex lines, expected 1' % len(m))
s = re.sub(r'^[ \t]*centerIndex:\s*\d+,[ \t]*\n', '', s, count=1, flags=re.M)
open(p, 'w', encoding='utf-8').write(s)
print('patched: Sell is now a normal button in the row')
