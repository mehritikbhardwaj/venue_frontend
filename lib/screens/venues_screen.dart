import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/venue.dart';
import '../providers/session_provider.dart';
import '../providers/venues_provider.dart';
import '../providers/view_state.dart';
import '../widgets/brand.dart';
import '../widgets/state_views.dart';

/// Home: list of venues. Tapping one opens its slot grid.
class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VenuesProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Local, case-insensitive filter over the already-loaded venues. Matches
  /// against name, sport and location so "turf", "badminton" or an area all work.
  List<Venue> _filter(List<Venue> venues) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return venues;
    return venues
        .where((v) =>
            v.name.toLowerCase().contains(q) ||
            v.sport.toLowerCase().contains(q) ||
            v.location.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VenuesProvider>();
    final session = context.watch<SessionProvider>();
    final firstName = (session.currentUser?.name ?? '').split(' ').first;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName.isEmpty ? 'Hi there 👋' : 'Hi, $firstName 👋',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Find your court',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeaderButton(
                      icon: Icons.event_note_rounded,
                      tooltip: 'My Bookings',
                      onTap: () => context.push('/bookings'),
                    ),
                    const SizedBox(width: 10),
                    _AccountButton(session: session),
                  ],
                ),
                const SizedBox(height: 18),
                // Live local search over the loaded venues.
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.tileShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 15, color: AppTheme.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search venues & sports',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.inkMuted),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppTheme.inkMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                                FocusScope.of(context).unfocus();
                              },
                            ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.brand,
              onRefresh: () => provider.load(),
              child: _buildBody(provider),
            ),
          ),
        ],
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
        final venues = _filter(provider.venues);
        if (venues.isEmpty) {
          return EmptyView(
            message: 'No venues match "${_query.trim()}".\nTry a different name, sport or area.',
            icon: Icons.search_off_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          itemCount: venues.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, i) => _VenueCard(venue: venues[i]),
        );
    }
  }
}

/// Circular translucent button used on the gradient header.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.session});
  final SessionProvider session;

  Future<void> _confirmLogout(BuildContext context, SessionProvider session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: Text("You'll need to verify your mobile number again to sign back in."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger, minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    session.logout();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: session.currentUser?.name ?? 'Account',
      offset: const Offset(0, 48),
      onSelected: (v) {
        if (v == 'logout') _confirmLogout(context, session);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text('Signed in as ${session.currentUser?.name ?? '-'}'),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppTheme.danger),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({required this.venue});
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => context.push('/venues/detail', extra: venue),
      child: Row(
        children: [
          SportAvatar(sport: venue.sport),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusBadge(label: venue.sport, color: AppTheme.brand),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(Icons.place_rounded, size: 14, color: AppTheme.inkMuted),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              venue.location,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.inkMuted, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.brand.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.brandDark),
          ),
        ],
      ),
    );
  }
}
