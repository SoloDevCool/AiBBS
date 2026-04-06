import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/topic.dart';
import '../../models/node.dart';
import '../../models/notification.dart';
import '../../services/api_services.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final int topicId;

  const TopicDetailScreen({super.key, required this.topicId});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final TopicsService _topicsService = TopicsService();
  final CommentsService _commentsService = CommentsService();
  final InteractionsService _interactionsService = InteractionsService();
  TopicDetail? _topic;
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  int? _replyToId;
  String _replyToUsername = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTopic();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTopic() async {
    setState(() => _isLoading = true);
    try {
      final response = await _topicsService.getTopic(widget.topicId);
      if (response.isSuccess && response.data != null) {
        setState(() => _topic = response.data!);
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

  Future<void> _toggleCool() async {
    if (_topic == null) return;
    final wasCooled = _topic!.isCooled;
    try {
      if (wasCooled) {
        await _interactionsService.uncoolTopic(_topic!.id);
      } else {
        await _interactionsService.coolTopic(_topic!.id);
      }
      setState(() {
        _topic = TopicDetail(
          id: _topic!.id,
          title: _topic!.title,
          slug: _topic!.slug,
          content: _topic!.content,
          node: _topic!.node,
          author: _topic!.author,
          commentsCount: _topic!.commentsCount,
          coolsCount: _topic!.coolsCount + (wasCooled ? -1 : 1),
          viewsCount: _topic!.viewsCount,
          pinned: _topic!.pinned,
          isRepost: _topic!.isRepost,
          sourceUrl: _topic!.sourceUrl,
          isCooled: !wasCooled,
          isAuthor: _topic!.isAuthor,
          hasPoll: _topic!.hasPoll,
          poll: _topic!.poll,
          comments: _topic!.comments,
          createdAt: _topic!.createdAt,
          updatedAt: _topic!.updatedAt,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await _commentsService.createComment(
        topicId: widget.topicId,
        content: content,
        parentId: _replyToId,
      );
      if (response.isSuccess) {
        _commentController.clear();
        setState(() {
          _replyToId = null;
          _replyToUsername = '';
        });
        await _loadTopic();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('评论失败: $e')),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _commentsService.deleteComment(topicId: widget.topicId, commentId: commentId);
      await _loadTopic();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteTopic() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个话题吗？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _topicsService.deleteTopic(widget.topicId);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_topic?.title ?? '话题详情', overflow: TextOverflow.ellipsis),
        actions: [
          if (_topic?.isAuthor == true) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await context.push('/topic/${widget.topicId}/edit');
                _loadTopic();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTopic,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('链接已复制')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topic == null
              ? const Center(child: Text('话题不存在'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          // Topic header
                          _buildTopicHeader(),
                          const SizedBox(height: 12),
                          // Topic content
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SelectableText(_topic!.content),
                          ),
                          if (_topic!.isRepost && _topic!.sourceUrl != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.link, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text('转载自: ${_topic!.sourceUrl}',
                                        style: Theme.of(context).textTheme.bodySmall),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Poll
                          if (_topic!.hasPoll && _topic!.poll != null) ...[
                            const SizedBox(height: 16),
                            _buildPoll(_topic!.poll!),
                          ],
                          // Interaction bar
                          const SizedBox(height: 16),
                          _buildActionBar(),
                          const Divider(height: 32),
                          // Comments
                          Text('评论 (${_topic!.commentsCount})',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ..._topic!.comments.map((c) => _buildCommentTree(c, 0)),
                        ],
                      ),
                    ),
                    // Comment input
                    _buildCommentInput(),
                  ],
                ),
    );
  }

  Widget _buildTopicHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/user/${_topic!.author.id}'),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: _topic!.author.avatarUrl != null
                ? NetworkImage(_topic!.author.avatarUrl!)
                : null,
            child: _topic!.author.avatarUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push('/user/${_topic!.author.id}'),
                child: Text(_topic!.author.username,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => context.push('/nodes'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_topic!.node.name,
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
            ],
          ),
        ),
        Text('${_topic!.viewsCount} 浏览',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPoll(Poll poll) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.poll, size: 18),
                const SizedBox(width: 6),
                Text('投票', style: Theme.of(context).textTheme.titleSmall),
                if (poll.closed) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('已关闭',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.orange)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ...poll.options.map((option) {
              final totalVotes =
                  poll.options.fold<int>(0, (sum, o) => sum + o.votesCount);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(option.title)),
                        if (option.voted) const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('${option.votesCount} 票',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalVotes > 0 ? option.percentage / 100 : 0,
                        minHeight: 6,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        Expanded(
          child: Text('${_topic!.coolsCount} 酷',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text('${_topic!.commentsCount} 评论',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text('${_topic!.viewsCount} 浏览',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  Widget _buildCommentTree(CommentTree comment, int depth) {
    final theme = Theme.of(context);
    final indent = depth * 16.0;
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/user/${comment.author.id}'),
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: comment.author.avatarUrl != null
                      ? NetworkImage(comment.author.avatarUrl!)
                      : null,
                  child: comment.author.avatarUrl == null
                      ? const Icon(Icons.person, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/user/${comment.author.id}'),
                child: Text(comment.author.username,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (comment.isAuthor) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('作者', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                ),
              ],
              if (comment.loginOnly) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('仅登录可见',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: Colors.orange)),
                ),
              ],
              const Spacer(),
              Text(_timeAgo(comment.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          // Comment content
          SelectableText(comment.content, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          // Comment actions
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _replyToId = comment.id;
                    _replyToUsername = comment.author.username;
                  });
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.reply, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Text('回复', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[500])),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  try {
                    if (comment.isCooled) {
                      await _interactionsService.uncoolComment(comment.id);
                    } else {
                      await _interactionsService.coolComment(comment.id);
                    }
                    await _loadTopic();
                  } catch (_) {}
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        comment.isCooled ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: comment.isCooled ? Colors.red : Colors.grey[500]),
                    const SizedBox(width: 2),
                    Text('${comment.coolsCount}',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[500])),
                  ],
                ),
              ),
              if (comment.tipsTotal > 0) ...[
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text('${comment.tipsTotal}',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber)),
                  ],
                ),
              ],
              if (comment.isAuthor) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => _deleteComment(comment.id),
                  child: Icon(Icons.delete_outline, size: 14, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
          // Replies
          ...comment.replies.map((r) => _buildCommentTree(r, depth + 1)),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('回复 @$_replyToUsername',
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyToId = null;
                        _replyToUsername = '';
                      });
                    },
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: '写评论...',
                    isDense: true,
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isSubmitting ? null : _submitComment,
                icon: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, size: 18),
              ),
            ],
          ),
        ],
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
