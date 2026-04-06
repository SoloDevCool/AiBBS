import 'node.dart';
import 'user.dart';

class TopicListItem {
  final int id;
  final String title;
  final String slug;
  final String excerpt;
  final NodeBrief node;
  final UserBrief author;
  final int commentsCount;
  final int coolsCount;
  final int viewsCount;
  final bool pinned;
  final bool isCooled;
  final bool hasPoll;
  final DateTime createdAt;

  TopicListItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.node,
    required this.author,
    required this.commentsCount,
    required this.coolsCount,
    required this.viewsCount,
    this.pinned = false,
    this.isCooled = false,
    this.hasPoll = false,
    required this.createdAt,
  });

  factory TopicListItem.fromJson(Map<String, dynamic> json) {
    return TopicListItem(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      node: NodeBrief.fromJson(json['node'] as Map<String, dynamic>),
      author: UserBrief.fromJson(json['author'] as Map<String, dynamic>),
      commentsCount: json['comments_count'] as int? ?? 0,
      coolsCount: json['cools_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      pinned: json['pinned'] as bool? ?? false,
      isCooled: json['is_cooled'] as bool? ?? false,
      hasPoll: json['has_poll'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CommentTree {
  final int id;
  final String content;
  final UserBrief author;
  final int coolsCount;
  final bool isCooled;
  final bool isAuthor;
  final bool loginOnly;
  final int tipsTotal;
  final DateTime createdAt;
  final List<CommentTree> replies;

  CommentTree({
    required this.id,
    required this.content,
    required this.author,
    required this.coolsCount,
    this.isCooled = false,
    this.isAuthor = false,
    this.loginOnly = false,
    this.tipsTotal = 0,
    required this.createdAt,
    this.replies = const [],
  });

  factory CommentTree.fromJson(Map<String, dynamic> json) {
    return CommentTree(
      id: json['id'] as int,
      content: json['content'] as String,
      author: UserBrief.fromJson(json['author'] as Map<String, dynamic>),
      coolsCount: json['cools_count'] as int? ?? 0,
      isCooled: json['is_cooled'] as bool? ?? false,
      isAuthor: json['is_author'] as bool? ?? false,
      loginOnly: json['login_only'] as bool? ?? false,
      tipsTotal: json['tips_total'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      replies: (json['replies'] as List?)
              ?.map((e) => CommentTree.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PollOption {
  final int id;
  final String title;
  final int votesCount;
  final double percentage;
  final bool voted;

  PollOption({
    required this.id,
    required this.title,
    required this.votesCount,
    required this.percentage,
    this.voted = false,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as int,
      title: json['title'] as String,
      votesCount: json['votes_count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      voted: json['voted'] as bool? ?? false,
    );
  }
}

class Poll {
  final int id;
  final bool closed;
  final List<PollOption> options;

  Poll({required this.id, required this.closed, required this.options});

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as int,
      closed: json['closed'] as bool? ?? false,
      options: (json['options'] as List?)
              ?.map((e) => PollOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TopicDetail {
  final int id;
  final String title;
  final String slug;
  final String content;
  final NodeBrief node;
  final UserBrief author;
  final int commentsCount;
  final int coolsCount;
  final int viewsCount;
  final bool pinned;
  final bool isRepost;
  final String? sourceUrl;
  final bool isCooled;
  final bool isAuthor;
  final bool hasPoll;
  final Poll? poll;
  final List<CommentTree> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  TopicDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.node,
    required this.author,
    required this.commentsCount,
    required this.coolsCount,
    required this.viewsCount,
    this.pinned = false,
    this.isRepost = false,
    this.sourceUrl,
    this.isCooled = false,
    this.isAuthor = false,
    this.hasPoll = false,
    this.poll,
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory TopicDetail.fromJson(Map<String, dynamic> json) {
    return TopicDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String? ?? '',
      content: json['content'] as String,
      node: NodeBrief.fromJson(json['node'] as Map<String, dynamic>),
      author: UserBrief.fromJson(json['author'] as Map<String, dynamic>),
      commentsCount: json['comments_count'] as int? ?? 0,
      coolsCount: json['cools_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      pinned: json['pinned'] as bool? ?? false,
      isRepost: json['is_repost'] as bool? ?? false,
      sourceUrl: json['source_url'] as String?,
      isCooled: json['is_cooled'] as bool? ?? false,
      isAuthor: json['is_author'] as bool? ?? false,
      hasPoll: json['has_poll'] as bool? ?? false,
      poll: json['poll'] != null
          ? Poll.fromJson(json['poll'] as Map<String, dynamic>)
          : null,
      comments: (json['comments'] as List?)
              ?.map((e) => CommentTree.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
