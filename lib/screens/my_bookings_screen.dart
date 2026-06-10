import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/booking.dart';
import '../providers/bookings_provider.dart';
import '../providers/session_provider.dart';
import '../providers/view_state.dart';
import '../widgets/brand.dart';
import '../widgets/state_views.dart';

/// "My Bookings": the current user's bookings with cancel.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _load() {
    final userId = context.read<SessionProvider>().currentUser?.id;
    if (userId != null) context.read<BookingsProvider>().load(userId);
  }

  Future<void> _cancel(Booking booking) async {
    final userId = context.read<SessionProvider>().currentUser!.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CancelBookingDialog(booking: booking),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<BookingsProvider>().cancel(
      booking.id,
      userId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Booking cancelled' : 'Could not cancel. Try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingsProvider>();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'My Bookings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(BookingsProvider provider) {
    switch (provider.state) {
      case ViewState.loading:
      case ViewState.idle:
        return const LoadingView(label: 'Loading your bookings…');
      case ViewState.error:
        return ErrorView(
          message: provider.errorMessage ?? 'Failed to load bookings',
          onRetry: _load,
        );
      case ViewState.empty:
        return _withRefresh(
          const EmptyView(
            message:
                'No bookings yet.\nBook a slot from a venue to see it here.',
            icon: Icons.event_available_rounded,
          ),
        );
      case ViewState.success:
        final upcoming = provider.bookings.where((b) => b.isUpcoming).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        final past = provider.bookings.where((b) => !b.isUpcoming).toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
        return TabBarView(
          controller: _tabs,
          children: [
            _list(
              provider,
              upcoming,
              emptyMessage:
                  'No upcoming bookings.\nBook a slot to see it here.',
              emptyIcon: Icons.event_available_rounded,
            ),
            _list(
              provider,
              past,
              emptyMessage: 'No past bookings yet.',
              emptyIcon: Icons.history_rounded,
            ),
          ],
        );
    }
  }

  Widget _list(
    BookingsProvider provider,
    List<Booking> items, {
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (items.isEmpty) {
      return _withRefresh(EmptyView(message: emptyMessage, icon: emptyIcon));
    }
    return _withRefresh(
      ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _BookingCard(
          booking: items[i],
          cancelling: provider.cancellingId == items[i].id,
          onCancel: () => _cancel(items[i]),
        ),
      ),
    );
  }

  Widget _withRefresh(Widget child) => RefreshIndicator(
    color: AppTheme.brand,
    onRefresh: () async => _load(),
    child: child,
  );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.cancelling,
    required this.onCancel,
  });
  final Booking booking;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final active = booking.isActive;
    final dateStr = DateFormat(
      'EEE, d MMM yyyy',
    ).format(DateTime.parse(booking.date));
    final title = booking.venueName.isEmpty
        ? 'Venue #${booking.venueId}'
        : booking.venueName;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SportAvatar(sport: booking.sport, active: active),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: active ? AppTheme.ink : AppTheme.inkMuted,
                        decoration: active ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.sport,
                      style: const TextStyle(
                        color: AppTheme.inkMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              active
                  ? const StatusBadge(
                      label: 'Confirmed',
                      color: AppTheme.brand,
                      icon: Icons.check_circle_rounded,
                    )
                  : const StatusBadge(
                      label: 'Cancelled',
                      color: AppTheme.danger,
                      icon: Icons.cancel_rounded,
                    ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _meta(Icons.event_rounded, dateStr),
              _meta(Icons.schedule_rounded, booking.timeLabel),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: cancelling ? null : onCancel,
                icon: cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppTheme.danger,
                        ),
                      )
                    : const Icon(Icons.close_rounded, size: 18),
                label: Text(cancelling ? 'Cancelling…' : 'Cancel booking'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger, width: 1.5),
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.inkMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Modern, destructive-styled confirmation for cancelling a booking: a red
/// badge header, a grouped details card, and Keep / Cancel actions.
class _CancelBookingDialog extends StatelessWidget {
  const _CancelBookingDialog({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final title = booking.venueName.isEmpty
        ? 'Venue #${booking.venueId}'
        : booking.venueName;
    final dateStr = DateFormat(
      'EEE, d MMM yyyy',
    ).format(DateTime.parse(booking.date));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: AppTheme.danger,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cancel this booking?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'This frees up the slot for others and can’t be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.inkMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.canvas,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _CancelDetailRow(
                    icon: Icons.stadium_rounded,
                    label: 'Venue',
                    value: title,
                  ),
                  const Divider(height: 1),
                  _CancelDetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: booking.timeLabel,
                  ),
                  const Divider(height: 1),
                  _CancelDetailRow(
                    icon: Icons.event_rounded,
                    label: 'Date',
                    value: dateStr,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Cancel booking',
                      style: TextStyle(fontSize: 12),
                    ),
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

/// A label/value row inside the cancel dialog's details card.
class _CancelDetailRow extends StatelessWidget {
  const _CancelDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
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
              color: AppTheme.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: AppTheme.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
