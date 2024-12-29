// lib/screens/home_page.dart
import 'dart:io';

import 'package:blog_anon/services/supabase_service.dart';
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

  final _supabaseService = SupabaseService();
  List<Post> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final postsData = await _supabaseService.getPosts();
      print(postsData);
      setState(() {
        _posts = postsData.map((data) => Post.fromJson(data)).toList();
      });
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPost() async {
    final prefs = await SharedPreferences.getInstance();
    if (_authorController.text.isNotEmpty &&
        _contentController.text.isNotEmpty) {
      try {
        await _supabaseService.createPost(
          author: _authorController.text,
          content: _contentController.text,
          user_id: prefs.getString("user_id") ?? '',
        );
        // _authorController.clear();
        _contentController.clear();
        await _loadPosts(); // Reload posts after adding
      } on SocketException {
        // Menangani jika tidak ada koneksi internet
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
      }
    } else {
      // Menangani jika field kosong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in both fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                      textAlign: TextAlign
                          .center, // Properti textAlign dipindahkan ke sini
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8), // Rounded full
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 0,
                            blurRadius: 6,
                            offset: Offset(0, 4), // Shadow appears below
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _authorController,
                        decoration: const InputDecoration(
                          labelText: 'Sender',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8), // Rounded full
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
                        borderRadius: BorderRadius.circular(8), // Rounded full
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 0,
                            blurRadius: 6,
                            offset: Offset(0, 4), // Shadow appears below
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: 3, // Multi-line support
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8), // Rounded full
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
            const SizedBox(height: 16),
            const Text(
              'Cuitan Terbaru',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _posts.length > 3 ? 3 : _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 16),
                    child: Card(
                      color: baseColor, // Background white
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded-md
                      ),
                      elevation: 4, // Optional: Add slight shadow if needed
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
    );
  }

  @override
  void dispose() {
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
