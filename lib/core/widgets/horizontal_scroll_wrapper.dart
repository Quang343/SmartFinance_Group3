import 'package:flutter/material.dart';

class HorizontalScrollWrapper extends StatefulWidget {
  final Widget child;
  final double scrollAmount;

  const HorizontalScrollWrapper({
    super.key,
    required this.child,
    this.scrollAmount = 200,
  });

  @override
  State<HorizontalScrollWrapper> createState() => _HorizontalScrollWrapperState();
}

class _HorizontalScrollWrapperState extends State<HorizontalScrollWrapper> {
  final ScrollController _controller = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateButtons());
  }

  @override
  void didUpdateWidget(HorizontalScrollWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateButtons());
  }

  void _updateButtons() {
    if (!mounted || !_controller.hasClients) return;
    final showLeft = _controller.position.pixels > 0;
    final showRight = _controller.position.pixels < _controller.position.maxScrollExtent;
    
    if (showLeft != _showLeftButton || showRight != _showRightButton) {
      setState(() {
        _showLeftButton = showLeft;
        _showRightButton = showRight;
      });
    }
  }

  void _scroll(double offset) {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      (_controller.position.pixels + offset).clamp(
        0.0,
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updateButtons);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // We try to grab the nearest card color, otherwise use scaffold background
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _updateButtons());
            return false;
          },
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: widget.child,
          ),
        ),
        if (_showLeftButton)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    bgColor,
                    bgColor.withValues(alpha: 0.8),
                    bgColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => _scroll(-widget.scrollAmount),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.chevron_left_rounded, size: 20, color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
            ),
          ),
        if (_showRightButton)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    bgColor.withValues(alpha: 0.0),
                    bgColor.withValues(alpha: 0.8),
                    bgColor,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  onTap: () => _scroll(widget.scrollAmount),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
