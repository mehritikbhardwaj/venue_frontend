import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../providers/bookings_provider.dart';
import '../providers/session_provider.dart';
import '../providers/view_state.dart';
import '../widgets/state_views.dart';

/// "My Bookings": the current user's bookings with cancel.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = context.read<SessionProvider>().currentUser?.id;
    if (userId != null) context.read<BookingsProvider>().load(userId);
  }

  Future<void> _cancel(Booking booking) async {
    final userId = context.read<SessionProvider>().currentUser!.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text('${booking.venueName} · ${booking.timeLabel}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel booking')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<BookingsProvider>().cancel(booking.id, userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Booking cancelled' : 'Could not cancel. Try again.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(BookingsProvider provider) {
    switch (provider.state) {
      case ViewState.loading:
      case ViewState.idle:
        return const LoadingView(label: 'Loading your bookings…');
      case ViewState.error:
        return ErrorView(message: provider.errorMessage ?? 'Failed to load bookings', onRetry: _load);
      case ViewState.empty:
        return const EmptyView(
          message: 'No bookings yet.\nBook a slot from a venue to see it here.',
          icon: Icons.event_available_rounded,
        );
      case ViewState.success:
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.bookings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _BookingCard(
            booking: provider.bookings[i],
            cancelling: provider.cancellingId == provider.bookings[i].id,
            onCancel: () => _cancel(provider.bookings[i]),
          ),
        );
    }
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.cancelling, required this.onCancel});
  final Booking booking;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = booking.isActive;
    final dateStr = DateFormat('EEE, d MMM yyyy').format(DateTime.parse(booking.date));

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: active ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          child: Icon(Icons.event_rounded,
              color: active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
        ),
        title: Text(booking.venueName.isEmpty ? 'Venue #${booking.venueId}' : booking.venueName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$dateStr · ${booking.timeLabel}'
              '${active ? '' : '  ·  Cancelled'}'),
        ),
        trailing: active
            ? (cancelling
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(onPressed: onCancel, child: const Text('Cancel')))
            : Text('Cancelled', style: TextStyle(color: scheme.error)),
      ),
    );
  }
}
