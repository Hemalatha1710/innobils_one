

import 'package:flutter/material.dart';
import 'package:innobils_one/screen/reels_screen.dart';
import 'package:share_plus/share_plus.dart';

import 'dynamic_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> posts = [
    {'name': 'Arun', 'caption': 'Enjoying my day!', 'likes': 12, 'liked': false},
    {'name': 'Priya', 'caption': 'Beautiful memories ❤️', 'likes': 25, 'liked': false},
    {'name': 'Rahul', 'caption': 'Keep smiling 😊', 'likes': 8, 'liked': false},
    {'name': 'Divya', 'caption': 'Coffee first, everything else later ☕', 'likes': 19, 'liked': false},
    {'name': 'Karthik', 'caption': 'Weekend vibes with the crew', 'likes': 31, 'liked': false},
    {'name': 'Meena', 'caption': 'Sunset never gets old 🌇', 'likes': 44, 'liked': false},
    {'name': 'Vikram', 'caption': 'Learning Flutter one widget at a time', 'likes': 16, 'liked': false},
    {'name': 'Sneha', 'caption': 'Good food, good mood 🍛', 'likes': 27, 'liked': false},
    {'name': 'Ravi', 'caption': 'Morning run done 🏃', 'likes': 10, 'liked': false},
    {'name': 'Anitha', 'caption': 'Trying something new today', 'likes': 22, 'liked': false},
  ];

  final List<String> stories = [
    'You',
    'Arun',
    'Priya',
    'Rahul',
    'Divya',
    'Karthik',
    'Meena',
    'Vikram',
    'Sneha',
    'Ravi',
  ];

  final Map<int, List<String>> comments = {};

  void addComment(int index, String comment) {
    if (comment.trim().isEmpty) return;

    setState(() {
      comments.putIfAbsent(index, () => []);
      comments[index]!.add(comment.trim());
    });
  }

  /// The dialog owns its TextEditingController (see _CommentDialog below),
  /// so there is no "controller used after being disposed" error.
  Future<void> showCommentDialog(int index) async {
    final comment = await showDialog<String>(
      context: context,
      builder: (_) => const _CommentDialog(),
    );

    if (comment != null) addComment(index, comment);
  }

  Future<void> sharePost(Map<String, dynamic> post) async {
    final String shareText = '${post['name']}: ${post['caption']}';

    try {
      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share. Please try again.')),
      );
      debugPrint('Share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library),
            tooltip: 'Reels',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReelsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.dynamic_form),
            tooltip: 'Dynamic Form',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DynamicFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Stories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _UserAvatar(name: stories[index], radius: 28),
                      const SizedBox(height: 5),
                      Text(stories[index]),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Posts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          ...posts.asMap().entries.map((entry) {
            final index = entry.key;
            final post = entry.value;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _UserAvatar(name: post['name'], radius: 20),
                        const SizedBox(width: 10),
                        Text(
                          post['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(post['caption'], style: const TextStyle(fontSize: 16)),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              posts[index]['liked'] = !posts[index]['liked'];
                              posts[index]['likes'] +=
                              posts[index]['liked'] ? 1 : -1;
                            });
                          },
                          icon: Icon(
                            post['liked']
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: post['liked'] ? Colors.red : Colors.grey,
                          ),
                        ),
                        Text('${post['likes']} likes'),
                        const Spacer(),
                        IconButton(
                          onPressed: () => showCommentDialog(index),
                          icon: const Icon(Icons.comment_outlined),
                        ),
                        Text('${comments[index]?.length ?? 0}'),
                        IconButton(
                          onPressed: () => sharePost(post),
                          icon: const Icon(Icons.share_outlined),
                        ),
                      ],
                    ),

                    // Comments below the post
                    ...((comments[index] ?? []).map(
                          (comment) => Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          top: 6,
                          bottom: 6,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.account_circle, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(comment)),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Profile photo ids (from pravatar.cc) for each name
const Map<String, int> _avatarIds = {
  'Arun': 12,
  'Priya': 5,
  'Rahul': 15,
  'Divya': 47,
  'Karthik': 33,
  'Meena': 20,
  'Vikram': 51,
  'Sneha': 9,
  'Ravi': 60,
  'Anitha': 25,
};

/// Small round profile image. Falls back to the first letter when the
/// image is loading, offline, or the name has no photo ("You").
class _UserAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const _UserAvatar({required this.name, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.deepPurple.shade100,
      child: name == 'You'
          ? Icon(Icons.add, size: radius, color: Colors.deepPurple)
          : Text(name[0], style: TextStyle(fontSize: radius * 0.8)),
    );

    final id = _avatarIds[name];
    if (id == null) return fallback;

    return ClipOval(
      child: Image.network(
        'https://i.pravatar.cc/150?img=$id',
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) =>
        progress == null ? child : fallback,
      ),
    );
  }
}

/// Comment dialog with its own controller lifecycle.
class _CommentDialog extends StatefulWidget {
  const _CommentDialog();

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    // Runs only after the dialog has fully closed, so it is safe.
    _controller.dispose();
    super.dispose();
  }

  void _post() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Comment'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _post(),
        decoration: const InputDecoration(
          hintText: 'Write your comment...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _post,
          child: const Text('Post'),
        ),
      ],
    );
  }
}