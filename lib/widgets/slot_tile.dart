import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/slot.dart';

/// A single cell in the slot grid. Available = tappable, brand-tinted with a
/// gradient accent; booked = greyed out and disabled. The visual distinction
/// is required by the brief.
class SlotTile extends StatelessWidget {
  const SlotTile({super.key, required this.slot, required this.onTap});

  final Slot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final booked = slot.isBooked;
    // A past slot can't be booked. "Booked" takes label priority over "Passed".
    final past = !booked && slot.isPast;
    final disabled = booked || past;

    final (IconData icon, String label) = booked
        ? (Icons.lock_rounded, 'Booked')
        : past
            ? (Icons.history_rounded, 'Passed')
            : (Icons.bolt_rounded, 'Open');

    final fg = disabled ? AppTheme.inkMuted : Colors.white;

    return Opacity(
      opacity: past ? 0.6 : 1, // extra visual cue that the time has gone
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled ? null : AppTheme.limeGradient,
          color: disabled ? const Color(0xFFEDEFED) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: disabled ? null : AppTheme.tileShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: disabled ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot.startTime,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 12, color: fg),
                      const SizedBox(width: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
