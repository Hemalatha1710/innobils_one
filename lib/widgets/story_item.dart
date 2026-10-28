import 'package:flutter/material.dart';

class StoryItem extends StatelessWidget {
  final String name;
  final bool isMine;
  const StoryItem({super.key, required this.name, this.isMine = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMine
                  ? null
                  : const LinearGradient(
                colors: [Colors.deepPurple, Colors.pink, Colors.orange],
              ),
              border: isMine ? Border.all(color: Colors.grey) : null,
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.deepPurple.shade50,
              child: isMine
                  ? const Icon(Icons.add, color: Colors.deepPurple)
                  : Text(name[0], style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
