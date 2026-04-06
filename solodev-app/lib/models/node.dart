class NodeBrief {
  final int id;
  final String name;
  final String slug;

  NodeBrief({required this.id, required this.name, required this.slug});

  factory NodeBrief.fromJson(Map<String, dynamic> json) {
    return NodeBrief(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

class NodeItem {
  final int id;
  final String name;
  final String slug;
  final String kind;
  final int topicsCount;
  final bool isFollowed;
  final int position;

  NodeItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.kind,
    required this.topicsCount,
    this.isFollowed = false,
    required this.position,
  });

  factory NodeItem.fromJson(Map<String, dynamic> json) {
    return NodeItem(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      kind: json['kind'] as String? ?? 'interest',
      topicsCount: json['topics_count'] as int? ?? 0,
      isFollowed: json['is_followed'] as bool? ?? false,
      position: json['position'] as int? ?? 0,
    );
  }
}
