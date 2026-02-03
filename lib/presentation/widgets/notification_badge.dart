import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final double? size;
  final Color? backgroundColor;
  final Color? textColor;

  const NotificationBadge({
    super.key,
    required this.count,
    this.size,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final badgeSize = size ?? 18.0;
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.error,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          displayCount,
          style: AppTypography.bodySmall.copyWith(
            color: textColor ?? Colors.white,
            fontSize: badgeSize * 0.5,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// Badge positioned on top of another widget
class BadgedIcon extends StatelessWidget {
  final Widget icon;
  final int badgeCount;
  final double? badgeSize;
  final Color? badgeColor;

  const BadgedIcon({
    super.key,
    required this.icon,
    required this.badgeCount,
    this.badgeSize,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: NotificationBadge(
              count: badgeCount,
              size: badgeSize,
              backgroundColor: badgeColor,
            ),
          ),
      ],
    );
  }
}

