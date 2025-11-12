import 'package:flutter/material.dart';

class SwipeIndicator extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;
  final bool shouldBounce;

  const SwipeIndicator({
    Key? key,
    required this.isExpanded,
    required this.onTap,
    required this.shouldBounce,
  }) : super(key: key);

  @override
  State<SwipeIndicator> createState() => _SwipeIndicatorState();
}

class _SwipeIndicatorState extends State<SwipeIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -10)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -10, end: 0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_bounceController);

    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.shouldBounce) {
            _bounceController.forward(from: 0);
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(SwipeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldBounce) {
      _bounceController.forward(from: 0);
    } else {
      _bounceController.stop();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.shouldBounce && !widget.isExpanded ? _bounceAnimation.value : 0, 0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Container(
              key: ValueKey<bool>(widget.isExpanded),
              width: 5,
              height: 100,
              margin: EdgeInsets.only(
                right: widget.isExpanded ? 0 : 2,
                left: widget.isExpanded ? 2 : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.horizontal(
                  left: widget.isExpanded ? Radius.zero : const Radius.circular(2),
                  right: widget.isExpanded ? const Radius.circular(2) : Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(widget.isExpanded ? 2 : -2, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 