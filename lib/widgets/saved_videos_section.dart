import 'package:flutter/material.dart';

class VideoPlaceholder extends StatelessWidget {
  // You might want to pass video data here later (e.g., thumbnail, video ID)
  // final String thumbnailUrl;
  // final String videoId;
  final VoidCallback? onTap; // Add onTap callback

  const VideoPlaceholder({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Use the onTap callback
      child: Container(
        width: 200, // Adjust width for horizontal list item
        decoration: BoxDecoration(
          color: Colors.grey[300], // Placeholder background color
          borderRadius: BorderRadius.circular(8.0),
          // In a real app, you would use a DecorationImage with a video thumbnail:
          // image: DecorationImage(
          //   image: NetworkImage(thumbnailUrl),
          //   fit: BoxFit.cover,
          // ),
        ),
        child: Center(
          child: Icon(
            Icons.play_circle_fill, // Play button icon
            size: 50,
            color: Colors.white.withOpacity(0.8), // Semi-transparent white
          ),
        ),
      ),
    );
  }
}

class SavedVideosSection extends StatelessWidget {
  // Placeholder list of videos (just using null for placeholders)
  final List<dynamic> videos = List.generate(
    4,
    (index) => null,
  ); // Example: 4 placeholder videos

  SavedVideosSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ), // Padding for the title
          child: Text(
            'Saved Videos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 150, // Set a height for the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal, // Set to horizontal scrolling
            itemCount: videos.length,
            itemBuilder: (context, index) {
              // In a real app, you would build a VideoPlaceholder with actual video data
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16.0 : 0,
                  right: 16.0,
                ), // Add horizontal padding
                child: VideoPlaceholder(
                  onTap: () {
                    // Handle tap
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
