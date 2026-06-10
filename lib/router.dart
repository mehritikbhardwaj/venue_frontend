import 'package:go_router/go_router.dart';

import 'models/venue.dart';
import 'providers/session_provider.dart';
import 'screens/login_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/venue_detail_screen.dart';
import 'screens/venues_screen.dart';

/// Central go_router config. Redirects to /login until a user is selected,
/// so authenticated screens always have a current user for X-User-Id.
GoRouter createRouter(SessionProvider session) {
  return GoRouter(
    initialLocation: '/venues',
    refreshListenable: session, // re-evaluate redirect when login state changes
    redirect: (context, state) {
      final loggedIn = session.isLoggedIn;
      final goingToLogin = state.matchedLocation == '/login';
      if (!loggedIn) return goingToLogin ? null : '/login';
      if (loggedIn && goingToLogin) return '/venues';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/venues', builder: (context, state) => const VenuesScreen()),
      GoRoute(
        path: '/venues/detail',
        builder: (context, state) => VenueDetailScreen(venue: state.extra as Venue),
      ),
      GoRoute(path: '/bookings', builder: (context, state) => const MyBookingsScreen()),
    ],
  );
}
