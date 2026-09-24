import sys

def load(p):
    return open(p, encoding='utf-8').read()

def rep(s, old, new, name):
    if s.count(old) != 1:
        sys.exit('%s: anchor not found (%d): %s' % (name, s.count(old), old[:60]))
    return s.replace(old, new)

# ---------- 1. translations ----------
p = 'lib/services/app_localizations.dart'
s = load(p)
new_keys = [
 ('more', 'More', 'තවත්', 'மேலும்'),
 ('alerts', 'Alerts', 'දැනුම්දීම්', 'அறிவிப்புகள்'),
 ('refund_policy', 'Refund Policy', 'මුදල් ආපසු ගෙවීමේ ප්‍රතිපත්තිය', 'பணத்தைத் திரும்பப் பெறும் கொள்கை'),
 ('privacy_and_data', 'Privacy & Data', 'රහස්‍යතාව සහ දත්ත', 'தனியுரிமை & தரவு'),
 ('about', 'About', 'ගැන', 'பற்றி'),
 ('tap_to_check_updates', 'Tap to check for updates', 'යාවත්කාලීන පරීක්ෂා කිරීමට තට්ටු කරන්න', 'புதுப்பிப்புகளைச் சரிபார்க்க தட்டவும்'),
]
lines = ''
for k, en, si, ta in new_keys:
    if "'%s':" % k in s:
        print('skip existing key', k)
        continue
    lines += "    '%s': {'English': '%s', 'Sinhala': '%s', 'Tamil': '%s'},\n" % (k, en, si, ta)
if lines:
    s = rep(s, "    'settings': {'English': 'Settings',", lines + "    'settings': {'English': 'Settings',", p)
    open(p, 'w', encoding='utf-8').write(s)
print('translations ok')

# ---------- 2. settings screen ----------
p = 'lib/screens/settings_screen.dart'
s = load(p)
if "AppLocalizations.t('refund_policy')" not in s:
    s = rep(s, "_SectionHeader('Privacy & Data')", "_SectionHeader(AppLocalizations.t('privacy_and_data'))", p)
    s = rep(s, "'Refund Policy', null,", "AppLocalizations.t('refund_policy'), null,", p)
    s = rep(s, "_SectionHeader('About')", "_SectionHeader(AppLocalizations.t('about'))", p)
    s = rep(s, "'App Version', '$_appVersion — Tap to check for updates',",
               "AppLocalizations.t('app_version'), '$_appVersion — ${AppLocalizations.t('tap_to_check_updates')}',", p)
    open(p, 'w', encoding='utf-8').write(s)
print('settings ok')

# ---------- 3. bottom bar ----------
p = 'lib/screens/home_screen.dart'
s = load(p)
if "AppLocalizations.t('alerts')" not in s:
    s = rep(s, "const FancyNavItem(icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: 'More'),",
               "FancyNavItem(icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: AppLocalizations.t('more')),", p)
    s = rep(s, "label: 'Alerts', showBadge", "label: AppLocalizations.t('alerts'), showBadge", p)
    open(p, 'w', encoding='utf-8').write(s)
print('home ok')
