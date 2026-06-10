import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/venue.dart';
import '../providers/session_provider.dart';
import '../providers/venues_provider.dart';
import '../providers/view_state.dart';
import '../widgets/state_views.dart';

/// Home: list of venues. Tapping one opens its slot grid.
class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VenuesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VenuesProvider>();
    final session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venues'),
        actions: [
          IconButton(
            tooltip: 'My Bookings',
            icon: const Icon(Icons.event_note_rounded),
            onPressed: () => context.push('/bookings'),
          ),
          PopupMenuButton<String>(
            tooltip: session.currentUser?.name ?? 'Account',
            icon: const Icon(Icons.account_circle_rounded),
            onSelected: (v) {
              if (v == 'logout') {
                session.logout();
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text('Signed in as ${session.currentUser?.name ?? '-'}'),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Switch user')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(),
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(VenuesProvider provider) {
    switch (provider.state) {
      case ViewState.loading:
      case ViewState.idle:
        return const LoadingView(label: 'Loading venues…');
      case ViewState.error:
        return ErrorView(message: provider.errorMessage ?? 'Failed to load venues', onRetry: provider.load);
      case ViewState.empty:
        return const EmptyView(message: 'No venues yet', icon: Icons.stadium_rounded);
      case ViewState.success:
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.venues.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _VenueCard(venue: provider.venues[i]),
        );
    }
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({required this.venue});
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBadminton = venue.sport.toLowerCase().contains('badminton');
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            isBadminton ? Icons.sports_tennis_rounded : Icons.sports_soccer_rounded,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Text(venue.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${venue.sport} · ${venue.location}'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/venues/detail', extra: venue),
      ),
    );
  }
}
