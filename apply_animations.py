#!/usr/bin/env python3
"""Adds animations to Home, Wallet, Sell and Settings screens.
Run from the project root (~/Fistt):  python3 apply_animations.py
Safe to run twice. A change whose code was not found is skipped and reported."""
import os, sys

IMPORT_LINE = "import '../widgets/anim.dart';\n"
applied, skipped = [], []


def skip_string(s, i):
    q = s[i]
    triple = s.startswith(q * 3, i)
    end = q * 3 if triple else q
    j = i + (3 if triple else 1)
    while j < len(s):
        if s[j] == '\\':
            j += 2
            continue
        if s.startswith(end, j):
            return j + len(end)
        if s.startswith('${', j):
            j = find_close(s, j + 1) + 1
            continue
        j += 1
    raise ValueError('unterminated string')


def find_close(s, i):
    """s[i] is an opening bracket; return index of its matching closing bracket."""
    depth = 0
    j = i
    while j < len(s):
        c = s[j]
        if c in '\'"':
            j = skip_string(s, j)
            continue
        if s.startswith('//', j):
            j = s.index('\n', j)
            continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
            if depth == 0:
                return j
        j += 1
    raise ValueError('no matching bracket')


def read(p):
    with open(p, encoding='utf-8') as f:
        return f.read()


def write(p, t):
    with open(p, 'w', encoding='utf-8') as f:
        f.write(t)


def add_import(s):
    if IMPORT_LINE in s:
        return s
    key = "import 'package:flutter/material.dart';\n"
    return s.replace(key, key + IMPORT_LINE, 1) if key in s else IMPORT_LINE + s


def wrap_after(s, anchor, target, prefix, suffix=')'):
    """Find `anchor`, then the first `target` (e.g. 'return Container(') after it,
    and wrap the call expression: return <prefix>Container(...)<suffix>;"""
    a = s.find(anchor)
    if a < 0:
        return None
    t = s.find(target, a)
    if t < 0:
        return None
    expr_start = t + len('return ')
    open_idx = s.index('(', expr_start)
    close_idx = find_close(s, open_idx)
    return s[:expr_start] + prefix + s[expr_start:close_idx + 1] + suffix + s[close_idx + 1:]


def patch(path, name, fn, needs_import=True):
    if not os.path.exists(path):
        skipped.append(f'{name}: file not found ({path})')
        return
    s = read(path)
    new = fn(s)
    if new is None:
        skipped.append(f'{name}: code not found (already changed?)')
        return
    if new == s:
        skipped.append(f'{name}: already applied')
        return
    if needs_import:
        new = add_import(new)
    write(path, new)
    applied.append(name)


# ---- 1) app-wide page transition (main.dart)
def p_main(s):
    if 'pageTransitionsTheme' in s:
        return s
    key = '        useMaterial3: true,\n'
    if key not in s:
        return None
    return s.replace(key, key + (
        '        pageTransitionsTheme: const PageTransitionsTheme(builders: {\n'
        '          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),\n'
        '          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),\n'
        '        }),\n'), 1)


patch('lib/main.dart', 'Page transition (main.dart)', p_main, needs_import=False)


# ---- 2) home: tab fade + list stagger
def p_home_tab(s):
    old = 'body: _pages[_tab],'
    if old not in s:
        return None
    return s.replace(old, 'body: AnimatedSwitcher(duration: const Duration(milliseconds: 220), '
                          'child: KeyedSubtree(key: ValueKey<int>(_tab), child: _pages[_tab])),', 1)


def p_home_list(s):
    if 'staggerDelay(i), child: Container(' in s:
        return s
    return wrap_after(s, "final sellerName = l['sellerDisplayName'] ?? '';", 'return Container(',
                      'FadeSlideIn(delay: staggerDelay(i), child: ')


def p_home_promo(s):
    if 'staggerDelay(i), child: InkWell(' in s:
        return s
    return wrap_after(s, 'final p = _promotions[i];', 'return InkWell(',
                      'FadeSlideIn(delay: staggerDelay(i), child: ')


patch('lib/screens/home_screen.dart', 'Home: tab fade', p_home_tab)
patch('lib/screens/home_screen.dart', 'Home: listing cards stagger', p_home_list)
patch('lib/screens/home_screen.dart', 'Home: promotions stagger', p_home_promo)


# ---- 3) wallet: balance count-up
def p_wallet(s):
    old = ("Text('LKR ${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, "
           "fontSize: 30, fontWeight: FontWeight.bold)),")
    if old not in s:
        return None
    return s.replace(old, "CountUpText(value: _balance, prefix: 'LKR ', style: const TextStyle(color: Colors.white, "
                          "fontSize: 30, fontWeight: FontWeight.bold)),", 1)


patch('lib/screens/wallet_screen.dart', 'Wallet: balance count-up', p_wallet)


# ---- 4) sell screen: rental fields expand + thumbnail pop-in
def p_sell_rental(s):
    if 'AnimatedSize(' in s and "_saleType == 'rental') ...[" in s and 'alignment: Alignment.topCenter' in s:
        return s
    anchor = "if (_saleType == 'rental') ...["
    a = s.find(anchor)
    if a < 0:
        return None
    br = s.index('[', a)
    close = find_close(s, br)
    head = ("AnimatedSize(duration: const Duration(milliseconds: 250), curve: Curves.easeOut, "
            "alignment: Alignment.topCenter, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [\n")
    tail = "\n]))"
    return s[:a] + head + s[a:close + 1] + tail + s[close + 1:]


def p_sell_thumb(s):
    if 'PopIn(key: ValueKey(_screenshots[i].path)' in s:
        return s
    return wrap_after(s, 'if (i == _screenshots.length) {', 'return Stack(',
                      'PopIn(key: ValueKey(_screenshots[i].path), child: ')


patch('lib/screens/add_listing_screen.dart', 'Sell: rental fields expand', p_sell_rental)
patch('lib/screens/add_listing_screen.dart', 'Sell: thumbnail pop-in', p_sell_thumb)


# ---- 5) settings: rows fade in
def p_settings(s):
    if 'return FadeSlideIn(child: ListTile(' in s:
        return s
    a = s.find('Widget _tile(IconData icon, String title, String? subtitle, VoidCallback onTap) {')
    if a < 0:
        return None
    return wrap_after(s, 'Widget _tile(IconData icon, String title, String? subtitle, VoidCallback onTap) {',
                      'return ListTile(', 'FadeSlideIn(child: ')


patch('lib/screens/settings_screen.dart', 'Settings: rows fade in', p_settings)

print('\nApplied:')
for a in applied:
    print('  +', a)
print('Skipped:')
for k in skipped:
    print('  -', k)
if not os.path.exists('lib/widgets/anim.dart'):
    print('\nWARNING: lib/widgets/anim.dart is missing - copy it into lib/widgets/ first!')
    sys.exit(1)
