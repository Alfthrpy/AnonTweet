// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PostsService {
  final SupabaseClient client = Supabase.instance.client;

  // Fetch all posts
  Future<List<Map<String, dynamic>>> getPosts(
      {int limit = 10, int offset = 0}) async {
    final response = await client
        .from('posts')
        .select('''
      *,
      reactions:reactions(count)
    ''')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response.map((post) {
      return {...post, 'reaction_count': post['reactions'][0]['count']};
    }));
  }

  // Get reaction count for a specific post

  Future<List<Map<String, dynamic>>> getPostsByUserId(String userId,
      {int limit = 10, int offset = 0}) async {
    final response = await client
        .from('posts')
        .select('''
      *,
      reactions:reactions(count)
    ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    ;

    return List<Map<String, dynamic>>.from(response.map((post) {
      return {...post, 'reaction_count': post['reactions'][0]['count']};
    }));
  }

  // Create new post
  Future<void> createPost({
    required String author,
    required String content,
    required String user_id,
  }) async {
    final response = await client.from('posts').insert({
      'author': author,
      'content': content,
      'user_id': user_id,
    });
  }

  Future<int> getReactionCount(int postId) async {
    final response =
        await client.from('reactions').select().eq('post_id', postId).count();

    return response.count;
  }

  // Get top 3 posts with most reactions in a day
  Future<List<Map<String, dynamic>>> getTopPostsOfDay() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = startDate.add(const Duration(days: 1));

    // Get posts created today
    final response = await client
        .from('posts')
        .select()
        .gte('created_at', startDate.toIso8601String())
        .lt('created_at', endDate.toIso8601String());

    // Convert to list of maps and get reaction counts
    final posts = await Future.wait(
      response.map((post) async {
        final reactionCount = await getReactionCount(post['id']);
        return {...post, 'reaction_count': reactionCount};
      }),
    );

    // Sort by reaction count and get top 3
    return posts
      ..sort((a, b) =>
          (b['reaction_count'] as int).compareTo(a['reaction_count'] as int))
      ..take(1).toList();
  }

  Future<void> updatePost(String postId, String newContent) async {
    final response = await client
        .from('posts')
        .update({'content': newContent})
        .eq('id', postId)
        .select();

    if (response.isEmpty) {
      throw Exception('Post tidak ditemukan atau tidak dapat diperbarui.');
    }
  }
}
