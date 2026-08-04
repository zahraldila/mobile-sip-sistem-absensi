import 'package:flutter/material.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}
