import 'package:flutter/material.dart';

class AppShadow {
  AppShadow._();

  static const BoxShadow soft = BoxShadow(
    color: Color(0x140F172A),
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> ambient = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
