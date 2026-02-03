import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class ModernNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const ModernNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class ModernNavBar extends StatelessWidget {
  final int currentIndex;
  final List<ModernNavBarItem> items;
  final ValueChanged<int> onTap;

  const ModernNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs + bottomPadding,
      ),
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth =
              (constraints.maxWidth - (AppSpacing.sm * 2)) / items.length;
          final indicatorPosition = AppSpacing.sm + (currentIndex * itemWidth);

          return Stack(
            children: [
              // Background blur effect
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),

              // Active indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                left: indicatorPosition,
                top: AppSpacing.sm,
                child: Container(
                  width: itemWidth,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Nav items
              Row(
                children:
                    items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSelected = index == currentIndex;

                      return Expanded(
                        child: _buildNavItem(
                          item: item,
                          isSelected: isSelected,
                          onTap: () => onTap(index),
                        ),
                      );
                    }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required ModernNavBarItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey(isSelected),
                color:
                    isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.6),
                size: AppSpacing.iconLg,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTypography.bodySmall.copyWith(
                color:
                    isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Floating Action Button tarzı ek buton
class ModernFloatingNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const ModernFloatingNavButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppSpacing.screenHorizontal + 60,
      right: AppSpacing.screenHorizontal + AppSpacing.lg,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            onTap: onPressed,
            child: Icon(icon, color: Colors.white, size: AppSpacing.iconLg),
          ),
        ),
      ),
    );
  }
}
