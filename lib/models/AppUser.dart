class AppUser {
  final int id;
  final String username;
  final String? avatarUrl;
  final bool isGuest;

  AppUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.isGuest
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      username: json['username'] ?? 'Guest',
      avatarUrl: json['avatar_url'],
      isGuest: json['is_guest'] == 1 || json['is_guest'] == true,
    );
  }
}