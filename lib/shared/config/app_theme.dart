import 'dart:ui';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Premium design tokens layered on top of [AppColors].
///
/// Keeps the existing brand palette intact while introducing the gradients,
/// shadows and glass surfaces that give the app its elevated, "premium" feel.
/// Everything here is derived from the same primary/navy hues already in use,
/// so the visual language stays coherent — just richer.

// ── Gradients ────────────────────────────────────────────────────────────────

class AppGradients {
  const AppGradients._();

  /// Deep navy header used across the operator experience. A diagonal blend
  /// gives depth without competing with foreground content.
  static const LinearGradient operatorHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF283149), Color(0xFF1A1F2E), Color(0xFF12151F)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Electric blue header for the supervisor experience — same geometry as the
  /// operator header so the two roles feel like one product.
  static const LinearGradient supervisorHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3358E8), Color(0xFF1F4FD9), Color(0xFF1A3FB5)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Brand gradient for primary calls-to-action and the logo mark.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E5BF0), Color(0xFF1F4FD9), Color(0xFF1A3FB5)],
  );

  /// Barely-there vertical wash for scaffold backgrounds — lifts flat white
  /// into something with a hint of depth.
  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F9FD), Color(0xFFEEF1F8)],
  );
}

// ── Shadows ──────────────────────────────────────────────────────────────────

class AppShadows {
  const AppShadows._();

  /// Soft resting shadow for cards — diffuse and low-contrast so surfaces feel
  /// like they float a millimetre above the background.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF1A1D2E).withValues(alpha: 0.05),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF1A1D2E).withValues(alpha: 0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// Stronger shadow for interactive / elevated surfaces (buttons, dialogs).
  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: const Color(0xFF1A1D2E).withValues(alpha: 0.12),
      blurRadius: 36,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: const Color(0xFF1A1D2E).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Colored glow cast beneath brand-colored elements (primary buttons, logo).
  static List<BoxShadow> brand({double opacity = 0.35}) => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: opacity),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  /// Soft ambient shadow beneath the header, tinted with the header hue so the
  /// header reads as a raised panel rather than a painted rectangle.
  static List<BoxShadow> header(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.28),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];
}

// ── Reusable decorations ─────────────────────────────────────────────────────

class AppDecorations {
  const AppDecorations._();

  /// The canonical premium card surface: white, generously rounded, hairline
  /// border and a soft floating shadow. Replaces the ad-hoc BoxDecorations
  /// that were duplicated across every screen.
  static BoxDecoration card({
    Color? color,
    double radius = 20,
    Color? borderColor,
    List<BoxShadow>? shadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? const Color(0xFFEDEFF4)),
      boxShadow: shadow ?? AppShadows.card,
    );
  }
}

// ── Glass surface ────────────────────────────────────────────────────────────

/// A frosted-glass container: blurs whatever is behind it and lays a
/// translucent tint + hairline highlight on top. Used for premium dialogs and
/// floating overlays where depth should show through.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double radius;
  final Color tint;
  final double tintOpacity;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final List<BoxShadow>? shadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.radius = 24,
    this.tint = Colors.white,
    this.tintOpacity = 0.72,
    this.padding,
    this.border,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? AppShadows.elevated,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: tintOpacity),
              borderRadius: BorderRadius.circular(radius),
              border:
                  border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
