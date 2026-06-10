import 'package:shared_preferences/shared_preferences.dart';

/// Persists just enough of the logged-in user to restore the session on the
/// next launch (id + name + mobile). Stores primitives only — no model import —
/// so it stays an infrastructure concern. [SessionProvider] owns the mapping
/// to/from [AppUser].
class SessionStore {
  static const _kId = 'session_user_id';
  static const _kName = 'session_user_name';
  static const _kMobile = 'session_user_mobile';

  Future<void> save({required int id, required String name, String? mobile}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kId, id);
    await prefs.setString(_kName, name);
    if (mobile != null) {
      await prefs.setString(_kMobile, mobile);
    } else {
      await prefs.remove(_kMobile);
    }
  }

  /// Returns the saved user, or null if no session was persisted.
  Future<({int id, String name, String? mobile})?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kId);
    if (id == null) return null;
    return (
      id: id,
      name: prefs.getString(_kName) ?? '',
      mobile: prefs.getString(_kMobile),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kName);
    await prefs.remove(_kMobile);
  }
}
