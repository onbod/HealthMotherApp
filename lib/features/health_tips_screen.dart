import 'package:flutter/material.dart';
import '../widgets/shared_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  List<HealthTip> healthTips = [];
  String selectedCategory = 'All';
  int presentWeek = 20;
  Set<String> readTips = {}; // Track read tips by title

  @override
  void initState() {
    super.initState();
    // presentWeek will be set in didChangeDependencies
    fetchHealthTips();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userSession = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );
    final week = userSession.calculateCurrentWeekFromLatestANC();
    if (week != presentWeek) {
      setState(() {
        presentWeek = week;
      });
    }
  }

  Future<void> fetchHealthTips() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('health-tips').get();
    print('Fetched health tips:');
    for (var doc in snapshot.docs) {
      print(doc.data());
    }
    setState(() {
      healthTips =
          snapshot.docs.map((doc) {
            final data = doc.data();
            print('categoryType: ${data['categoryType'] ?? ''}');
            return HealthTip(
              title: data['title'] ?? '',
              description: data['description'] ?? data['content'] ?? '',
              category: data['category'] ?? '',
              categoryType: data['categoryType'] ?? '',
              icon:
                  Icons
                      .water_drop, // Default icon, or map if you store icon info
              color:
                  Colors.blue, // Default color, or map if you store color info
              weeks: data['weeks'] ?? '',
            );
          }).toList();
    });
  }

  List<HealthTip> getTipsForCategory(String categoryType, int presentWeek) {
    final tips =
        healthTips
            .where(
              (tip) =>
                  (tip.categoryType ?? '').trim().toLowerCase() ==
                      categoryType.trim().toLowerCase() &&
                  int.tryParse(tip.weeks.toString()) != null,
            )
            .toList();
    tips.sort(
      (a, b) => int.parse(
        b.weeks.toString(),
      ).compareTo(int.parse(a.weeks.toString())),
    );
    HealthTip? presentTip;
    try {
      presentTip = tips.firstWhere(
        (tip) => int.tryParse(tip.weeks.toString()) == presentWeek,
      );
    } catch (_) {
      presentTip = null;
    }
    final last4Tips =
        tips
            .where(
              (tip) =>
                  int.tryParse(tip.weeks.toString()) != presentWeek &&
                  int.tryParse(tip.weeks.toString())! < presentWeek,
            )
            .take(4)
            .toList();
    final result = <HealthTip>[];
    if (presentTip != null) result.add(presentTip);
    result.addAll(last4Tips);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: SharedAppBar(
        visitNumber: 'Health Tips',
        onNotificationPressed: () {
          // Handle notification press
        },
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('General Health'),
                _buildCategoryChip('Physical Health'),
                _buildCategoryChip('Mental Health'),
              ],
            ),
          ),

          // Health Tips List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount:
                  selectedCategory == 'All'
                      ? healthTips.length
                      : getTipsForCategory(
                        selectedCategory,
                        presentWeek,
                      ).length,
              itemBuilder: (context, index) {
                final List<HealthTip> filteredTips =
                    selectedCategory == 'All'
                        ? healthTips
                        : getTipsForCategory(selectedCategory, presentWeek);
                final tip = filteredTips[index];
                return _buildHealthTipCard(tip);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = category == selectedCategory;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(category),
        onSelected: (selected) {
          setState(() {
            selectedCategory = category;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildHealthTipCard(HealthTip tip) {
    final isRead = readTips.contains(tip.title);
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                readTips.add(tip.title);
              });
              _showTipDetails(tip);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tip.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(tip.icon, color: tip.color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tip.categoryType,
                              style: TextStyle(
                                fontSize: 14,
                                color: tip.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tip.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            readTips.add(tip.title);
                          });
                          _showTipDetails(tip);
                        },
                        child: const Text('Read More'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isRead)
          Positioned(
            top: 12,
            right: 20,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(0xFF1877F2), // Facebook blue
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  void _showTipDetails(HealthTip tip) {
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
                      Icon(tip.icon, color: tip.color, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              tip.category,
                              style: TextStyle(
                                fontSize: 16,
                                color: tip.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        // Additional content can be added here
                      ],
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
  final String category;
  final String categoryType;
  final IconData icon;
  final Color color;
  final String weeks;

  HealthTip({
    required this.title,
    required this.description,
    required this.category,
    required this.categoryType,
    required this.icon,
    required this.color,
    required this.weeks,
  });
}
