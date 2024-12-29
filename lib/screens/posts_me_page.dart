import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import for DateTime formatting and parsing
import 'package:timeago/timeago.dart' as timeago; // Import timeago package

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
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort desc
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

  bool canEditPost(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inMinutes <= 10;
  }

  Future<void> _editPost(Post post) async {
    TextEditingController controller = TextEditingController(text: post.content);
    final result = await showDialog<String>( 
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Cuitan'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Tulis cuitan baru',
            ),
            maxLines: null,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cuitan tidak boleh kosong')),
                  );
                  return;
                }
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _updatePost(post, result);
    }
  }

  Future<void> _updatePost(Post post, String newContent) async {
    try {
      await _supabaseService.updatePost(post.id.toString(), newContent);
      final updatedPosts = await _supabaseService.getPostsByUserId(
        (await SharedPreferences.getInstance()).getString("user_id") ?? '',
      );
      if (mounted) {
        setState(() {
          _posts = updatedPosts.map((data) => Post.fromJson(data)).toList();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuitan berhasil diperbarui')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  DateTime _parseTimestamp(String timestamp) {
    final now = DateTime.now();

    // Match relative time format like '0 menit yang lalu', '2 jam yang lalu'
    final regex = RegExp(r'(\d+)\s+(\w+)\s+yang\s+lalu');
    final match = regex.firstMatch(timestamp);

    if (match != null) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2);

      if (unit == 'menit') {
        return now.subtract(Duration(minutes: value));
      } else if (unit == 'jam') {
        return now.subtract(Duration(hours: value));
      } else if (unit == 'hari') {
        return now.subtract(Duration(days: value));
      }
    }

    // If no match, return current time (fallback)
    return now;
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
                        final createdAt = _parseTimestamp(post.timestamp);

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
                                    // Hanya tampilkan tombol edit jika cuitan bisa diedit
                                    if (canEditPost(createdAt))
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editPost(post),
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
