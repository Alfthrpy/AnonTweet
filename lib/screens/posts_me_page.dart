// lib/screens/posts_page.dart
import 'package:blog_anon/themes/colors.dart';
import 'package:blog_anon/components/postCards.dart';
import 'package:blog_anon/services/reactions_service.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/posts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostsMePage extends StatefulWidget {
  const PostsMePage({Key? key}) : super(key: key);

  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsMePage> {
  final _postService = PostsService();
  final _reactionService = ReactionService();
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  Map<int, bool> _reactions = {};
  Map<int, int> _reactionCounts = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _postsPerPage = 10;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _setupRealtimeSubscription();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _setupRealtimeSubscription() async {
    _postService.client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('user_id',
            (await SharedPreferences.getInstance()).getString("user_id") ?? '')
        .listen((data) async {
          if (mounted) {
            final posts = await Future.wait(data.map((post) async {
              final postObj = Post.fromJson(post);
              postObj.reactionCount =
                  await _postService.getReactionCount(post['id']);
              return postObj;
            }).toList());
            if (mounted) {
              setState(() {
                _posts = posts
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                _updateReactions();
                _filterPosts();
              });
            }
          }
        });
  }

  Future<void> _loadPosts({int page = 1}) async {
    if (mounted) {
      if (page == 1) {
        setState(() => _isLoading = true);
      } else {
        setState(() => _isLoadingMore = true);
      }
    }
    try {
      final postsData = await _postService.getPostsByUserId(
          (await SharedPreferences.getInstance()).getString("user_id") ?? '',
          limit: _postsPerPage,
          offset: (page - 1) * _postsPerPage);
      if (mounted) {
        setState(() {
          if (page == 1) {
            _posts = postsData.map((data) => Post.fromJson(data)).toList();
          } else {
            _posts
                .addAll(postsData.map((data) => Post.fromJson(data)).toList());
          }
          _updateReactions();
          _filterPosts();
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
        if (page == 1) {
          setState(() => _isLoading = false);
        } else {
          setState(() => _isLoadingMore = false);
        }
      }
    }
  }

  bool canEditPost(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inMinutes <= 10;
  }

  Future<void> _editPost(Post post) async {
    TextEditingController controller =
        TextEditingController(text: post.content);
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
      await _postService.updatePost(post.id.toString(), newContent);
      final updatedPosts = await _postService.getPostsByUserId(
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
      _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateReactions() async {
    for (var post in _posts) {
      final userId =
          (await SharedPreferences.getInstance()).getString("user_id") ?? '';
      final hasReacted = await _reactionService.hasReacted(post.id, userId);
      if (mounted) {
        setState(() {
          _reactions[post.id] = hasReacted;
          _reactionCounts[post.id] = post.reactionCount ?? 0;
        });
      }
    }
  }

  void _filterPosts() {
    if (mounted) {
      setState(() {
        if (_searchQuery.isEmpty) {
          _filteredPosts = List.from(_posts);
        } else {
          _filteredPosts = _posts.where((post) {
            return post.author
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                post.content.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }
      });
    }
  }

  Future<void> _handleReaction(int postId) async {
    final userId =
        (await SharedPreferences.getInstance()).getString("user_id") ?? '';
    await _reactionService.toggleReaction(postId, 'like', userId);
    if (mounted) {
      setState(() {
        _reactions[postId] = !_reactions[postId]!;
        if (_reactions[postId]!) {
          _reactionCounts[postId] = (_reactionCounts[postId] ?? 0) + 1;
        } else {
          _reactionCounts[postId] = (_reactionCounts[postId] ?? 0) - 1;
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _currentPage++;
      _loadPosts(page: _currentPage);
    }
  }

  Future<void> _refreshPosts() async {
    _currentPage = 1;
    await _loadPosts(page: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuitan Anda',
            style: TextStyle(fontWeight: FontWeight.bold, color: baseColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPosts,
          ),
        ],
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              height: 40,
              width: 300,
              child: TextField(
                onChanged: (value) {
                  _searchQuery = value;
                  _filterPosts();
                },
                decoration: const InputDecoration(
                  hintText: 'Cari Cuitan...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshPosts,
                    child: _filteredPosts.isEmpty
                        ? const Center(
                            child: Text('Belum ada Cuitan'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredPosts.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _filteredPosts.length) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              return PostCard(
                                post: _filteredPosts[index],
                                isDetailed: false,
                                hasReacted:
                                    _reactions[_filteredPosts[index].id] ??
                                        false,
                                reactionCount:
                                    _reactionCounts[_filteredPosts[index].id] ??
                                        0,
                                onReaction: () =>
                                    _handleReaction(_filteredPosts[index].id),
                                onEdit:
                                    canEditPost(_filteredPosts[index].createdAt)
                                        ? () => _editPost(_filteredPosts[index])
                                        : null,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
