import 'package:flutter/material.dart';
import 'responsive_spacing.dart';

class AdaptiveContentPadding extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const AdaptiveContentPadding({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? ResponsiveSpacing.pagePadding(context);

    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      );
    }

    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}
