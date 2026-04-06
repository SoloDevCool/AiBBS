import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../models/topic.dart';
import '../../services/api_services.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final UsersService _usersService = UsersService();
  final TopicsService _topicsService = TopicsService();
  UserPublicProfile? _profile;
  List<TopicListItem> _topics = [];
  bool _isLoading = true;
  bool _isLoadingTopics = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadProfile(), _loadTopics()]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadProfile() async {
    final response = await _usersService.getUserProfile(widget.userId);
    if (response.isSuccess && response.data != null) {
      setState(() => _profile = response.data!);
    }
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoadingTopics = true);
    final response = await _topicsService.getTopics(page: 1, perPage: 20);
    if (response.isSuccess) {
      setState(() => _topics = (response.data ?? []).where((t) => t.author.id == widget.userId).toList());
    }
    setState(() => _isLoadingTopics = false);
  }

  Future<void> _toggleFollow() async {
    if (_profile == null) return;
    setState(() => _isFollowLoading = true);
    try {
      if (_profile!.isFollowed) {
        await _usersService.unfollowUser(widget.userId);
      } else {
        await _usersService.followUser(widget.userId);
      }
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
    setState(() => _isFollowLoading = false);
  }

  Future<void> _toggleBlock() async {
    if (_profile == null) return;
    final action = _profile!.isBlocked ? '取消屏蔽' : '屏蔽';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认$action'),
        content: Text('确定要$action该用户吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (_profile!.isBlocked) {
        await _usersService.unblockUser(widget.userId);
      } else {
        await _usersService.blockUser(widget.userId);
      }
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.username ?? '用户主页'),
        actions: [
          if (_profile != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') _toggleBlock();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(_profile!.isBlocked ? '取消屏蔽' : '屏蔽用户'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('用户不存在'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 48,
                                      backgroundImage: _profile!.avatarUrl != null
                                          ? NetworkImage(_profile!.avatarUrl!)
                                          : null,
                                      child: _profile!.avatarUrl == null
                                          ? const Icon(Icons.person, size: 48)
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(_profile!.username,
                                        style: theme.textTheme.headlineSmall),
                                    const SizedBox(height: 4),
                                    Text('注册于 ${_formatDate(_profile!.createdAt)}',
                                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('${_profile!.points} 酷能量',
                                          style: theme.textTheme.labelSmall),
                                    ),
                                    const SizedBox(height: 16),
                                    // Follow button
                                    SizedBox(
                                      width: 160,
                                      child: FilledButton.tonal(
                                        onPressed: _isFollowLoading ? null : _toggleFollow,
                                        child: _isFollowLoading
                                            ? const SizedBox(
                                                width: 18, height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2))
                                            : Text(_profile!.isFollowed ? '已关注' : '关注'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Stats
                              Row(
                                children: [
                                  _StatChip(icon: Icons.article, label: '话题', value: _profile!.topicsCount),
                                  const SizedBox(width: 8),
                                  _StatChip(icon: Icons.comment, label: '评论', value: _profile!.commentsCount),
                                  const SizedBox(width: 8),
                                  _StatChip(icon: Icons.people, label: '粉丝', value: _profile!.followersCount),
                                  const SizedBox(width: 8),
                                  _StatChip(icon: Icons.person_add, label: '关注', value: _profile!.followingCount),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Topics
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text('话题', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      if (_isLoadingTopics)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else if (_topics.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('暂无话题')),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final topic = _topics[index];
                              return ListTile(
                                title: Text(topic.title),
                                subtitle: Text('${topic.commentsCount} 评论 · ${topic.viewsCount} 浏览'),
                                onTap: () => context.push('/topic/${topic.id}'),
                              );
                            },
                            childCount: _topics.length,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 2),
            Text('$value', style: Theme.of(context).textTheme.titleSmall),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
