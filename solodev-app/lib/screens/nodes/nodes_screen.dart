import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/node.dart';
import '../../services/api_services.dart';

class NodesScreen extends StatefulWidget {
  const NodesScreen({super.key});

  @override
  State<NodesScreen> createState() => _NodesScreenState();
}

class _NodesScreenState extends State<NodesScreen> with SingleTickerProviderStateMixin {
  final NodesService _nodesService = NodesService();
  List<NodeItem> _nodes = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadNodes();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final kinds = ['interest', 'system'];
    _selectedKind = kinds[_tabController.index];
    _loadNodes();
  }

  String? _selectedKind;

  Future<void> _loadNodes() async {
    setState(() => _isLoading = true);
    try {
      final response = await _nodesService.getNodes(
        kind: _selectedKind,
      );
      if (response.isSuccess) {
        setState(() => _nodes = response.data ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow(NodeItem node) async {
    try {
      if (node.isFollowed) {
        await _nodesService.unfollowNode(node.id);
      } else {
        await _nodesService.followNode(node.id);
      }
      await _loadNodes();
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
        title: const Text('节点'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '兴趣节点'),
            Tab(text: '系统节点'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nodes.isEmpty
              ? const Center(child: Text('暂无节点'))
              : RefreshIndicator(
                  onRefresh: _loadNodes,
                  child: ListView.builder(
                    itemCount: _nodes.length,
                    itemBuilder: (context, index) {
                      final node = _nodes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(node.name[0],
                              style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(node.name),
                        subtitle: Text('${node.topicsCount} 个话题'),
                        trailing: OutlinedButton(
                          onPressed: () => _toggleFollow(node),
                          child: Text(node.isFollowed ? '已关注' : '关注'),
                        ),
                        onTap: () {
                          context.pop();
                          context.go('/node/${node.id}?name=${Uri.encodeComponent(node.name)}');
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
