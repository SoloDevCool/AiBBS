import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/topic.dart';
import '../../services/api_services.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int? nodeId;
  final String? nodeName;

  const HomeScreen({super.key, this.nodeId, this.nodeName});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final TopicsService _topicsService = TopicsService();
  final List<TopicListItem> _topics = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _currentScope = 'recent';
  int _currentPage = 1;
  bool _hasMore = true;
  late TabController _tabController;

  static const _scopes = ['recent', 'popular', 'following', 'hot'];
  static const _scopeLabels = ['最新', '最热', '已关注', '热门'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _scopes.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _onScopeChanged(_scopes[_tabController.index]);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await _loadTopics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTopics() async {
    _currentPage = 1;
    _hasMore = true;
    final response = await _topicsService.getTopics(
      scope: _currentScope,
      nodeId: widget.nodeId,
      page: 1,
    );
    if (mounted) {
      if (response.isSuccess) {
        setState(() {
          _topics.clear();
          _topics.addAll(response.data ?? []);
          _hasMore = response.pagination?.hasMore ?? false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final response = await _topicsService.getTopics(
      scope: _currentScope,
      nodeId: widget.nodeId,
      page: _currentPage,
    );
    if (mounted) {
      setState(() {
        if (response.isSuccess) {
          _topics.addAll(response.data ?? []);
          _hasMore = response.pagination?.hasMore ?? false;
        }
        _isLoadingMore = false;
      });
    }
  }

  void _onScopeChanged(String scope) {
    setState(() => _currentScope = scope);
    _loadTopics();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nodeName ?? 'SoloDev.Cool'),
        actions: widget.nodeId == null
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push('/search'),
                ),
              ]
            : null,
        bottom: widget.nodeId == null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _scopeLabels.map((label) => Tab(text: label)).toList(),
              )
            : null,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: authState.user?.avatarUrl != null
                        ? NetworkImage(authState.user!.avatarUrl!)
                        : null,
                    child: authState.user?.avatarUrl == null
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authState.user?.username ?? '未登录',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('首页'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('节点'),
              onTap: () {
                Navigator.pop(context);
                context.push('/nodes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('通知'),
              onTap: () {
                Navigator.pop(context);
                context.push('/notifications');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('个人资料'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出登录'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: _topics.isEmpty
                  ? const Center(child: Text('暂无话题'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _topics.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _topics.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _TopicCard(
                          topic: _topics[index],
                          onTap: () => context.push('/topic/${_topics[index].id}'),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/topic/create'),
        child: const Icon(Icons.edit),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final TopicListItem topic;
  final VoidCallback onTap;

  const _TopicCard({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: topic.author.avatarUrl != null
                        ? NetworkImage(topic.author.avatarUrl!)
                        : null,
                    child: topic.author.avatarUrl == null
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(topic.author.username,
                      style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text(_timeAgo(topic.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              if (topic.pinned)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('置顶',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer)),
                ),
              Text(topic.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (topic.excerpt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(topic.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(topic.node.name,
                        style: theme.textTheme.labelSmall),
                  ),
                  const Spacer(),
                  if (topic.hasPoll)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.poll, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text('投票', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text('${topic.viewsCount}',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(topic.isCooled ? Icons.favorite : Icons.favorite_border,
                          size: 14, color: topic.isCooled ? Colors.red : Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text('${topic.coolsCount}',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.comment_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text('${topic.commentsCount}',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
