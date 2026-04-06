import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../models/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final CheckInService _checkInService = CheckInService();
  UserProfile? _profile;
  UserStats? _stats;
  bool _isLoading = true;
  bool _isCheckingIn = false;
  bool _todayCheckedIn = false;
  int _totalPoints = 0;
  int _pointsEarned = 0;
  bool _showCheckInAnimation = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await _profileService.getProfile();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _profile = response.data!;
          _stats = response.data!.stats;
          ref.read(authProvider.notifier).updateUser(response.data!.user);
        });
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

  Future<void> _checkIn() async {
    setState(() => _isCheckingIn = true);
    try {
      final response = await _checkInService.checkIn();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _todayCheckedIn = response.data!.todayCheckedIn;
          _totalPoints = response.data!.totalPoints;
          _pointsEarned = response.data!.pointsEarned;
          _showCheckInAnimation = true;
        });
        ref.read(authProvider.notifier).updateUser(
              User(
                id: _profile!.user.id,
                email: _profile!.user.email,
                username: _profile!.user.username,
                avatarUrl: _profile!.user.avatarUrl,
                points: _totalPoints,
                role: _profile!.user.role,
                createdAt: _profile!.user.createdAt,
              ),
            );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showCheckInAnimation = false);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('签到失败: $e')),
        );
      }
    }
    setState(() => _isCheckingIn = false);
  }

  Future<void> _changePassword(BuildContext context) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                decoration: const InputDecoration(labelText: '当前密码'),
                obscureText: true,
                validator: (v) => v?.isEmpty ?? true ? '请输入当前密码' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                decoration: const InputDecoration(labelText: '新密码'),
                obscureText: true,
                validator: (v) => (v?.length ?? 0) < 6 ? '密码至少6位' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                decoration: const InputDecoration(labelText: '确认新密码'),
                obscureText: true,
                validator: (v) => v != newController.text ? '密码不一致' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final response = await _profileService.changePassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
        newPasswordConfirmation: confirmController.text,
      );
      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码修改成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = _profile?.user ?? authState.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('个人资料')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar and basic info
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // TODO: Pick and upload avatar
                          },
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundImage: user?.avatarUrl != null
                                    ? NetworkImage(user!.avatarUrl!)
                                    : null,
                                child: user?.avatarUrl == null
                                    ? const Icon(Icons.person, size: 48)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(user?.username ?? '',
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(user?.email ?? '', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${user?.points ?? 0} 酷能量',
                              style: theme.textTheme.labelSmall),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Check-in card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('每日签到', style: theme.textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(
                                  _todayCheckedIn ? '今日已签到' : '今日未签到',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: _todayCheckedIn ? Colors.green : Colors.orange),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: (_todayCheckedIn || _isCheckingIn) ? null : _checkIn,
                            icon: _isCheckingIn
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.check_circle),
                            label: Text(_todayCheckedIn ? '已签到' : '签到'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showCheckInAnimation)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+$_pointsEarned 酷能量!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Stats cards
                  Row(
                    children: [
                      _StatCard(label: '话题', value: _stats?.topicsCount ?? 0, icon: Icons.article),
                      const SizedBox(width: 8),
                      _StatCard(label: '评论', value: _stats?.commentsCount ?? 0, icon: Icons.comment),
                      const SizedBox(width: 8),
                      _StatCard(label: '关注者', value: _stats?.followersCount ?? 0, icon: Icons.people),
                      const SizedBox(width: 8),
                      _StatCard(label: '关注', value: _stats?.followingCount ?? 0, icon: Icons.person_add),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('修改用户名'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editUsername(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('修改密码'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _changePassword(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('退出登录'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('确认退出'),
                          content: const Text('确定要退出登录吗？'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消')),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.read(authProvider.notifier).logout();
                                },
                                child: const Text('退出')),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _editUsername() async {
    final controller = TextEditingController(text: _profile?.user.username ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改用户名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '用户名'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;
    try {
      final response = await _profileService.updateProfile(username: result.trim());
      if (response.isSuccess && response.data != null) {
        ref.read(authProvider.notifier).updateUser(response.data!);
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('用户名修改成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: $e')),
        );
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              Text('$value', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
