import 'package:flutter/material.dart';

class DotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const DotIndicator({super.key, required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 18 : 10,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
