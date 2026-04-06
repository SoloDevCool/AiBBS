import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../models/notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final NotificationsService _notificationsService = NotificationsService();
  final List<NotificationItem> _notifications = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _scope = 'all';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadNotifications(), _loadUnreadCount()]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotifications() async {
    _currentPage = 1;
    _hasMore = true;
    final response = await _notificationsService.getNotifications(
      scope: _scope,
      page: 1,
    );
    if (response.isSuccess) {
      _notifications.clear();
      _notifications.addAll(response.data ?? []);
      _hasMore = response.pagination?.hasMore ?? false;
    }
  }

  Future<void> _loadUnreadCount() async {
    final response = await _notificationsService.getUnreadCount();
    if (response.isSuccess) {
      setState(() => _unreadCount = response.data ?? 0);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final response = await _notificationsService.getNotifications(
      scope: _scope,
      page: _currentPage,
    );
    if (response.isSuccess) {
      _notifications.addAll(response.data ?? []);
      _hasMore = response.pagination?.hasMore ?? false;
    }
    setState(() => _isLoadingMore = false);
  }

  Future<void> _markAllRead() async {
    try {
      await _notificationsService.markAllRead();
      setState(() {
        for (final n in _notifications) {
          // Mark locally since model is immutable, just refresh
        }
        _unreadCount = 0;
      });
      await _loadNotifications();
    } catch (_) {}
  }

  void _onScopeChanged(String scope) {
    setState(() => _scope = scope);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('通知'),
            if (_unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('全部已读'),
            ),
          PopupMenuButton<String>(
            onSelected: _onScopeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'comment', child: Text('评论')),
              const PopupMenuItem(value: 'mention', child: Text('提及')),
              const PopupMenuItem(value: 'cool', child: Text('赞')),
              const PopupMenuItem(value: 'follower', child: Text('关注')),
              const PopupMenuItem(value: 'tip', child: Text('打赏')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('暂无通知'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final notification = _notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () async {
                          if (!notification.read) {
                            await _notificationsService.markRead(notification.id);
                          }
                          // Navigate to related topic if available
                          if (notification.notifiable?.topic != null) {
                            final topicId = notification.notifiable!.topic!.id;
                            if (mounted) context.push('/topic/$topicId');
                          }
                          _loadUnreadCount();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.read ? null : theme.colorScheme.primaryContainer.withOpacity(0.3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: notification.actor.avatarUrl != null
                  ? NetworkImage(notification.actor.avatarUrl!)
                  : null,
              child: notification.actor.avatarUrl == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: notification.actor.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${_getNotifyActionText()}'),
                      ],
                    ),
                  ),
                  if (notification.notifiable?.topic != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.notifiable!.topic!.title,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _getNotifyActionText() {
    switch (notification.notifyType) {
      case 'new_comment':
        return '评论了你的主题';
      case 'new_reply':
        return '回复了你的评论';
      case 'mention':
        return '在评论中提到了你';
      case 'new_follower':
        return '关注了你';
      case 'topic_cool':
        return '觉得你的主题很 Cool';
      case 'comment_cool':
        return '觉得你的评论很 Cool';
      case 'tip':
        return '打赏了你';
      case 'topic_vote':
        return '参与了你的投票';
      default:
        return '有新动态';
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${dateTime.month}-${dateTime.day}';
  }
}
