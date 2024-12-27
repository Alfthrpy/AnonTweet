// lib/widgets/post_card.dart
import 'package:blog_anon/services/reactions_service.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isDetailed;

  const PostCard({
    Key? key,
    required this.post,
    this.isDetailed = false,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _reactionService = ReactionService();
  bool _hasReacted = false;
  int _reactionCount = 0;

  @override
  void initState() {
    super.initState();
    _checkReaction();
    _reactionCount = widget.post.reactionCount ?? 0;
  }

  Future<void> _checkReaction() async {
    final hasReacted = await _reactionService.hasReacted(widget.post.id,
        (await SharedPreferences.getInstance()).getString("user_id") ?? '');
    if (mounted) {
      setState(() => _hasReacted = hasReacted);
    }
  }

  Future<void> _handleReaction() async {
    await _reactionService.toggleReaction(widget.post.id, 'like',
        (await SharedPreferences.getInstance()).getString("user_id") ?? '');
    setState(() {
      _hasReacted = !_hasReacted;
      _reactionCount += _hasReacted ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(
        bottom: 16,
        left: widget.isDetailed ? 0 : 16,
        right: widget.isDetailed ? 0 : 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    widget.post.author[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.author,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        widget.post.timestamp,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: widget.isDetailed ? null : 3,
              overflow: widget.isDetailed ? null : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: _handleReaction,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          _hasReacted ? Icons.favorite : Icons.favorite_border,
                          color: _hasReacted ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _reactionCount.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!widget.isDetailed) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Navigate to detail page
                    },
                    child: const Text('Lihat Detail'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
