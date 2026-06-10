/// A selectable (hardcoded/seeded) user.
class AppUser {
  final int id;
  final String name;

  const AppUser({required this.id, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      AppUser(id: json['id'] as int, name: json['name'] as String);
}
