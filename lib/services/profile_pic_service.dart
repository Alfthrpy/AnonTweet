import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePicService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getProfilePic(String userId) async {
    try {
      final response = await _supabase
          .from('profile_pic')
          .select('profile_pic_link')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['profile_pic_link'] != null) {
        return response['profile_pic_link'];
      }
      return null;
    } catch (e) {
      print('Error fetching profile picture: $e');
      return null;
    }
  }
}
