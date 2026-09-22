import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class FancyNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const FancyNavItem({required this.icon, required this.selectedIcon, required this.label});
}

/// Floating bottom navigation bar. The selected tab gets a glowing gradient pill,
/// the icon pops a little bigger. If [centerIndex] is set, that item renders as
/// a raised circular button overlapping the top edge of the bar.
class FancyNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<FancyNavItem> items;
  final int? centerIndex;

  const FancyNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    this.centerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final dur = reduce ? Duration.zero : const Duration(milliseconds: 240);
    final hasCenter = centerIndex != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SizedBox(
          height: hasCenter ? 96 : 68,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x59000000), blurRadius: 20, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    children: List.generate(items.length, (i) {
                      if (i == centerIndex) {
                        return const Expanded(child: SizedBox());
                      }
                      final item = items[i];
                      final selected = i == selectedIndex;
                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: item.label,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              if (!selected) HapticFeedback.selectionClick();
                              onSelected(i);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: AnimatedContainer(
                                duration: dur,
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: selected
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [AppColors.primary, Color(0xFF9B7BFF)],
                                        )
                                      : null,
                                  boxShadow: selected
                                      ? const [BoxShadow(color: Color(0x666C4CF1), blurRadius: 14, offset: Offset(0, 4))]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: selected ? 1.14 : 1.0,
                                      duration: dur,
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        selected ? item.selectedIcon : item.icon,
                                        size: 24,
                                        color: selected ? Colors.white : AppColors.hint,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                        color: selected ? Colors.white : AppColors.hint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              if (hasCenter)
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(centerIndex!);
                      },
                      child: AnimatedContainer(
                        duration: dur,
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, Color(0xFF9B7BFF)],
                          ),
                          border: Border.all(color: AppColors.bg, width: 4),
                          boxShadow: const [
                            BoxShadow(color: Color(0x996C4CF1), blurRadius: 18, offset: Offset(0, 6)),
                          ],
                        ),
                        child: Icon(
                          selectedIndex == centerIndex ? items[centerIndex!].selectedIcon : items[centerIndex!].icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
