import 'package:blog_anon/services/profile_pic_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import 'package:blog_anon/themes/colors.dart';

class PostCard extends StatefulWidget {
  final Post? post;
  final bool isDetailed;
  final bool hasReacted;
  final int reactionCount;
  final VoidCallback onReaction;
  final VoidCallback? onEdit;

  const PostCard({
    Key? key,
    required this.post,
    this.isDetailed = false,
    required this.hasReacted,
    required this.reactionCount,
    required this.onReaction,
    this.onEdit,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isCurrentUser = false;
  String? _profilePicUrl;
  final profilePicService = ProfilePicService();

  @override
  void initState() {
    super.initState();
    _checkUserId();
    _loadProfilePic();
  }

  Future<void> _loadProfilePic() async {
    if (widget.post?.user_id != null) {
      final profilePicUrl =
          await profilePicService.getProfilePic(widget.post!.user_id);
      if (mounted) {
        setState(() {
          _profilePicUrl = profilePicUrl;
        });
      }
    }
  }

  Future<void> _checkUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');
    if (mounted) {
      setState(() {
        _isCurrentUser = currentUserId == widget.post?.user_id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.post == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(
        bottom: 16,
        left: widget.isDetailed ? 0 : 16,
        right: widget.isDetailed ? 0 : 16,
      ),
      color: _isCurrentUser ? baseColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: tertiaryColor,
                  backgroundImage: _profilePicUrl != null
                      ? NetworkImage(_profilePicUrl!)
                      : null,
                  child: _profilePicUrl == null
                      ? Text(
                          widget.post!.author[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.post!.author,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (_isCurrentUser)
                            Text(' (Anda)', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                      Text(
                        widget.post!.timestamp,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: widget.onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post!.content,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: widget.onReaction,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          widget.hasReacted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.hasReacted ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.reactionCount.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
