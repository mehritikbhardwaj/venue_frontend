import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/booking_repository.dart';
import '../data/venue_repository.dart';
import '../models/slot.dart';
import '../models/venue.dart';
import '../providers/slots_provider.dart';
import '../providers/view_state.dart';
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
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm booking'),
        content: Text('${venue.name}\n${slot.label} on '
            '${DateFormat('EEE, d MMM yyyy').format(provider.selectedDate)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Book')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final outcome = await provider.book(slot);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case BookOutcome.success:
        messenger.showSnackBar(const SnackBar(
          content: Text('Booked! See it in My Bookings.'),
          backgroundColor: Colors.green,
        ));
      case BookOutcome.slotTaken:
        // The graceful path required by the brief: clear message + grid refreshed.
        messenger.showSnackBar(const SnackBar(
          content: Text('Sorry, that slot was just booked by someone else.'),
          backgroundColor: Colors.redAccent,
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
      appBar: AppBar(
        title: Text(venue.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEE, d MMM yyyy').format(provider.selectedDate),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(context, provider),
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: const Text('Change date'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(context, provider),
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
        return const EmptyView(message: 'No slots for this date', icon: Icons.event_busy_rounded);
      case ViewState.success:
        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
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
