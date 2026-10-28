import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';


import '../service/feed_data.dart';
import 'command_dialog.dart';


/// Reusable post widget. State lives in [FeedPost], so it survives scrolling.
class PostCard extends StatefulWidget {
  final FeedPost post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  FeedPost get post => widget.post;

  void _toggleLike() {
    setState(() {
      post.liked = !post.liked;
      post.likes += post.liked ? 1 : -1;
    });
  }

  Future<void> _addComment() async {
    final text = await showAddCommentDialog(context);
    if (text != null && mounted) {
      setState(() => post.comments.add(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(post.name[0])),
            title: Text(post.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.more_horiz),
          ),
          // Image placeholder (no network needed)
          GestureDetector(
            onDoubleTap: () {
              if (!post.liked) _toggleLike();
            },
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [post.color.shade300, post.color.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.photo_camera_outlined,
                  size: 56, color: Colors.white70),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(post.caption, style: const TextStyle(fontSize: 16)),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _toggleLike,
                icon: Icon(
                  post.liked ? Icons.favorite : Icons.favorite_border,
                  color: post.liked ? Colors.red : Colors.grey,
                ),
              ),
              Text('${post.likes} likes'),
              const Spacer(),
              IconButton(
                onPressed: _addComment,
                icon: const Icon(Icons.comment_outlined),
              ),
              Text('${post.comments.length}'),
              IconButton(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: '${post.name}: ${post.caption}'),
                ),
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
          for (final c in post.comments)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
