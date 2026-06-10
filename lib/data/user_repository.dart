import '../core/api_client.dart';
import '../models/user.dart';

/// Fetches the list of selectable users for the login screen.
class UserRepository {
  UserRepository(this._api);
  final ApiClient _api;

  Future<List<AppUser>> fetchUsers() async {
    final data = await _api.get('/users') as List<dynamic>;
    return data.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }
}
