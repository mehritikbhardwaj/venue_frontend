import 'package:go_router/go_router.dart';

import 'models/venue.dart';
import 'providers/session_provider.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/venue_detail_screen.dart';
import 'screens/venues_screen.dart';

/// Central go_router config.
///
/// Auth flow guard:
///  - not logged in  -> only /login and /otp are reachable
///  - logged in & no name yet (new user) -> forced to /complete-profile
///  - logged in & has name -> /venues (kept out of the auth/profile screens)
GoRouter createRouter(SessionProvider session) {
  return GoRouter(
    initialLocation: '/venues',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggedIn = session.isLoggedIn;
      final inAuthFlow = loc == '/login' || loc == '/otp';

      if (!loggedIn) {
        // Allow the OTP screen only if a request is in progress.
        if (loc == '/otp' && session.pendingMobile == null) return '/login';
        return inAuthFlow ? null : '/login';
      }

      // Logged in:
      final needsName = session.currentUser!.needsName;
      if (needsName) return loc == '/complete-profile' ? null : '/complete-profile';
      if (inAuthFlow || loc == '/complete-profile') return '/venues';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
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
