import 'package:flutter/material.dart';

class FeedPost {
  final String name;
  final String caption;
  final MaterialColor color;
  int likes;
  bool liked;
  final List<String> comments;

  FeedPost({
    required this.name,
    required this.caption,
    required this.color,
    required this.likes,
    this.liked = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}

const List<String> storyNames = [
  'You', 'Arun', 'Priya', 'Rahul', 'Divya', 'Karthik',
  'Meena', 'Vikram', 'Sneha', 'Ravi', 'Anitha', 'Suresh',
];

const _names = [
  'Arun', 'Priya', 'Rahul', 'Divya', 'Karthik',
  'Meena', 'Vikram', 'Sneha', 'Ravi', 'Anitha',
];

const _captions = [
  'Enjoying my day!',
  'Beautiful memories ❤️',
  'Keep smiling 😊',
  'Coffee first, everything else later ☕',
  'Weekend vibes with the crew',
  'Learning Flutter one widget at a time',
  'Sunset never gets old 🌇',
  'Good food, good mood 🍛',
];

const List<MaterialColor> _colors = [
  Colors.deepPurple, Colors.teal, Colors.orange, Colors.pink,
  Colors.indigo, Colors.green, Colors.blueGrey, Colors.red,
];

List<FeedPost> generatePosts([int count = 15]) => List.generate(
  count,
      (i) => FeedPost(
    name: _names[i % _names.length],
    caption: _captions[i % _captions.length],
    color: _colors[i % _colors.length],
    likes: 8 + (i * 7) % 60,
  ),
);
