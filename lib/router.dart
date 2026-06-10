import 'package:go_router/go_router.dart';

import 'models/venue.dart';
import 'providers/session_provider.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/venue_detail_screen.dart';
import 'screens/venues_screen.dart';

/// Central go_router config.
///
/// Auth flow guard:
///  - not logged in  -> only /login is reachable (OTP is a sheet over login)
///  - logged in & no name yet (new user) -> forced to /complete-profile
///  - logged in & has name -> /venues (kept out of the auth/profile screens)
GoRouter createRouter(SessionProvider session) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggedIn = session.isLoggedIn;

      // The splash screen routes itself once its animation finishes; never
      // redirect away from it.
      if (loc == '/splash') return null;

      if (!loggedIn) {
        return loc == '/login' ? null : '/login';
      }

      // Logged in:
      final needsName = session.currentUser!.needsName;
      if (needsName) return loc == '/complete-profile' ? null : '/complete-profile';
      if (loc == '/login' || loc == '/complete-profile') return '/venues';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(path: '/venues', builder: (context, state) => const VenuesScreen()),
      GoRoute(
        path: '/venues/detail',
        builder: (context, state) => VenueDetailScreen(venue: state.extra as Venue),
      ),
      GoRoute(path: '/bookings', builder: (context, state) => const MyBookingsScreen()),
    ],
  );
}
