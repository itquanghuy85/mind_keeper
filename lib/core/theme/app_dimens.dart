import 'package:flutter/rendering.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
}

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double pill = 999;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius xxxlAll = BorderRadius.all(Radius.circular(xxxl));
  static const BorderRadius xxlTop = BorderRadius.vertical(top: Radius.circular(xxl));
  static const BorderRadius xlTop = BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

abstract final class AppSizes {
  static const double controlHeight = 52;
  static const double controlHeightSm = 44;
  static const double controlHeightLg = 56;
  static const double chipHeight = 36;
  static const double touchTarget = 48;
  static const double iconXs = 14;
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;
  static const double bottomNavHeight = 70;
  static const double badgeSm = 32;
  static const double badgeMd = 40;
  static const double badgeLg = 48;
  static const double cardElevation = 0;
  static const double cardElevationElevated = 8;
  static const double dividerThickness = 0.5;
}