import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../themes/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _selectedAvatar = '';
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  final SupabaseClient client = Supabase.instance.client;

  // Daftar avatar yang tersedia
  final List<String> _avatarOptions = [
    'https://cnwfmmxuqrleotacsdci.supabase.co/storage/v1/object/public/shortener-API/anon_tweet_profile_pic/profile_pic_1.png',
    'https://cnwfmmxuqrleotacsdci.supabase.co/storage/v1/object/public/shortener-API/anon_tweet_profile_pic/profile_pic_2.png',
    'https://cnwfmmxuqrleotacsdci.supabase.co/storage/v1/object/public/shortener-API/anon_tweet_profile_pic/profile_pic_3.png',
    'https://cnwfmmxuqrleotacsdci.supabase.co/storage/v1/object/public/shortener-API/anon_tweet_profile_pic/profile_pic_4.png',
    'https://cnwfmmxuqrleotacsdci.supabase.co/storage/v1/object/public/shortener-API/anon_tweet_profile_pic/profile_pic_5.png',
    'https://cnwfmmxuqrleotacsdci.supabase.co/storage/v1/object/public/shortener-API/anon_tweet_profile_pic/profile_pic_6.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAvatar = prefs.getString('avatar_url') ?? _avatarOptions[0];
      _nameController.text = prefs.getString('user_name') ?? 'Anonim';
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    await prefs.setString('avatar_url', _selectedAvatar);
    await prefs.setString('user_name', _nameController.text);

    if (userId != null) {
      final response = await client.from('profile_pic').upsert({
        'user_id': userId,
        'profile_pic_link': _selectedAvatar,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan ke database')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error!.message}')),
        );
      }
    }

    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: baseColor),
        ),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                _saveProfile();
              }),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: secondaryColor,
                      width: 3,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(_selectedAvatar),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Pilih Avatar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _avatarOptions.length,
                itemBuilder: (context, index) {
                  final avatar = _avatarOptions[index];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatar;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedAvatar == avatar
                              ? secondaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          avatar,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
