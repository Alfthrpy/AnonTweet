// // lib/screens/posts_page.dart
// import 'package:blog_anon/components/postCards.dart';
// import 'package:flutter/material.dart';
// import '../models/post.dart';
// import '../services/posts_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class PostsMePage extends StatefulWidget {
//   const PostsMePage({Key? key}) : super(key: key);

//   @override
//   _PostsPageState createState() => _PostsPageState();
// }

// class _PostsPageState extends State<PostsMePage> {
//   final _postService = PostsService();
//   List<Post> _posts = [];
//   bool _isLoading = false;
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _loadPosts();
//     _setupRealtimeSubscription();
//   }

//   Future<void> _setupRealtimeSubscription() async {
//     _postService.client
//         .from('posts')
//         .stream(primaryKey: ['id'])
//         .eq('user_id',
//             (await SharedPreferences.getInstance()).getString("user_id") ?? '')
//         .listen((data) async {
//           if (mounted) {
//             final posts = await Future.wait(data.map((post) async {
//               final postObj = Post.fromJson(post);
//               postObj.reactionCount =
//                   await _postService.getReactionCount(post['id']);
//               return postObj;
//             }).toList());
//             setState(() {
//               _posts = posts
//                 ..sort(
//                     (a, b) => b.createdAt.compareTo(a.createdAt)); // Sort desc
//             });
//           }
//         });
//   }

//   Future<void> _loadPosts() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() => _isLoading = true);
//     try {
//       final postsData =
//           await _postService.getPostsByUserId(prefs.getString("user_id") ?? '');
//       if (mounted) {
//         setState(() {
//           _posts = postsData.map((data) => Post.fromJson(data)).toList();
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   Future<void> _refreshPosts() async {
//     await _loadPosts();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Ciutan Anda'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _refreshPosts,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: _refreshPosts,
//               child: _posts.isEmpty
//                   ? const Center(
//                       child: Text('Belum ada ciutan'),
//                     )
//                   : ListView.builder(
//                       itemCount: _posts.length,
//                       itemBuilder: (context, index) {
//                         return PostCard(
//                           post: _posts[index],
//                         );
//                       },
//                     ),
//             ),
//     );
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

// lib/screens/posts_page.dart
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
  Map<int, bool> _reactions = {}; // Menyimpan status like untuk setiap post
  Map<int, int> _reactionCounts =
      {}; // Menyimpan jumlah reaction untuk setiap post
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _postsPerPage = 10;

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
            setState(() {
              _posts = posts
                ..sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt)); // Sort desc
              _updateReactions(); // Update reactions state
            });
          }
        });
  }

  Future<void> _loadPosts({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    if (page == 1) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final postsData = await _postService.getPostsByUserId(
          prefs.getString("user_id") ?? '',
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
          _updateReactions(); // Update reactions state
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

  // Memperbarui status reactions untuk semua post
  Future<void> _updateReactions() async {
    for (var post in _posts) {
      final userId =
          (await SharedPreferences.getInstance()).getString("user_id") ?? '';
      final hasReacted = await _reactionService.hasReacted(post.id, userId);
      setState(() {
        _reactions[post.id] = hasReacted;
        _reactionCounts[post.id] = post.reactionCount ?? 0;
      });
    }
  }

  Future<void> _handleReaction(int postId) async {
    final userId =
        (await SharedPreferences.getInstance()).getString("user_id") ?? '';
    await _reactionService.toggleReaction(postId, 'like', userId);
    setState(() {
      _reactions[postId] = !_reactions[postId]!; // Toggle status
      if (_reactions[postId]!) {
        _reactionCounts[postId] = (_reactionCounts[postId] ?? 0) + 1;
      } else {
        _reactionCounts[postId] = (_reactionCounts[postId] ?? 0) - 1;
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _currentPage++;
      _loadPosts(page: _currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuitan Anda'),
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
                      itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _posts.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return PostCard(
                          post: _posts[index],
                          isDetailed: false,
                          hasReacted: _reactions[_posts[index].id] ?? false,
                          reactionCount: _reactionCounts[_posts[index].id] ?? 0,
                          onReaction: () => _handleReaction(_posts[index].id),
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _refreshPosts() async {
    _currentPage = 1;
    await _loadPosts(page: _currentPage);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
