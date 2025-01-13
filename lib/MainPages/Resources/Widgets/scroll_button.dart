// lib/MainPages/Resources/Widgets/scroll_buttons.dart

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class ScrollButton extends StatefulWidget {
  const ScrollButton({
    super.key,
    required this.isAtFirstParent,
    required this.isAtLastParent,
    required this.onScrollUp,
    required this.onScrollDown,
  });
  final bool isAtFirstParent;
  final bool isAtLastParent;
  final VoidCallback onScrollUp;
  final VoidCallback onScrollDown;

  @override
  _ScrollButtonState createState() => _ScrollButtonState();
}

class _ScrollButtonState extends State<ScrollButton>
    with TickerProviderStateMixin {
  late AnimationController _scrollUpController;
  late AnimationController _scrollDownController;
  late Animation<double> _scrollUpAnimation;
  late Animation<double> _scrollDownAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _scrollUpController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollDownController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Define the rotation animation (shake effect)
    _scrollUpAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]).animate(_scrollUpController);

    _scrollDownAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: .05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
    ]).animate(_scrollDownController);
  }

  @override
  void dispose() {
    _scrollUpController.dispose();
    _scrollDownController.dispose();
    super.dispose();
  }

  Future<void> _triggerVibration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 100);
    }
  }

  void _onScrollUpPressed() {
    if (widget.isAtFirstParent) {
      _scrollUpController.forward(from: 0);
      _triggerVibration();
    } else {
      widget.onScrollUp();
    }
  }

  void _onScrollDownPressed() {
    if (widget.isAtLastParent) {
      _scrollDownController.forward(from: 0);
      _triggerVibration();
    } else {
      widget.onScrollDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scroll Up Button with Wiggle Animation
          AnimatedBuilder(
            animation: _scrollUpAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _scrollUpAnimation.value,
                child: child,
              );
            },
            child: FloatingActionButton(
              key: const Key('ScrollUpButton'),
              onPressed: _onScrollUpPressed,
              heroTag: 'scrollUp',
              backgroundColor:
                  widget.isAtFirstParent ? Colors.grey.withOpacity(0.6) : null,
              tooltip: 'Scroll to previous parent comment',
              child: const Icon(Icons.arrow_drop_up),
            ),
          ),
          const SizedBox(width: 20),
          // Scroll Down Button with Wiggle Animation
          AnimatedBuilder(
            animation: _scrollDownAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _scrollDownAnimation.value,
                child: child,
              );
            },
            child: FloatingActionButton(
              key: const Key('ScrollDownButton'),
              onPressed: _onScrollDownPressed,
              heroTag: 'scrollDown',
              backgroundColor:
                  widget.isAtLastParent ? Colors.grey.withOpacity(0.6) : null,
              tooltip: 'Scroll to next parent comment',
              child: const Icon(Icons.arrow_drop_down),
            ),
          ),
        ],
      ),
    );
  }
}
