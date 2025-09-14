import 'dart:math';
import 'package:flutter/material.dart';

class AppColors {
  static const List<Color> _accents = <Color>[
    Color(0xFF2F9BFF), // blue
    Color(0xFFFF4D4D), // red
    Color(0xFF21C16B), // green
    Color(0xFFFFA000), // amber
    Color(0xFF7B61FF), // purple
    Color(0xFF00B8A9), // teal
    Color(0xFFFF7A59), // orange
    Color(0xFF00C2FF), // sky
  ];

  static final Random _rnd = Random();

  /// Random mỗi lần gọi (không ổn định)
  static Color randomAccent() {
    return _accents[_rnd.nextInt(_accents.length)];
  }

  /// Tạo màu nhạt hơn nếu muốn (shade100)
  static Color shade100(Color c, [double opacity = .10]) {
    return c.withOpacity(opacity.clamp(0.0, 1.0));
  }
}
