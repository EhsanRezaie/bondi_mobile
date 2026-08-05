import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/utils/formatters.dart';

class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final String? lastSeenAt;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.lastSeenAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final successColor =
        isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;

    if (isOnline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: successColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Online',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: successColor,
            ),
          ),
        ],
      );
    }

    if (lastSeenAt != null) {
      final lastSeen = DateTime.tryParse(lastSeenAt!);
      if (lastSeen != null) {
        final text = formatLastSeen(lastSeen);
        return Text(
          'Last seen $text',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: mutedColor,
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}
