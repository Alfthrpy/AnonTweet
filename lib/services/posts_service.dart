// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PostsService {
  final SupabaseClient client = Supabase.instance.client;

  // Fetch all posts
  Future<List<Map<String, dynamic>>> getPosts() async {
    final response = await client.from('posts').select('''
      *,
      reactions:reactions(count)
    ''').order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response.map((post) {
      return {...post, 'reaction_count': post['reactions'][0]['count']};
    }));
  }

  // Get reaction count for a specific post
  Future<int> getReactionCount(int postId) async {
    final response =
        await client.from('reactions').select().eq('post_id', postId).count();

    return response.count;
  }

  Future<List<Map<String, dynamic>>> getPostsByUserId(String userId) async {
    final response = await client.from('posts').select('''
      *,
      reactions:reactions(count)
    ''').eq('user_id', userId).order('created_at', ascending: false);

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
}
