import 'package:flutter/material.dart';

/// Shows an "Add Comment" dialog and returns the text (or null if cancelled).
/// The TextEditingController lives inside the dialog's own State, so it is
/// disposed only after the dialog's closing animation has finished.
Future<String?> showAddCommentDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _CommentDialog(),
  );
}

class _CommentDialog extends StatefulWidget {
  const _CommentDialog();

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
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
        ElevatedButton(onPressed: _post, child: const Text('Post')),
      ],
    );
  }
}
