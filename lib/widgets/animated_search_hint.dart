import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Animated rotating search hint text where the prefix (e.g. "Search ") remains constant,
/// and only the keyword after it smoothly animates and rotates.
class AnimatedSearchHint extends StatefulWidget {
  final String prefix;
  final List<String> hints;
  final TextStyle? style;
  final Duration interval;

  const AnimatedSearchHint({
    super.key,
    this.prefix = 'Search ',
    required this.hints,
    this.style,
    this.interval = const Duration(milliseconds: 2600),
  });

  @override
  State<AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<AnimatedSearchHint> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (timer) {
      if (mounted && widget.hints.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.hints.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hints.isEmpty) return const SizedBox.shrink();

    final textStyle = widget.style ??
        const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Constant static prefix (never moves or flickers)
        if (widget.prefix.isNotEmpty)
          Text(
            widget.prefix,
            style: textStyle.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7A818B),
            ),
          ),

        // Rotating keyword only
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final inOffset = Tween<Offset>(
                begin: const Offset(0.0, 0.75),
                end: Offset.zero,
              ).animate(animation);

              return SlideTransition(
                position: inOffset,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Text(
              widget.hints[_currentIndex],
              key: ValueKey<int>(_currentIndex),
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
