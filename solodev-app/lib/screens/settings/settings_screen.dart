import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../models/notification.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final MiscService _miscService = MiscService();
  SiteInfo? _siteInfo;
  List<FriendLink> _friendLinks = [];
  List<ChatGroup> _chatGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _miscService.getSiteInfo(),
        _miscService.getFriendLinks(),
        _miscService.getChatGroups(),
      ]);

      if (results[0].isSuccess) {
        // Site info
      }
      if (results[1].isSuccess) {
        final data = results[1].data;
        if (data is List) {
          setState(() {
            _friendLinks = data
                .map((e) => FriendLink.fromJson(e as Map<String, dynamic>))
                .toList();
          });
        }
      }
      if (results[2].isSuccess) {
        final data = results[2].data;
        if (data is Map<String, dynamic>) {
          final groups = data['chat_groups'] as List?;
          if (groups != null) {
            setState(() {
              _chatGroups = groups
                  .map((e) => ChatGroup.fromJson(e as Map<String, dynamic>))
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      // Silently handle
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // About
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('关于 SoloDev.Cool'),
                  subtitle: Text('独立开发者社区'),
                ),

                const Divider(),

                // Chat groups
                if (_chatGroups.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('交流群',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  ..._chatGroups.map((group) => ListTile(
                        leading: const Icon(Icons.chat),
                        title: Text(group.name),
                        subtitle: group.description != null ? Text(group.description!) : null,
                        trailing: Text('${group.membersCount} 人',
                            style: theme.textTheme.bodySmall),
                      )),
                  const Divider(),
                ],

                // Friend links
                if (_friendLinks.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('友情链接',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  ..._friendLinks.map((link) => ListTile(
                        leading: const Icon(Icons.link),
                        title: Text(link.name),
                        subtitle: link.description != null ? Text(link.description!) : null,
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () {
                          // Open link in browser
                        },
                      )),
                  const Divider(),
                ],

                // Navigation
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('其他',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('个人资料'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile'),
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('节点'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/nodes'),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('API 文档'),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () {
                    // Open API docs
                  },
                ),

                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'SoloDev.Cool v1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
