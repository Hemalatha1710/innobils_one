import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../service/auth_service.dart';
import '../service/db_data.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  // Discovered at runtime from the bundled assets (first five .mp4 files),
  // so the folder name can never get out of sync with the code.
  List<String> videos = [];

  final PageController pageController = PageController();

  String userId = 'guest';
  String userName = 'User';

  Set<int> liked = {};
  Map<int, int> likeCounts = {};
  Map<int, int> commentCounts = {};

  VideoPlayerController? currentController;
  int currentIndex = 0;
  String? videoError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await AuthService().currentUser();
    userId = user?['mobile'] ?? 'guest';
    userName = user?['name'] ?? 'User';
    await _refreshCounts();

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final found = manifest
        .listAssets()
        .where((a) => a.toLowerCase().endsWith('.mp4'))
        .toList()
      ..sort();
    debugPrint('REEL ASSETS FOUND: $found');
    if (!mounted) return;

    if (found.isEmpty) {
      setState(() => videoError =
      'No .mp4 files are bundled in the app.\n'
          'Check the assets folder and the assets: section in pubspec.yaml, '
          'then run flutter clean and run again.');
      return;
    }
    setState(() => videos = found.take(5).toList());
    await _loadVideo(0);
  }

  /// Reload likes/comments from the local database.
  Future<void> _refreshCounts() async {
    final l = await ReelDb.likedBy(userId);
    final lc = await ReelDb.likeCounts();
    final cc = await ReelDb.commentCounts();
    if (!mounted) return;
    setState(() {
      liked = l;
      likeCounts = lc;
      commentCounts = cc;
    });
  }

  Future<void> _loadVideo(int index) async {
    final oldController = currentController;
    currentController = null;
    videoError = null;
    await oldController?.dispose();
    if (!mounted) return;
    setState(() {});

    if (index >= videos.length) return;
    final controller = VideoPlayerController.asset(videos[index]);
    currentController = controller;

    try {
      await controller.initialize();
      // User may have scrolled again while loading.
      if (!mounted || currentController != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      setState(() {});
      await controller.play();
    } catch (e) {
      debugPrint('VIDEO ERROR: $e');
      if (mounted && currentController == controller) {
        setState(() => videoError = '${videos[index]}\n$e');
      }
    }
  }

  Future<void> _toggleLike(int index) async {
    final nowLiked = !liked.contains(index);
    // Update UI first, then persist.
    setState(() {
      if (nowLiked) {
        liked.add(index);
      } else {
        liked.remove(index);
      }
      final count = (likeCounts[index] ?? 0) + (nowLiked ? 1 : -1);
      likeCounts[index] = count < 0 ? 0 : count;
    });
    await ReelDb.setLike(userId, index, nowLiked);
  }

  Future<void> _share(int index) async {
    await SharePlus.instance.share(
      ShareParams(text: 'Check out Reel ${index + 1} on Connect!'),
    );
  }

  void _showComments(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(
        reelId: index,
        userId: userId,
        userName: userName,
        onChanged: _refreshCounts,
      ),
    );
  }

  @override
  void dispose() {
    currentController?.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Reels'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: videos.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: videoError != null
              ? Text(videoError!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center)
              : const CircularProgressIndicator(color: Colors.white),
        ),
      )
          : PageView.builder(
        controller: pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        onPageChanged: (index) {
          setState(() => currentIndex = index);
          _loadVideo(index);
        },
        itemBuilder: (context, index) {
          final controller = index == currentIndex ? currentController : null;
          final isLiked = liked.contains(index);

          return Stack(
            alignment: Alignment.center,
            children: [
              if (controller != null && controller.value.isInitialized)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    });
                  },
                  onDoubleTap: () {
                    if (!isLiked) _toggleLike(index);
                  },
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                )
              else if (index == currentIndex && videoError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Video failed to load:\n$videoError',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              if (controller != null &&
                  controller.value.isInitialized &&
                  !controller.value.isPlaying)
                const IgnorePointer(
                  child: Icon(Icons.play_arrow, size: 70, color: Colors.white70),
                ),

              Positioned(
                right: 12,
                bottom: 90,
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () => _toggleLike(index),
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 34,
                      ),
                    ),
                    Text('${likeCounts[index] ?? 0}',
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 20),
                    IconButton(
                      onPressed: () => _showComments(index),
                      icon: const Icon(Icons.comment,
                          color: Colors.white, size: 32),
                    ),
                    Text('${commentCounts[index] ?? 0}',
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 20),
                    IconButton(
                      onPressed: () => _share(index),
                      icon: const Icon(Icons.share,
                          color: Colors.white, size: 32),
                    ),
                    const Text('Share',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),

              Positioned(
                left: 16,
                bottom: 30,
                child: Text(
                  'Reel ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final int reelId;
  final String userId;
  final String userName;
  final Future<void> Function() onChanged;

  const _CommentsSheet({
    required this.reelId,
    required this.userId,
    required this.userName,
    required this.onChanged,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController controller = TextEditingController();
  List<Map<String, Object?>> comments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await ReelDb.comments(widget.reelId);
    if (!mounted) return;
    setState(() {
      comments = list;
      loading = false;
    });
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    controller.clear();
    await ReelDb.addComment(
        widget.reelId, widget.userId, widget.userName, text);
    await _load();
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: 350,
        child: Column(
          children: [
            const Text('Comments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : comments.isEmpty
                  ? const Center(child: Text('No comments yet'))
                  : ListView(
                children: comments
                    .map((c) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(c['user_name'] as String),
                  subtitle: Text(c['text'] as String),
                ))
                    .toList(),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration:
                    const InputDecoration(hintText: 'Write a comment...'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ],
        ),
      ),
    );
  }
}