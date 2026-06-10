/// Backend base URL. Defaults to the deployed Vercel API so the app works on a
/// physical device out of the box. Override for local dev:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000  (iOS simulator)
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://venuebackend.vercel.app',
  );

  /// How often the slot grid refreshes for live "booked" updates (bonus).
  static const Duration slotPollInterval = Duration(seconds: 4);
}
