import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'data/auth_repository.dart';
import 'data/booking_repository.dart';
import 'data/venue_repository.dart';
import 'providers/bookings_provider.dart';
import 'providers/session_provider.dart';
import 'providers/venues_provider.dart';
import 'router.dart';

void main() {
  // Composition root: build the single ApiClient and repositories once, then
  // inject providers above the widget tree. Screens never construct these.
  final api = ApiClient();
  final authRepo = AuthRepository(api);
  final venueRepo = VenueRepository(api);
  final bookingRepo = BookingRepository(api);

  runApp(QuickSlotApp(
    api: api,
    authRepo: authRepo,
    venueRepo: venueRepo,
    bookingRepo: bookingRepo,
  ));
}

class QuickSlotApp extends StatefulWidget {
  const QuickSlotApp({
    super.key,
    required this.api,
    required this.authRepo,
    required this.venueRepo,
    required this.bookingRepo,
  });

  final ApiClient api;
  final AuthRepository authRepo;
  final VenueRepository venueRepo;
  final BookingRepository bookingRepo;

  @override
  State<QuickSlotApp> createState() => _QuickSlotAppState();
}

class _QuickSlotAppState extends State<QuickSlotApp> {
  late final SessionProvider _session = SessionProvider(widget.api, widget.authRepo);
  late final GoRouter _router = createRouter(_session);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _session),
        ChangeNotifierProvider(create: (_) => VenuesProvider(widget.venueRepo)),
        ChangeNotifierProvider(create: (_) => BookingsProvider(widget.bookingRepo)),
        // SlotsProvider is scoped to a single venue, so it's created inside the
        // venue-detail screen rather than here.
        Provider.value(value: widget.venueRepo),
        Provider.value(value: widget.bookingRepo),
      ],
      child: MaterialApp.router(
        title: 'QuickSlot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
