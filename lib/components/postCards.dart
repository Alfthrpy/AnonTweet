import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import 'package:blog_anon/themes/colors.dart';

class PostCard extends StatefulWidget {
  final Post? post;
  final bool isDetailed;
  final bool hasReacted;
  final int reactionCount;
  final String profile_pic_link;
  final bool isCurrentUser;
  final VoidCallback onReaction;
  final VoidCallback? onEdit;

  const PostCard({
    Key? key,
    required this.post,
    this.isDetailed = false,
    required this.hasReacted,
    required this.reactionCount,
    required this.profile_pic_link,
    required this.isCurrentUser,
    required this.onReaction,
    this.onEdit,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
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
      color: widget.isCurrentUser ? baseColor : Colors.white,
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
                widget.profile_pic_link.isNotEmpty
                    ? CircleAvatar(
                        backgroundColor: tertiaryColor,
                        backgroundImage: NetworkImage(widget.profile_pic_link),
                        child: null,
                      )
                    : CircleAvatar(
                        backgroundColor: tertiaryColor,
                        child: Text(
                          widget.post!.author[0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
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
                          if (widget.isCurrentUser)
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
