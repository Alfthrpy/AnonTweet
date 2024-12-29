// lib/models/post.dart
class Post {
  final int id;
  final String author;
  final String content;
  final String user_id;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.author,
    required this.content,
    required this.user_id,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      author: json['author'],
      content: json['content'],
      user_id: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get timestamp {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
  }
}
