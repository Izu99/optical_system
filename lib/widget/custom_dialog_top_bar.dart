import 'package:flutter/material.dart';

/// A custom top bar for dialogs/pages with window controls (close, minimize, maximize), theme-driven.
class CustomDialogTopBar extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final Color? backgroundColor;
  final Color? iconColor;
  final double borderRadius;

  const CustomDialogTopBar({
    super.key,
    required this.title,
    required this.icon,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = backgroundColor ?? colorScheme.primary.withOpacity(0.05);
    final ic = iconColor ?? colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ic,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.minimize_rounded),
                tooltip: 'Minimize',
                onPressed: onMinimize,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.crop_square_rounded),
                tooltip: 'Maximize',
                onPressed: onMaximize,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
                onPressed: onClose ?? () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                color: colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
