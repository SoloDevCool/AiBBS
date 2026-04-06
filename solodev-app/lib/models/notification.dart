import 'user.dart';

class NotificationItem {
  final int id;
  final String notifyType;
  final bool read;
  final UserBrief actor;
  final Notifiable? notifiable;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.notifyType,
    required this.read,
    required this.actor,
    this.notifiable,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      notifyType: json['notify_type'] as String,
      read: json['read'] as bool? ?? false,
      actor: UserBrief.fromJson(json['actor'] as Map<String, dynamic>),
      notifiable: json['notifiable'] != null
          ? Notifiable.fromJson(json['notifiable'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get displayText {
    final actorName = actor.username;
    switch (notifyType) {
      case 'new_comment':
        return '$actorName 评论了你的主题';
      case 'new_reply':
        return '$actorName 回复了你的评论';
      case 'mention':
        return '$actorName 在评论中提到了你';
      case 'new_follower':
        return '$actorName 关注了你';
      case 'topic_cool':
        return '$actorName 觉得你的主题很 Cool';
      case 'comment_cool':
        return '$actorName 觉得你的评论很 Cool';
      case 'tip':
        final amount = notifiable?.amount ?? 0;
        return '$actorName 打赏了你 $amount 酷能量';
      case 'topic_vote':
        return '$actorName 参与了你的投票';
      default:
        return '收到新通知';
    }
  }
}

class Notifiable {
  final String type;
  final int id;
  final String? content;
  final TopicRef? topic;
  final int? amount;

  Notifiable({
    required this.type,
    required this.id,
    this.content,
    this.topic,
    this.amount,
  });

  factory Notifiable.fromJson(Map<String, dynamic> json) {
    return Notifiable(
      type: json['type'] as String,
      id: json['id'] as int,
      content: json['content'] as String?,
      topic: json['topic'] != null
          ? TopicRef.fromJson(json['topic'] as Map<String, dynamic>)
          : null,
      amount: json['amount'] as int?,
    );
  }
}

class TopicRef {
  final int id;
  final String title;
  final String slug;

  TopicRef({required this.id, required this.title, required this.slug});

  factory TopicRef.fromJson(Map<String, dynamic> json) {
    return TopicRef(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String? ?? '',
    );
  }
}

class ChatGroup {
  final int id;
  final String name;
  final String? description;
  final int membersCount;

  ChatGroup({
    required this.id,
    required this.name,
    this.description,
    required this.membersCount,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      membersCount: json['members_count'] as int? ?? 0,
    );
  }
}

class FriendLink {
  final int id;
  final String name;
  final String url;
  final String? description;
  final String? logo;
  final int sortOrder;

  FriendLink({
    required this.id,
    required this.name,
    required this.url,
    this.description,
    this.logo,
    required this.sortOrder,
  });

  factory FriendLink.fromJson(Map<String, dynamic> json) {
    return FriendLink(
      id: json['id'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      logo: json['logo'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class SiteInfo {
  final String siteName;
  final String siteTitle;
  final String siteDescription;
  final String? logoUrl;
  final String? faviconUrl;
  final SiteStats stats;
  final SiteFeatures features;

  SiteInfo({
    required this.siteName,
    required this.siteTitle,
    required this.siteDescription,
    this.logoUrl,
    this.faviconUrl,
    required this.stats,
    required this.features,
  });

  factory SiteInfo.fromJson(Map<String, dynamic> json) {
    return SiteInfo(
      siteName: json['site_name'] as String? ?? 'SoloDev.Cool',
      siteTitle: json['site_title'] as String? ?? 'SoloDev.Cool',
      siteDescription: json['site_description'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      faviconUrl: json['favicon_url'] as String?,
      stats: SiteStats.fromJson(json['stats'] as Map<String, dynamic>),
      features: SiteFeatures.fromJson(json['features'] as Map<String, dynamic>),
    );
  }
}

class SiteStats {
  final int usersCount;
  final int topicsCount;
  final int commentsCount;

  SiteStats({
    required this.usersCount,
    required this.topicsCount,
    required this.commentsCount,
  });

  factory SiteStats.fromJson(Map<String, dynamic> json) {
    return SiteStats(
      usersCount: json['users_count'] as int? ?? 0,
      topicsCount: json['topics_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
    );
  }
}

class SiteFeatures {
  final bool registrationEnabled;
  final bool invitationCodeRequired;
  final bool friendLinksEnabled;
  final bool chatGroupsEnabled;

  SiteFeatures({
    required this.registrationEnabled,
    required this.invitationCodeRequired,
    required this.friendLinksEnabled,
    required this.chatGroupsEnabled,
  });

  factory SiteFeatures.fromJson(Map<String, dynamic> json) {
    return SiteFeatures(
      registrationEnabled: json['registration_enabled'] as bool? ?? true,
      invitationCodeRequired:
          json['invitation_code_required'] as bool? ?? false,
      friendLinksEnabled: json['friend_links_enabled'] as bool? ?? false,
      chatGroupsEnabled: json['chat_groups_enabled'] as bool? ?? false,
    );
  }
}

class CheckInResult {
  final int pointsEarned;
  final int totalPoints;
  final bool todayCheckedIn;

  CheckInResult({
    required this.pointsEarned,
    required this.totalPoints,
    required this.todayCheckedIn,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      pointsEarned: json['points_earned'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      todayCheckedIn: json['today_checked_in'] as bool? ?? false,
    );
  }
}

class PaginationInfo {
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory PaginationInfo.fromHeaders(Map<String, String> headers) {
    return PaginationInfo(
      page: int.tryParse(headers['x-page'] ?? '1') ?? 1,
      perPage: int.tryParse(headers['x-per-page'] ?? '20') ?? 20,
      total: int.tryParse(headers['x-total'] ?? '0') ?? 0,
      totalPages: int.tryParse(headers['x-total-pages'] ?? '0') ?? 0,
    );
  }
}

class TipResult {
  final int id;
  final int amount;
  final UserBrief fromUser;
  final UserBrief toUser;
  final int myPoints;

  TipResult({
    required this.id,
    required this.amount,
    required this.fromUser,
    required this.toUser,
    required this.myPoints,
  });

  factory TipResult.fromJson(Map<String, dynamic> json) {
    return TipResult(
      id: json['id'] as int,
      amount: json['amount'] as int,
      fromUser: UserBrief.fromJson(json['from_user'] as Map<String, dynamic>),
      toUser: UserBrief.fromJson(json['to_user'] as Map<String, dynamic>),
      myPoints: json['my_points'] as int? ?? 0,
    );
  }
}
