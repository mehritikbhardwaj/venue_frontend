import 'package:flutter/material.dart';

import '../models/slot.dart';

/// A single cell in the slot grid. Available = tappable & highlighted;
/// booked = greyed out and disabled. The visual distinction is required.
class SlotTile extends StatelessWidget {
  const SlotTile({super.key, required this.slot, required this.onTap});

  final Slot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final booked = slot.isBooked;

    return Material(
      color: booked ? scheme.surfaceContainerHighest : scheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: booked ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: booked ? scheme.outlineVariant : scheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slot.startTime,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: booked ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booked ? 'Booked' : 'Available',
                style: TextStyle(
                  fontSize: 11,
                  color: booked ? scheme.error : scheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
