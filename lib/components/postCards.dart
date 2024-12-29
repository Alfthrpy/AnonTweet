import 'package:flutter/material.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post? post;
  final bool isDetailed;
  final bool hasReacted; // Status apakah user sudah memberi reaksi
  final int reactionCount; // Jumlah reaksi pada postingan
  final VoidCallback onReaction; // Callback untuk menangani perubahan reaksi
  final VoidCallback? onEdit;

  const PostCard(
      {Key? key,
      required this.post,
      this.isDetailed = false,
      required this.hasReacted,
      required this.reactionCount,
      required this.onReaction,
      this.onEdit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(
        bottom: 16,
        left: isDetailed ? 0 : 16,
        right: isDetailed ? 0 : 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian header dengan avatar dan info penulis
            Row(
              children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                post!.author[0].toUpperCase(),
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
                  post!.author,
                  style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  ),
                  Text(
                  post!.timestamp,
                  style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                icon: Icon(Icons.edit),
                onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bagian konten postingan
            Text(
              post!.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // Bagian reaksi (like) dan jumlah reaksi
            Row(
              children: [
                InkWell(
                  onTap: onReaction, // Menangani perubahan reaksi ketika di-tap
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          hasReacted ? Icons.favorite : Icons.favorite_border,
                          color: hasReacted ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reactionCount.toString(),
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
