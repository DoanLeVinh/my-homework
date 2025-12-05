import 'package:flutter/material.dart';
import 'dart:ui';

/// Text với shadow và backdrop để nổi bật trên mọi nền
class EnhancedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool useShadow;
  final bool useBackdrop;

  const EnhancedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.useShadow = true,
    this.useBackdrop = false,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: style?.copyWith(
        shadows: useShadow
            ? [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 8,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ]
            : null,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    if (useBackdrop) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: textWidget,
      );
    }

    return textWidget;
  }
}

/// iOS 18 Liquid Glass Card với backdrop blur và multi-layer effects
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final double? borderRadius;
  final double blurIntensity;
  final bool showShimmer;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.tintColor,
    this.borderRadius,
    this.blurIntensity = 20.0,
    this.showShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 24.0;
    final baseTint = tintColor ?? Colors.white;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Outer shadow (darker)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: Offset(0, 10),
            spreadRadius: -4,
          ),
          // Inner glow (lighter)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: Offset(0, -2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurIntensity,
            sigmaY: blurIntensity,
          ),
          child: Container(
            padding: padding ?? EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseTint.withValues(alpha: 0.25),
                  baseTint.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                width: 1.5,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Legacy EnhancedCard - kept for backward compatibility
class EnhancedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final Border? border;

  const EnhancedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border:
            border ??
            Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// iOS 18 Liquid Glass Button với gradient và shimmer
class LiquidGlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.color,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 16.0;
    final baseColor = color ?? Colors.blue;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor.withValues(alpha: 0.8),
                  baseColor.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(radius),
                child: Padding(
                  padding:
                      padding ??
                      EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: icon != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: Colors.white, size: 20),
                            SizedBox(width: 12),
                            child,
                          ],
                        )
                      : child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title với underline gradient
class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final double fontSize;

  const SectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: fontSize + 4),
              SizedBox(width: 12),
            ],
            EnhancedText(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 3,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
