import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';

class SegmentedTab {
  final String label;
  final int badgeCount;

  const SegmentedTab({required this.label, this.badgeCount = 0});
}

class SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<SegmentedTab> tabs;

  const SegmentedTabs({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSecondary : AppTheme.lightSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Row(
              children: List.generate(tabs.length, (i) {
                final selected = controller.index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.animateTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusChip - 4,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              tabs[i].label,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: (isPersian
                                      ? AppTheme.bodyBoldFa
                                      : AppTheme.bodyBold)
                                  .copyWith(
                                fontSize: 14,
                                color: selected ? Colors.white : mutedColor,
                              ),
                            ),
                          ),
                          if (tabs[i].badgeCount > 0) ...[
                            const SizedBox(width: 4),
                            _TabBadge(count: tabs[i].badgeCount),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _TabBadge extends StatelessWidget {
  final int count;

  const _TabBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 99 ? '99+' : count.toString();
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        displayCount,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          height: 1.1,
        ),
      ),
    );
  }
}