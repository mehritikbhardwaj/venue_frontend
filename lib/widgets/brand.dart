import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Visual mapping for a sport: an icon + a gradient, so every venue/booking
/// gets consistent, recognisable colour-coding across the app.
class SportStyle {
  const SportStyle(this.icon, this.gradient);
  final IconData icon;
  final Gradient gradient;

  static SportStyle of(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('badminton') || s.contains('tennis')) {
      return const SportStyle(Icons.sports_tennis_rounded, AppTheme.limeGradient);
    }
    if (s.contains('football') || s.contains('soccer') || s.contains('turf')) {
      return const SportStyle(Icons.sports_soccer_rounded, AppTheme.brandGradient);
    }
    if (s.contains('cricket')) {
      return const SportStyle(Icons.sports_cricket_rounded, AppTheme.amberGradient);
    }
    if (s.contains('basket')) {
      return const SportStyle(Icons.sports_basketball_rounded, AppTheme.amberGradient);
    }
    return const SportStyle(Icons.sports_handball_rounded, AppTheme.brandGradient);
  }
}

/// A rounded square with a sport's gradient + icon. Used as a list "avatar".
class SportAvatar extends StatelessWidget {
  const SportAvatar({super.key, required this.sport, this.size = 52, this.active = true});

  final String sport;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final style = SportStyle.of(sport);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: active ? style.gradient : null,
        color: active ? null : const Color(0xFFE6EAE7),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: active ? AppTheme.tileShadow : null,
      ),
      child: Icon(
        style.icon,
        color: active ? Colors.white : AppTheme.inkMuted,
        size: size * 0.5,
      ),
    );
  }
}

/// The curved gradient hero used at the top of primary screens. Children are
/// laid out over the brand gradient with a soft decorative blob.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 28),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusXl)),
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: Stack(
          children: [
            // Decorative translucent blob, top-right.
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small status pill (e.g. "Available", "Cancelled", "Confirmed").
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 12 : 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A white floating card with the app's soft shadow + large radius. Used as the
/// base surface for content cards across screens.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
