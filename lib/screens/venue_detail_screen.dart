import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/booking_repository.dart';
import '../data/venue_repository.dart';
import '../models/slot.dart';
import '../models/venue.dart';
import '../providers/slots_provider.dart';
import '../providers/view_state.dart';
import '../widgets/brand.dart';
import '../widgets/slot_tile.dart';
import '../widgets/state_views.dart';

/// Venue detail: date picker + slot grid. SlotsProvider is scoped to this
/// screen (one venue) and polls for live "booked" updates while open.
class VenueDetailScreen extends StatelessWidget {
  const VenueDetailScreen({super.key, required this.venue});
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SlotsProvider(
        context.read<VenueRepository>(),
        context.read<BookingRepository>(),
        venue.id,
        venue.openHour,
        venue.closeHour,
      )
        ..load()
        ..startPolling(),
      child: _VenueDetailView(venue: venue),
    );
  }
}

class _VenueDetailView extends StatelessWidget {
  const _VenueDetailView({required this.venue});
  final Venue venue;

  Future<void> _pickDate(BuildContext context, SlotsProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) await provider.setDate(picked);
  }

  Future<void> _confirmAndBook(BuildContext context, SlotsProvider provider, Slot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmBookingDialog(
        venue: venue,
        slot: slot,
        date: provider.selectedDate,
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final outcome = await provider.book(slot);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case BookOutcome.success:
        messenger.showSnackBar(SnackBar(
          content: const Text('Booked! See it in My Bookings.'),
          backgroundColor: AppTheme.brand,
        ));
      case BookOutcome.slotTaken:
        // The graceful path required by the brief: clear message + grid refreshed.
        messenger.showSnackBar(SnackBar(
          content: const Text('Sorry, that slot was just booked by someone else.'),
          backgroundColor: AppTheme.danger,
        ));
      case BookOutcome.error:
        messenger.showSnackBar(SnackBar(
          content: Text(provider.errorMessage ?? 'Booking failed. Try again.'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SlotsProvider>();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        venue.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${venue.sport} · ${venue.location}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DateStrip(provider: provider, onPickDate: () => _pickDate(context, provider)),
              ],
            ),
          ),
          const _SlotLegend(),
          Expanded(child: _buildBody(context, provider)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, SlotsProvider provider) {
    switch (provider.state) {
      case ViewState.loading:
      case ViewState.idle:
        return const LoadingView(label: 'Loading slots…');
      case ViewState.error:
        return ErrorView(message: provider.errorMessage ?? 'Failed to load slots', onRetry: provider.load);
      case ViewState.empty:
        final now = DateTime.now();
        final d = provider.selectedDate;
        final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
        return EmptyView(
          message: isToday
              ? 'No more slots today.\nTry another date.'
              : 'No slots for this date',
          icon: Icons.event_busy_rounded,
        );
      case ViewState.success:
        return RefreshIndicator(
          color: AppTheme.brand,
          onRefresh: provider.refresh,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemCount: provider.slots.length,
            itemBuilder: (context, i) {
              final slot = provider.slots[i];
              return SlotTile(
                slot: slot,
                onTap: () => _confirmAndBook(context, provider, slot),
              );
            },
          ),
        );
    }
  }
}

/// Horizontal strip of quick-pick day chips + a "more dates" calendar button.
class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.provider, required this.onPickDate});
  final SlotsProvider provider;
  final VoidCallback onPickDate;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(10, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == days.length) {
            return _CalendarChip(onTap: onPickDate);
          }
          final day = days[i];
          final selected = _sameDay(day, provider.selectedDate);
          return _DayChip(
            day: day,
            isToday: _sameDay(day, today),
            selected: selected,
            onTap: () => provider.setDate(day),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isToday,
    required this.selected,
    required this.onTap,
  });
  final DateTime day;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dow = DateFormat('EEE').format(day); // Mon
    final dom = DateFormat('d').format(day); // 7
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 54,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? 'Today' : dow,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.brandDark : Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dom,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: selected ? AppTheme.ink : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarChip extends StatelessWidget {
  const _CalendarChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text('More', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Small legend explaining the slot colours.
class _SlotLegend extends StatelessWidget {
  const _SlotLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          _legendDot(AppTheme.brand, 'Available'),
          const SizedBox(width: 18),
          _legendDot(const Color(0xFFCDD3CE), 'Booked'),
          const Spacer(),
          const Text(
            'Tap a slot to book',
            style: TextStyle(fontSize: 12, color: AppTheme.inkMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Modern booking-confirmation dialog: a sport badge header, a grouped details
/// card, and a clear Cancel / Book action row.
class _ConfirmBookingDialog extends StatelessWidget {
  const _ConfirmBookingDialog({required this.venue, required this.slot, required this.date});

  final Venue venue;
  final Slot slot;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SportAvatar(sport: venue.sport, size: 60),
            const SizedBox(height: 16),
            Text('Confirm booking', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            const Text(
              'Review your slot before you book.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Grouped details card.
            Container(
              decoration: BoxDecoration(
                color: AppTheme.canvas,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _DetailRow(icon: Icons.stadium_rounded, label: 'Venue', value: venue.name),
                  const Divider(height: 1),
                  _DetailRow(icon: Icons.schedule_rounded, label: 'Time', value: slot.label),
                  const Divider(height: 1),
                  _DetailRow(
                    icon: Icons.event_rounded,
                    label: 'Date',
                    value: DateFormat('EEE, d MMM yyyy').format(date),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions.
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Book'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A label/value row inside the confirm dialog's details card.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: AppTheme.brandDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.inkMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: AppTheme.ink, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
