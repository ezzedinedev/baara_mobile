import 'package:flutter/material.dart';

/// Rayons de coin centralisés pour la charte OpporTune BF.
/// Privilégier ces constantes à `BorderRadius.circular(...)` ad-hoc.
class AppRadius {
  AppRadius._();

  static const Radius xsRadius = Radius.circular(6);
  static const Radius smRadius = Radius.circular(10);
  static const Radius mdRadius = Radius.circular(14);
  static const Radius lgRadius = Radius.circular(20);
  static const Radius xlRadius = Radius.circular(28);
  static const Radius pillRadius = Radius.circular(999);

  static const BorderRadius xs = BorderRadius.all(xsRadius);
  static const BorderRadius sm = BorderRadius.all(smRadius);
  static const BorderRadius md = BorderRadius.all(mdRadius);
  static const BorderRadius lg = BorderRadius.all(lgRadius);
  static const BorderRadius xl = BorderRadius.all(xlRadius);
  static const BorderRadius pill = BorderRadius.all(pillRadius);

  static const BorderRadius sheetTop = BorderRadius.vertical(top: lgRadius);
}
