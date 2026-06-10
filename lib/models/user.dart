/// An app user, identified by mobile. `isNewUser` is true until a name is set.
class AppUser {
  final int id;
  final String name;
  final String? mobile;
  final bool isNewUser;

  const AppUser({
    required this.id,
    required this.name,
    this.mobile,
    this.isNewUser = false,
  });

  bool get needsName => name.trim().isEmpty;

  AppUser copyWith({String? name}) =>
      AppUser(id: id, name: name ?? this.name, mobile: mobile, isNewUser: isNewUser);

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        name: (json['name'] as String?) ?? '',
        mobile: json['mobile'] as String?,
        isNewUser: (json['is_new_user'] as bool?) ?? false,
      );
}

/// Result of POST /auth/request-otp. The OTP is returned in the response
/// (demo — no SMS) and shown on the OTP screen.
class OtpRequest {
  final int userId;
  final String mobile;
  final String otp;
  final bool isNewUser;

  const OtpRequest({
    required this.userId,
    required this.mobile,
    required this.otp,
    required this.isNewUser,
  });

  factory OtpRequest.fromJson(Map<String, dynamic> json) => OtpRequest(
        userId: json['user_id'] as int,
        mobile: json['mobile'] as String,
        otp: json['otp'] as String,
        isNewUser: (json['is_new_user'] as bool?) ?? false,
      );
}
