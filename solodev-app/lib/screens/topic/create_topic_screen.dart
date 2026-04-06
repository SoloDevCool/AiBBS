import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/node.dart';
import '../../services/api_services.dart';
import '../../services/api_client.dart';
import '../../models/api_response.dart';

class CreateTopicScreen extends ConsumerStatefulWidget {
  final int? topicId;

  const CreateTopicScreen({super.key, this.topicId});

  @override
  ConsumerState<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends ConsumerState<CreateTopicScreen> {
  final TopicsService _topicsService = TopicsService();
  final NodesService _nodesService = NodesService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _sourceUrlController = TextEditingController();
  List<NodeItem> _nodes = [];
  NodeItem? _selectedNode;
  bool _isLoadingNodes = true;
  bool _isSubmitting = false;
  bool _isRepost = false;
  bool _isEditing = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.topicId != null;
    _loadNodes();
    if (_isEditing) _loadTopic();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadNodes() async {
    final response = await _nodesService.getNodes(kind: 'interest');
    if (response.isSuccess) {
      setState(() {
        _nodes = response.data ?? [];
        _isLoadingNodes = false;
      });
    }
  }

  Future<void> _loadTopic() async {
    try {
      final response = await _topicsService.getTopic(widget.topicId!);
      if (response.isSuccess && response.data != null) {
        final topic = response.data!;
        _titleController.text = topic.title;
        _contentController.text = topic.content;
        if (topic.isRepost && topic.sourceUrl != null) {
          _isRepost = true;
          _sourceUrlController.text = topic.sourceUrl!;
        }
        // Find matching node
        final matchNode = _nodes.where((n) => n.id == topic.node.id).firstOrNull;
        if (matchNode != null) {
          setState(() => _selectedNode = matchNode);
        }
        setState(() => _isLoaded = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载话题失败: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入内容')));
      return;
    }
    if (_selectedNode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择节点')));
      return;
    }
    if (_isRepost && _sourceUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('转载请填写原文链接')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      ApiResponse response;
      if (_isEditing) {
        response = await _topicsService.updateTopic(
          id: widget.topicId!,
          title: title,
          content: content,
          nodeId: _selectedNode!.id,
          isRepost: _isRepost,
          sourceUrl: _isRepost ? _sourceUrlController.text.trim() : null,
        );
      } else {
        response = await _topicsService.createTopic(
          title: title,
          content: content,
          nodeId: _selectedNode!.id,
          isRepost: _isRepost,
          sourceUrl: _isRepost ? _sourceUrlController.text.trim() : null,
        );
      }
      if (response.isSuccess) {
        if (mounted) context.pop();
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
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑话题' : '创建话题'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEditing ? '保存' : '发布', style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Node selector
            DropdownButtonFormField<NodeItem>(
              value: _selectedNode,
              decoration: const InputDecoration(
                labelText: '选择节点 *',
                prefixIcon: Icon(Icons.category),
              ),
              items: _nodes.map((node) {
                return DropdownMenuItem(
                  value: node,
                  child: Text('${node.name} (${node.topicsCount})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedNode = value),
            ),
            const SizedBox(height: 16),
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题 *',
                hintText: '请输入话题标题',
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 200,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // Content
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '内容 *',
                hintText: '支持 Markdown 格式',
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            // Repost toggle
            SwitchListTile(
              title: const Text('转载'),
              subtitle: const Text('标记为转载内容'),
              value: _isRepost,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _isRepost = value),
            ),
            if (_isRepost) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _sourceUrlController,
                decoration: const InputDecoration(
                  labelText: '原文链接 *',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
