import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/failure.dart';
import '../core/session_store.dart';
import '../data/auth_repository.dart';
import '../models/user.dart';
import 'view_state.dart';

/// Owns the mobile + OTP login flow and the current user. Setting the current
/// user also wires the id into [ApiClient] so later requests carry X-User-Id.
///
/// The session is persisted via [SessionStore] so the user stays logged in
/// across app launches; [ensureRestored] reloads it on startup.
///
/// Flow: requestOtp(mobile) -> verifyOtp(otp) -> [if new] updateName(name).
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._api, this._auth, [SessionStore? store])
      : _store = store ?? SessionStore();

  final ApiClient _api;
  final AuthRepository _auth;
  final SessionStore _store;

  /// Memoised so concurrent callers (splash + router) share one restore pass.
  Future<void>? _restoreFuture;

  /// Loads any persisted session into memory exactly once. Safe to call from
  /// multiple places on startup.
  Future<void> ensureRestored() => _restoreFuture ??= _restore();

  Future<void> _restore() async {
    final saved = await _store.read();
    if (saved == null) return;
    currentUser = AppUser(id: saved.id, name: saved.name, mobile: saved.mobile);
    _api.userId = saved.id;
    notifyListeners();
  }

  AppUser? currentUser;
  bool get isLoggedIn => currentUser != null;

  // Per-step state so each screen can show loading/error independently.
  ViewState requestState = ViewState.idle;
  ViewState verifyState = ViewState.idle;
  ViewState profileState = ViewState.idle;
  String? errorMessage;

  // Carried between the login screen and the OTP screen.
  String? pendingMobile;
  String? generatedOtp; // shown on the OTP screen (demo, no SMS)
  bool pendingIsNew = false;

  Future<bool> requestOtp(String mobile) async {
    requestState = ViewState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _auth.requestOtp(mobile);
      pendingMobile = res.mobile;
      generatedOtp = res.otp;
      pendingIsNew = res.isNewUser;
      requestState = ViewState.success;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      requestState = ViewState.error;
      errorMessage = f.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (pendingMobile == null) return false;
    verifyState = ViewState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _auth.verifyOtp(pendingMobile!, otp);
      currentUser = user;
      _api.userId = user.id;
      await _store.save(id: user.id, name: user.name, mobile: user.mobile);
      verifyState = ViewState.success;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      verifyState = ViewState.error;
      errorMessage = f.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateName(String name) async {
    if (currentUser == null) return false;
    profileState = ViewState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _auth.updateName(currentUser!.id, name);
      // Preserve mobile; the PATCH response carries id/name/mobile.
      currentUser = AppUser(id: user.id, name: user.name, mobile: user.mobile);
      await _store.save(id: user.id, name: user.name, mobile: user.mobile);
      profileState = ViewState.success;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      profileState = ViewState.error;
      errorMessage = f.message;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    currentUser = null;
    _api.userId = null;
    pendingMobile = null;
    generatedOtp = null;
    pendingIsNew = false;
    requestState = ViewState.idle;
    verifyState = ViewState.idle;
    profileState = ViewState.idle;
    _store.clear(); // fire-and-forget; in-memory state is already cleared
    notifyListeners();
  }
}
