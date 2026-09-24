import sys
p = 'lib/screens/settings_screen.dart'
s = open(p, encoding='utf-8').read()
pairs = [
 ("'hint': 'Password (Google users: type DELETE)'", "'hint': 'Password'"),
 ("'hint': 'මුරපදය (Google පරිශීලකයන්: DELETE ටයිප් කරන්න)'", "'hint': 'මුරපදය'"),
 ("'hint': 'கடவுச்சொல் (Google பயனர்கள்: DELETE என தட்டச்சு செய்க)'", "'hint': 'கடவுச்சொல்'"),
]
n = 0
for a, b in pairs:
    if a in s:
        s = s.replace(a, b); n += 1
open(p, 'w', encoding='utf-8').write(s)
print('patched', n, 'of 3')
