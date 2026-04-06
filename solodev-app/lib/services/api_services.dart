import '../models/topic.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../models/node.dart';
import '../models/api_response.dart';
import 'api_client.dart';

class TopicsService {
  final ApiClient _client = ApiClient();

  /// 话题列表
  Future<ApiResponse<List<TopicListItem>>> getTopics({
    String scope = 'recent',
    int? nodeId,
    String? kind,
    int page = 1,
    int perPage = 20,
  }) async {
    return _client.get<List<TopicListItem>>(
      '/topics',
      queryParameters: {
        'scope': scope,
        if (nodeId != null) 'node_id': nodeId,
        if (kind != null) 'kind': kind,
        'page': page,
        'per_page': perPage,
      },
      fromJson: (data) => (data as List)
          .map((e) => TopicListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      paginated: true,
    );
  }

  /// 话题详情
  Future<ApiResponse<TopicDetail>> getTopic(int id) async {
    return _client.get<TopicDetail>(
      '/topics/$id',
      fromJson: (data) => TopicDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 创建话题
  Future<ApiResponse> createTopic({
    required String title,
    required String content,
    required int nodeId,
    bool isRepost = false,
    String? sourceUrl,
  }) async {
    return _client.post('/topics', data: {
      'topic': {
        'title': title,
        'content': content,
        'node_id': nodeId,
        if (isRepost) 'is_repost': true,
        if (sourceUrl != null) 'source_url': sourceUrl,
      }
    });
  }

  /// 更新话题
  Future<ApiResponse> updateTopic({
    required int id,
    String? title,
    String? content,
    int? nodeId,
    bool? isRepost,
    String? sourceUrl,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (nodeId != null) data['node_id'] = nodeId;
    if (isRepost != null) data['is_repost'] = isRepost;
    if (sourceUrl != null) data['source_url'] = sourceUrl;

    return _client.put('/topics/$id', data: {'topic': data});
  }

  /// 删除话题
  Future<ApiResponse> deleteTopic(int id) async {
    return _client.delete('/topics/$id');
  }

  /// 搜索话题
  Future<ApiResponse<List<TopicListItem>>> searchTopics({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    return _client.get<List<TopicListItem>>(
      '/topics/search',
      queryParameters: {'q': query, 'page': page, 'per_page': perPage},
      fromJson: (data) => (data as List)
          .map((e) => TopicListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      paginated: true,
    );
  }
}

class CommentsService {
  final ApiClient _client = ApiClient();

  /// 评论列表（树形）
  Future<ApiResponse<List<CommentTree>>> getComments({
    required int topicId,
    int page = 1,
    int perPage = 20,
  }) async {
    return _client.get<List<CommentTree>>(
      '/topics/$topicId/comments',
      queryParameters: {'page': page, 'per_page': perPage},
      fromJson: (data) => (data as List)
          .map((e) => CommentTree.fromJson(e as Map<String, dynamic>))
          .toList(),
      paginated: true,
    );
  }

  /// 创建评论
  Future<ApiResponse<CommentTree>> createComment({
    required int topicId,
    required String content,
    int? parentId,
  }) async {
    return _client.post<CommentTree>(
      '/topics/$topicId/comments',
      data: {
        'comment': {
          'content': content,
          if (parentId != null) 'parent_id': parentId,
        }
      },
      fromJson: (data) => CommentTree.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 删除评论
  Future<ApiResponse> deleteComment({required int topicId, required int commentId}) async {
    return _client.delete('/topics/$topicId/comments/$commentId');
  }

  /// 切换仅登录可见
  Future<ApiResponse> toggleLoginOnly({required int topicId, required int commentId}) async {
    return _client.post('/topics/$topicId/comments/$commentId/toggle_login_only');
  }
}

class InteractionsService {
  final ApiClient _client = ApiClient();

  /// 话题点赞
  Future<ApiResponse> coolTopic(int topicId) async {
    return _client.post('/topics/$topicId/cool');
  }

  /// 取消话题点赞
  Future<ApiResponse> uncoolTopic(int topicId) async {
    return _client.delete('/topics/$topicId/cool');
  }

  /// 评论点赞
  Future<ApiResponse> coolComment(int commentId) async {
    return _client.post('/comments/$commentId/cool');
  }

  /// 取消评论点赞
  Future<ApiResponse> uncoolComment(int commentId) async {
    return _client.delete('/comments/$commentId/cool');
  }

  /// 打赏
  Future<ApiResponse<TipResult>> tip({
    required int topicId,
    required int commentId,
    required int amount,
  }) async {
    return _client.post<TipResult>(
      '/topics/$topicId/tips',
      data: {'comment_id': commentId, 'amount': amount},
      fromJson: (data) {
        final tip = data['tip'] as Map<String, dynamic>;
        return TipResult.fromJson({...tip, 'my_points': data['my_points']});
      },
    );
  }
}

class PollsService {
  final ApiClient _client = ApiClient();

  /// 创建投票
  Future<ApiResponse<Poll>> createPoll({
    required int topicId,
    required List<String> options,
    bool closed = false,
  }) async {
    return _client.post<Poll>(
      '/topics/$topicId/poll',
      data: {
        'poll': {
          'options': options,
          'closed': closed,
        }
      },
      fromJson: (data) => Poll.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 删除投票
  Future<ApiResponse> deletePoll(int topicId) async {
    return _client.delete('/topics/$topicId/poll');
  }

  /// 投票
  Future<ApiResponse<Poll>> vote({required int pollId, required int pollOptionId}) async {
    return _client.post<Poll>(
      '/polls/$pollId/vote',
      data: {'poll_option_id': pollOptionId},
      fromJson: (data) => Poll.fromJson(data['poll'] as Map<String, dynamic>),
    );
  }

  /// 关闭投票
  Future<ApiResponse> closePoll(int pollId) async {
    return _client.post('/polls/$pollId/close');
  }

  /// 开启投票
  Future<ApiResponse> openPoll(int pollId) async {
    return _client.post('/polls/$pollId/open');
  }
}

class UsersService {
  final ApiClient _client = ApiClient();

  /// 用户公开主页
  Future<ApiResponse<UserPublicProfile>> getUserProfile(int userId) async {
    return _client.get<UserPublicProfile>(
      '/users/$userId',
      fromJson: (data) => UserPublicProfile.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 搜索用户
  Future<ApiResponse<List<UserBrief>>> searchUsers(String query) async {
    return _client.get<List<UserBrief>>(
      '/users/search',
      queryParameters: {'q': query},
      fromJson: (data) => (data as List)
          .map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 关注用户
  Future<ApiResponse> followUser(int userId) async {
    return _client.post('/users/$userId/follow');
  }

  /// 取消关注
  Future<ApiResponse> unfollowUser(int userId) async {
    return _client.delete('/users/$userId/follow');
  }

  /// 屏蔽用户
  Future<ApiResponse> blockUser(int userId) async {
    return _client.post('/users/$userId/block');
  }

  /// 取消屏蔽
  Future<ApiResponse> unblockUser(int userId) async {
    return _client.delete('/users/$userId/block');
  }
}

class NodesService {
  final ApiClient _client = ApiClient();

  /// 节点列表
  Future<ApiResponse<List<NodeItem>>> getNodes({String? kind}) async {
    return _client.get<List<NodeItem>>(
      '/nodes',
      queryParameters: kind != null ? {'kind': kind} : null,
      fromJson: (data) => (data as List)
          .map((e) => NodeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 关注节点
  Future<ApiResponse> followNode(int nodeId) async {
    return _client.post('/nodes/$nodeId/follow');
  }

  /// 取消关注节点
  Future<ApiResponse> unfollowNode(int nodeId) async {
    return _client.delete('/nodes/$nodeId/follow');
  }
}

class ProfileService {
  final ApiClient _client = ApiClient();

  /// 获取个人信息
  Future<ApiResponse<UserProfile>> getProfile() async {
    return _client.get<UserProfile>(
      '/profile',
      fromJson: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 更新个人信息
  Future<ApiResponse<User>> updateProfile({String? username}) async {
    return _client.patch<User>(
      '/profile',
      data: username != null ? {'username': username} : null,
      fromJson: (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 上传头像
  Future<ApiResponse<User>> updateAvatar(String filePath) async {
    return _client.patch<User>(
      '/profile',
      fromJson: (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 修改密码
  Future<ApiResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    return _client.patch('/profile/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    });
  }
}

class CheckInService {
  final ApiClient _client = ApiClient();

  /// 每日签到
  Future<ApiResponse<CheckInResult>> checkIn() async {
    return _client.post<CheckInResult>(
      '/check_in',
      fromJson: (data) => CheckInResult.fromJson(data as Map<String, dynamic>),
    );
  }
}

class NotificationsService {
  final ApiClient _client = ApiClient();

  /// 通知列表
  Future<ApiResponse<List<NotificationItem>>> getNotifications({
    String scope = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    return _client.get<List<NotificationItem>>(
      '/notifications',
      queryParameters: {
        'scope': scope,
        'page': page,
        'per_page': perPage,
      },
      fromJson: (data) => (data as List)
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      paginated: true,
    );
  }

  /// 未读通知数
  Future<ApiResponse<int>> getUnreadCount() async {
    return _client.get<int>(
      '/notifications/unread_count',
      fromJson: (data) => (data as Map<String, dynamic>)['unread_count'] as int,
    );
  }

  /// 标记已读
  Future<ApiResponse> markRead(int notificationId) async {
    return _client.put('/notifications/$notificationId/read');
  }

  /// 全部标记已读
  Future<ApiResponse> markAllRead() async {
    return _client.put('/notifications/read_all');
  }
}

class ImagesService {
  final ApiClient _client = ApiClient();

  /// 上传图片
  Future<ApiResponse<Map<String, dynamic>>> uploadImage(String filePath) async {
    return _client.post<Map<String, dynamic>>(
      '/images',
      fromJson: (data) => {
        'id': data['id'],
        'url': data['url'],
      },
    );
  }
}

class MiscService {
  final ApiClient _client = ApiClient();

  /// 交流群列表
  Future<ApiResponse<Map<String, dynamic>>> getChatGroups() async {
    return _client.get<Map<String, dynamic>>('/chat_groups');
  }

  /// 站点信息
  Future<ApiResponse<SiteInfo>> getSiteInfo() async {
    return _client.get<SiteInfo>(
      '/site_info',
      fromJson: (data) => SiteInfo.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 友情链接
  Future<ApiResponse<List<FriendLink>>> getFriendLinks() async {
    return _client.get<List<FriendLink>>(
      '/friend_links',
      fromJson: (data) => (data as List)
          .map((e) => FriendLink.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
