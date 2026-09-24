import sys
p = 'lib/widgets/fancy_nav_bar.dart'
s = open(p, encoding='utf-8').read()
if 'items[centerIndex!].label' in s:
    sys.exit('already patched')

def rep(old, new):
    global s
    if s.count(old) != 1:
        sys.exit('anchor not found (%d): %s' % (s.count(old), old.strip()[:60]))
    s = s.replace(old, new)

label = """              if (hasCenter)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 1 / items.length,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelected(centerIndex!);
                        },
                        child: Text(
                          items[centerIndex!].label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selectedIndex == centerIndex ? FontWeight.w700 : FontWeight.w500,
                            color: selectedIndex == centerIndex ? Colors.white : AppColors.hint,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
"""
# circle: a little smaller and raised, so the label fits under it inside the bar
rep("              if (hasCenter)\n                Positioned(\n                  top: 24,",
    label + "              if (hasCenter)\n                Positioned(\n                  top: 10,")
rep("                        width: 58,\n                        height: 58,", "                        width: 54,\n                        height: 54,")
open(p, 'w', encoding='utf-8').write(s)
print('patched')
