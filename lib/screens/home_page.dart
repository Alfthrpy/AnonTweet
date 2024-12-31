// lib/screens/home_page.dart
import 'dart:io';

import 'package:blog_anon/services/posts_service.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authorController = TextEditingController();
  final _contentController = TextEditingController();
  final _postService = PostsService();
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _initializeAuthorController();
    _loadPosts();
    _loadAvatarUrl();
  }

  Future<void> _initializeAuthorController() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? '';
    _authorController.text = userName;
  }

  Future<void> _loadAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarUrl = prefs.getString('avatar_url');
    if (mounted) {
      setState(() {
        _avatarUrl = avatarUrl;
      });
    }
  }

  Future<void> _loadPosts() async {
    try {
      final postsData = await _postService.getPosts();
      if (mounted) {
        setState(() {
          _posts = postsData.map((data) => Post.fromJson(data)).toList();
        });
      }
    } on SocketException {
      // Menangani kesalahan jaringan (misalnya, tidak ada koneksi internet)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('No internet connection. Please check your network.')),
      );
    } catch (e) {
      // Menangani kesalahan umum lainnya
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    if (mounted) {
      setState(() => _isLoading = true);
    }
  }

  Future<void> _addPost() async {
    final prefs = await SharedPreferences.getInstance();
    if (_authorController.text.isNotEmpty &&
        _contentController.text.isNotEmpty) {
      if (_authorController.text.length > 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nama tidak boleh lebih dari 12 karakter')),
        );
        return;
      }
      try {
        await _postService.createPost(
          author: _authorController.text,
          content: _contentController.text,
          user_id: prefs.getString("user_id") ?? '',
        );

        // _authorController.clear();
        _contentController.clear();
        await _loadPosts(); // Reload posts after adding

        // Menampilkan snackbar jika berhasil membuat post
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil membuat cuitan')),
        );
      } on SocketException {
        // Menangani jika tidak ada koneksi internet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Tidak ada koneksi internet. Silakan periksa jaringan Anda.')),
        );
      } catch (e) {
        // Menangani kesalahan umum lainnya
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      // Menangani jika field kosong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap isi kedua field.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'AnonTweet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: baseColor, // Putih dalam hex code
          ),
        ),
        backgroundColor:
            primaryColor, // Pastikan menambahkan 0xFF untuk opacity penuh
        actions: [
          if (_avatarUrl != null)
            IconButton(
              icon: CircleAvatar(
                backgroundImage: NetworkImage(_avatarUrl!),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile').then((_) {
                  if (mounted) {
                    setState(() {
                      _loadAvatarUrl();
                      _initializeAuthorController();
                    });
                  }
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                Navigator.pushNamed(context, '/profile').then((_) {
                  // Setelah kembali dari halaman profil, memuat ulang data
                  if (mounted) {
                    setState(() {
                      _loadAvatarUrl();
                      _initializeAuthorController();
                    });
                  }
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Buat Cuitan Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 0,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _authorController,
                          decoration: const InputDecoration(
                            labelText: 'Sender',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 0,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _contentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Content',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tertiaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Post',
                          style: TextStyle(color: baseColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'Cuitan Terbaru',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: _posts.length > 3 ? 3 : _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Container(
                      width: 300,
                      margin: const EdgeInsets.only(right: 16),
                      child: Card(
                        color: baseColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.author,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(
                                post.timestamp,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
