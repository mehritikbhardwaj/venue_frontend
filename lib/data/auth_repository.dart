import '../core/api_client.dart';
import '../models/user.dart';

/// Mobile + OTP auth and profile update. Maps JSON -> models; lets typed
/// [Failure]s from [ApiClient] propagate to the SessionProvider.
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  /// Requests an OTP for [mobile]. Backend find-or-creates the user and returns
  /// the OTP in the response (demo).
  Future<OtpRequest> requestOtp(String mobile) async {
    final data = await _api.post('/auth/request-otp', body: {'mobile': mobile})
        as Map<String, dynamic>;
    return OtpRequest.fromJson(data);
  }

  /// Verifies the OTP and returns the authenticated user.
  Future<AppUser> verifyOtp(String mobile, String otp) async {
    final data = await _api.post('/auth/verify-otp', body: {'mobile': mobile, 'otp': otp})
        as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  /// Sets the display name for a (typically new) user.
  Future<AppUser> updateName(int userId, String name) async {
    final data = await _api.patch('/users/$userId', body: {'name': name})
        as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }
}
