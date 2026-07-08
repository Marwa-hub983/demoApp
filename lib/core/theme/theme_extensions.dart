import 'package:flutter/material.dart';

class AppMetrics extends ThemeExtension<AppMetrics> {
  final double space4;
  final double space8;
  final double space12;
  final double space16;
  final double space24;
  final double space32;
  final double space48;

  final double radius4;
  final double radius8;
  final double radius12;
  final double radius16;
  final double radius24;
  final double radiusRound;

  final double cardElevation;
  final double buttonElevation;

  const AppMetrics({
    required this.space4,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space24,
    required this.space32,
    required this.space48,
    required this.radius4,
    required this.radius8,
    required this.radius12,
    required this.radius16,
    required this.radius24,
    required this.radiusRound,
    required this.cardElevation,
    required this.buttonElevation,
  });

  factory AppMetrics.standard() => const AppMetrics(
        space4: 4.0,
        space8: 8.0,
        space12: 12.0,
        space16: 16.0,
        space24: 24.0,
        space32: 32.0,
        space48: 48.0,
        radius4: 4.0,
        radius8: 8.0,
        radius12: 12.0,
        radius16: 16.0,
        radius24: 24.0,
        radiusRound: 999.0,
        cardElevation: 2.0,
        buttonElevation: 0.0,
      );

  @override
  AppMetrics copyWith({
    double? space4,
    double? space8,
    double? space12,
    double? space16,
    double? space24,
    double? space32,
    double? space48,
    double? radius4,
    double? radius8,
    double? radius12,
    double? radius16,
    double? radius24,
    double? radiusRound,
    double? cardElevation,
    double? buttonElevation,
  }) {
    return AppMetrics(
      space4: space4 ?? this.space4,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
      space24: space24 ?? this.space24,
      space32: space32 ?? this.space32,
      space48: space48 ?? this.space48,
      radius4: radius4 ?? this.radius4,
      radius8: radius8 ?? this.radius8,
      radius12: radius12 ?? this.radius12,
      radius16: radius16 ?? this.radius16,
      radius24: radius24 ?? this.radius24,
      radiusRound: radiusRound ?? this.radiusRound,
      cardElevation: cardElevation ?? this.cardElevation,
      buttonElevation: buttonElevation ?? this.buttonElevation,
    );
  }

  @override
  AppMetrics lerp(ThemeExtension<AppMetrics>? other, double t) {
    if (other is! AppMetrics) return this;
    return AppMetrics(
      space4: _lerpDouble(space4, other.space4, t),
      space8: _lerpDouble(space8, other.space8, t),
      space12: _lerpDouble(space12, other.space12, t),
      space16: _lerpDouble(space16, other.space16, t),
      space24: _lerpDouble(space24, other.space24, t),
      space32: _lerpDouble(space32, other.space32, t),
      space48: _lerpDouble(space48, other.space48, t),
      radius4: _lerpDouble(radius4, other.radius4, t),
      radius8: _lerpDouble(radius8, other.radius8, t),
      radius12: _lerpDouble(radius12, other.radius12, t),
      radius16: _lerpDouble(radius16, other.radius16, t),
      radius24: _lerpDouble(radius24, other.radius24, t),
      radiusRound: _lerpDouble(radiusRound, other.radiusRound, t),
      cardElevation: _lerpDouble(cardElevation, other.cardElevation, t),
      buttonElevation: _lerpDouble(buttonElevation, other.buttonElevation, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color shimmeringBase;
  final Color shimmeringHighlight;
  final Color success;
  final Color warning;
  final Color shadowColor;
  final Gradient primaryGradient;

  const AppColorsExtension({
    required this.shimmeringBase,
    required this.shimmeringHighlight,
    required this.success,
    required this.warning,
    required this.shadowColor,
    required this.primaryGradient,
  });

  @override
  AppColorsExtension copyWith({
    Color? shimmeringBase,
    Color? shimmeringHighlight,
    Color? success,
    Color? warning,
    Color? shadowColor,
    Gradient? primaryGradient,
  }) {
    return AppColorsExtension(
      shimmeringBase: shimmeringBase ?? this.shimmeringBase,
      shimmeringHighlight: shimmeringHighlight ?? this.shimmeringHighlight,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      shadowColor: shadowColor ?? this.shadowColor,
      primaryGradient: primaryGradient ?? this.primaryGradient,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      shimmeringBase: Color.lerp(shimmeringBase, other.shimmeringBase, t)!,
      shimmeringHighlight: Color.lerp(shimmeringHighlight, other.shimmeringHighlight, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      primaryGradient: Gradient.lerp(primaryGradient, other.primaryGradient, t)!,
    );
  }
}
