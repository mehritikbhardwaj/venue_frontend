import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/failure.dart';
import '../data/user_repository.dart';
import '../models/user.dart';
import 'view_state.dart';

/// Holds the logged-in user and the list of selectable users. Setting the
/// current user also wires the id into [ApiClient] so every later request
/// carries the X-User-Id header.
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._api, this._users);

  final ApiClient _api;
  final UserRepository _users;

  ViewState state = ViewState.idle;
  String? errorMessage;
  List<AppUser> users = [];
  AppUser? currentUser;

  bool get isLoggedIn => currentUser != null;

  Future<void> loadUsers() async {
    state = ViewState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      users = await _users.fetchUsers();
      state = users.isEmpty ? ViewState.empty : ViewState.success;
    } on Failure catch (f) {
      state = ViewState.error;
      errorMessage = f.message;
    }
    notifyListeners();
  }

  void login(AppUser user) {
    currentUser = user;
    _api.userId = user.id;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    _api.userId = null;
    notifyListeners();
  }
}
