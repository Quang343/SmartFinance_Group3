import 'package:flutter/material.dart';

class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  const ScaleOnTap({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.96,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget childWidget = widget.child;
    if (_isHovered) {
      childWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(
          // Subtle color overlay on hover: brightens dark elements, deepens light elements
          isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
          BlendMode.srcATop,
        ),
        child: childWidget,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0, // Subtle scale up on desktop hover
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedOpacity(
              opacity: _isHovered ? 0.95 : 1.0, // Thinned opacity shift combined with color filter
              duration: const Duration(milliseconds: 150),
              child: childWidget,
            ),
          ),
        ),
      ),
    );
  }
}
