import 'package:flutter/material.dart';

/// MediaScreen - Screen for managing media, images, and presentation slides
/// Users can upload and organize their media files here
class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Page title
          const Text(
            'Media & Slides',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Description of what this page does
          const Text(
            'Manage your images, videos, and presentation slides here',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 40),

          // Placeholder container for future media content
          Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              // Show message that content is coming soon
              child: Text('Media content coming soon!'),
            ),
          ),
        ],
      ),
    );
  }
}
