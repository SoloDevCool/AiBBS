class UserBrief {
  final int id;
  final String username;
  final String? avatarUrl;

  UserBrief({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory UserBrief.fromJson(Map<String, dynamic> json) {
    return UserBrief(
      id: json['id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class User {
  final int id;
  final String email;
  final String username;
  final String? avatarUrl;
  final int points;
  final String role;
  final bool profilePublic;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.points,
    required this.role,
    this.profilePublic = true,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: json['points'] as int? ?? 0,
      role: json['role'] as String? ?? 'user',
      profilePublic: json['profile_public'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'points': points,
      'role': role,
    };
  }
}

class UserPublicProfile {
  final int id;
  final String username;
  final String? avatarUrl;
  final int points;
  final int topicsCount;
  final int commentsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowed;
  final bool isBlocked;
  final DateTime createdAt;

  UserPublicProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.points,
    required this.topicsCount,
    required this.commentsCount,
    required this.followersCount,
    required this.followingCount,
    this.isFollowed = false,
    this.isBlocked = false,
    required this.createdAt,
  });

  factory UserPublicProfile.fromJson(Map<String, dynamic> json) {
    return UserPublicProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: json['points'] as int? ?? 0,
      topicsCount: json['topics_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      isFollowed: json['is_followed'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class UserProfile {
  final User user;
  final UserStats stats;

  UserProfile({required this.user, required this.stats});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }
}

class UserStats {
  final int topicsCount;
  final int commentsCount;
  final int followersCount;
  final int followingCount;
  final int blocksCount;

  UserStats({
    required this.topicsCount,
    required this.commentsCount,
    required this.followersCount,
    required this.followingCount,
    required this.blocksCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      topicsCount: json['topics_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      blocksCount: json['blocks_count'] as int? ?? 0,
    );
  }
}
