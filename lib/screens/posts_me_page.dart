// lib/screens/posts_page.dart
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostsMePage extends StatefulWidget {
  const PostsMePage({Key? key}) : super(key: key);

  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsMePage> {
  final _supabaseService = SupabaseService();
  List<Post> _posts = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _setupRealtimeSubscription();
  }

  Future<void> _setupRealtimeSubscription() async {
    _supabaseService.client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('user_id',
            (await SharedPreferences.getInstance()).getString("user_id") ?? '')
        .listen((data) {
          if (mounted) {
            setState(() {
              _posts = data.map((post) => Post.fromJson(post)).toList()
                ..sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt)); // Sort desc
            });
          }
        });
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isLoading = true);
    try {
      final postsData = await _supabaseService
          .getPostsByUserId(prefs.getString("user_id") ?? '');
      if (mounted) {
        setState(() {
          _posts = postsData.map((data) => Post.fromJson(data)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ciutan Anda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPosts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPosts,
              child: _posts.isEmpty
                  ? const Center(
                      child: Text('Belum ada ciutan'),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      child: Text(
                                        post.author[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.author,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
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
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  post.content,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
