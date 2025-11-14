import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/health_tips_screen.dart';

class HealthTipsCarousel extends StatelessWidget {
  const HealthTipsCarousel({super.key});

  Future<List<HealthTip>> _fetchHealthTips() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('health-tips').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return HealthTip(
        title: data['title'] ?? '',
        description: data['description'] ?? data['content'] ?? '',
        icon: Icons.water_drop, // Default icon, or map if you store icon info
        color: Colors.blue, // Default color, or map if you store color info
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthTipsScreen(),
                    ),
                  );
                },
                child: Text('View All', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<HealthTip>>(
            future: _fetchHealthTips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Failed to load health tips'));
              }
              final healthTips = snapshot.data ?? [];
              if (healthTips.isEmpty) {
                return Center(child: Text('No health tips available'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: healthTips.length,
                itemBuilder: (context, index) {
                  final tip = healthTips[index];
                  final screenWidth = MediaQuery.of(context).size.width;
                  final cardWidth =
                      screenWidth < 340
                          ? screenWidth - 32
                          : (screenWidth < 400 ? screenWidth - 48 : 280);
                  return Container(
                    width:
                        (cardWidth > 320 ? 320 : cardWidth)
                            .toDouble(), // max 320, min responsive
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: InkWell(
                        onTap: () {
                          _showTipDetails(context, tip);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12), // Reduced from 16
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      6,
                                    ), // Reduced from 8
                                    decoration: BoxDecoration(
                                      color: tip.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      tip.icon,
                                      color: tip.color,
                                      size: 20, // Reduced from 24
                                    ),
                                  ),
                                  const SizedBox(width: 8), // Reduced from 12
                                  Expanded(
                                    child: Text(
                                      tip.title,
                                      style: const TextStyle(
                                        fontSize: 14, // Reduced from 16
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // Reduced from 12
                              Expanded(
                                // Added Expanded to prevent overflow
                                child: Text(
                                  tip.description,
                                  style: TextStyle(
                                    fontSize: 13, // Reduced from 14
                                    color: Colors.grey[700],
                                    height: 1.3, // Reduced from 1.4
                                  ),
                                  maxLines: 3, // Reduced from 4
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8), // Reduced from 12
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      _showTipDetails(context, tip);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ), // Reduced padding
                                      minimumSize:
                                          Size.zero, // Allow button to be smaller
                                      tapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap, // Reduce tap target
                                    ),
                                    child: Text(
                                      'Read More',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 12, // Reduced font size
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTipDetails(BuildContext context, HealthTip tip) {
    final primaryColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tip.color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(tip.icon, color: tip.color, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          tip.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Text(
                        tip.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class HealthTip {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  HealthTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
