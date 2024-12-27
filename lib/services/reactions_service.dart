import 'package:supabase_flutter/supabase_flutter.dart';

class ReactionService {
  final SupabaseClient client = Supabase.instance.client;
  Future<void> toggleReaction(
      int postId, String reactionType, String userId) async {
    try {
      final exists = await client
          .from('reactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle(); // Gunakan maybeSingle untuk menghindari error

      if (exists != null) {
        // Jika sudah ada data, hapus reaksi
        await client
            .from('reactions')
            .delete()
            .match({'post_id': postId, 'user_id': userId});
      } else {
        // Jika tidak ada data, tambahkan reaksi baru
        await client.from('reactions').insert({
          'post_id': postId,
          'user_id': userId,
          'reaction_type': reactionType,
        });
      }
    } catch (e) {
      // Tangani error dengan cara yang sesuai
      print('Error: $e');
    }
  }

  Future<bool> hasReacted(int postId, String userId) async {
    final response = await client
        .from('reactions')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId);
    return response.isNotEmpty;
  }
}
