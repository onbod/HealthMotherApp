import 'package:flutter/material.dart';
import '../widgets/shared_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';

class NutritionTipsScreen extends StatefulWidget {
  const NutritionTipsScreen({super.key});

  @override
  State<NutritionTipsScreen> createState() => _NutritionTipsScreenState();
}

class _NutritionTipsScreenState extends State<NutritionTipsScreen> {
  List<NutritionTip> nutritionTips = [];
  String selectedCategory = 'All';
  int presentWeek = 20; // Will be set from session
  Set<String> readTips = {}; // Track read tips by title

  @override
  void initState() {
    super.initState();
    fetchNutritionTips();
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

  Future<void> fetchNutritionTips() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('nutrition-tips').get();
    print(
      'Fetched nutrition tips: \n${snapshot.docs.map((d) => d.data().toString()).join("\n")}',
    );
    setState(() {
      nutritionTips =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return NutritionTip(
              title: data['title'] ?? '',
              description: data['description'] ?? data['content'] ?? '',
              category: data['category'] ?? '',
              categoryType: data['categoryType'] ?? '',
              icon: Icons.spa, // Default icon, or map if you store icon info
              color:
                  Colors.green, // Default color, or map if you store color info
              details: data['details'] ?? data['content'] ?? '',
              weeks: data['weeks'] ?? '',
            );
          }).toList();
    });
  }

  List<NutritionTip> getTipsForCategory(String categoryType, int presentWeek) {
    final tips =
        nutritionTips
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
    NutritionTip? presentTip;
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
    final result = <NutritionTip>[];
    if (presentTip != null) result.add(presentTip);
    result.addAll(last4Tips);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: SharedAppBar(
        visitNumber: 'Nutrition Tips',
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
                _buildCategoryChip('Pregnancy Nutrition'),
                _buildCategoryChip('Snacks'),
                _buildCategoryChip('Safety'),
              ],
            ),
          ),

          // Nutrition Tips List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount:
                  selectedCategory == 'All'
                      ? nutritionTips.length
                      : getTipsForCategory(
                        selectedCategory,
                        presentWeek,
                      ).length,
              itemBuilder: (context, index) {
                final List<NutritionTip> filteredTips =
                    selectedCategory == 'All'
                        ? nutritionTips
                        : getTipsForCategory(selectedCategory, presentWeek);
                final tip = filteredTips[index];
                return _buildNutritionTipCard(tip);
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

  Widget _buildNutritionTipCard(NutritionTip tip) {
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
                        child: const Text('View Details'),
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

  void _showTipDetails(NutritionTip tip) {
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
                        Text(
                          tip.details,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),
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

class NutritionTip {
  final String title;
  final String description;
  final String category;
  final String categoryType;
  final IconData icon;
  final Color color;
  final String details;
  final String weeks;

  NutritionTip({
    required this.title,
    required this.description,
    required this.category,
    required this.categoryType,
    required this.icon,
    required this.color,
    required this.details,
    required this.weeks,
  });
}
