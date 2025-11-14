import 'package:flutter/material.dart';
import '../widgets/shared_app_bar.dart';
import '../screens/video_player_screen.dart';
import '../services/alarm_service.dart';
import 'package:flutter/services.dart';

class HealthVideosScreen extends StatelessWidget {
  const HealthVideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> videos = [
      {
        'title': 'Pregnancy Nutrition Guide',
        'author': 'Dr. Sarah Johnson',
        'videoId': 'dQw4w9WgXcQ', // Replace with actual video ID
      },
      {
        'title': 'Safe Exercises During Pregnancy',
        'author': 'Fitness Expert Maria',
        'videoId': 'dQw4w9WgXcQ', // Replace with actual video ID
      },
      {
        'title': 'Understanding Prenatal Care',
        'author': 'Dr. Michael Chen',
        'videoId': 'dQw4w9WgXcQ', // Replace with actual video ID
      },
      {
        'title': 'Mental Health During Pregnancy',
        'author': 'Dr. Lisa Thompson',
        'videoId': 'dQw4w9WgXcQ', // Replace with actual video ID
      },
      {
        'title': 'Preparing for Labor',
        'author': 'Midwife Emma Wilson',
        'videoId': 'dQw4w9WgXcQ', // Replace with actual video ID
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: SharedAppBar(
        visitNumber: 'Health Videos',
        onNotificationPressed: () {
          // Handle notification press
        },
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => VideoPlayerScreen(
                          videoId: video['videoId']!,
                          title: video['title']!,
                        ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      'https://img.youtube.com/vi/${video['videoId']}/maxresdefault.jpg',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error_outline, size: 50),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['title']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By ${video['author']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
