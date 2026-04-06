import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/topic.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TopicsService _topicsService = TopicsService();
  final UsersService _usersService = UsersService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  late final TabController _tabController;

  List<TopicListItem> _topicResults = [];
  List<UserBrief> _userResults = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty || query == _lastQuery) return;
    _lastQuery = query;
    _doSearch(query.trim());
  }

  Future<void> _doSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      if (_tabController.index == 0) {
        final response = await _topicsService.searchTopics(query: query);
        if (response.isSuccess) {
          setState(() => _topicResults = response.data ?? []);
        }
      } else {
        final response = await _usersService.searchUsers(query);
        if (response.isSuccess) {
          setState(() => _userResults = response.data ?? []);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: $e')),
        );
      }
    }
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索话题或用户...',
            border: InputBorder.none,
          ),
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => _doSearch(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) _doSearch(query);
            },
            child: const Text('搜索'),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '话题'),
              Tab(text: '用户'),
            ],
            onTap: (_) {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) _doSearch(query);
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _topicResults.isEmpty
                        ? Center(
                            child: Text(
                              _lastQuery.isEmpty ? '输入关键词搜索' : '未找到相关话题',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _topicResults.length,
                            itemBuilder: (context, index) {
                              final topic = _topicResults[index];
                              return ListTile(
                                title: Text(topic.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (topic.excerpt.isNotEmpty)
                                      Text(topic.excerpt,
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                    Text(
                                      '${topic.author.username} · ${topic.node.name} · ${topic.commentsCount} 评论',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                onTap: () => context.push('/topic/${topic.id}'),
                              );
                            },
                          ),
                _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _userResults.isEmpty
                        ? Center(
                            child: Text(
                              _lastQuery.isEmpty ? '输入关键词搜索' : '未找到相关用户',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _userResults.length,
                            itemBuilder: (context, index) {
                              final user = _userResults[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user.avatarUrl != null
                                      ? NetworkImage(user.avatarUrl!)
                                      : null,
                                  child: user.avatarUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(user.username),
                                onTap: () => context.push('/user/${user.id}'),
                              );
                            },
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
