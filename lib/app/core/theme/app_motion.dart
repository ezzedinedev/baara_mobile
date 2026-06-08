import 'package:flutter/animation.dart' show Curve, Curves;


class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration stagger = Duration(milliseconds: 40);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const double listSlideOffset = 18;
}
