import 'package:flutter/material.dart';
import 'responsive_spacing.dart';

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Border? border;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = ResponsiveSpacing.cardBorderRadius(context);
    final defaultBg = isDark ? const Color(0xFF0A2218) : Colors.white;
    final defaultBorder = Border.all(
      color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF2F7),
      width: 1,
    );

    final cardWidget = Container(
      padding: padding ?? EdgeInsets.all(ResponsiveSpacing.cardGap(context)),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? defaultBorder,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
