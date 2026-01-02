class AppUser {
  final int id;
  final String username;
  final String? avatarUrl;
  final String? auth_provider;
  final bool isGuest;

  AppUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.auth_provider,
    required this.isGuest
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      username: json['username'] ?? 'Guest',
      avatarUrl: json['avatar_url'],
      isGuest: json['is_guest'] == 1 || json['is_guest'] == true,
      auth_provider: json['auth_provider'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'is_guest': isGuest,
      'auth_provider': auth_provider,
    };
  }
}