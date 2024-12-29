// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Fetch all posts
  Future<List<Map<String, dynamic>>> getPosts() async {
    final response = await client
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    print(response);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> getPostsByUserId(String userId) async {
    final response = await client
        .from('posts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    print(response);

    return List<Map<String, dynamic>>.from(response as List);
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
