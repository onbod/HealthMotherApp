import 'package:flutter/material.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';
import 'health_videos_screen.dart';
import 'report_issue_intro_screen.dart';
import 'health_tips_screen.dart';
import 'nutrition_tips_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlobalNavigation(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: SharedAppBar(
          visitNumber: 'Resources',
          onNotificationPressed: () {
            // Handle notification press
          },
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Educational Resources Section
                _buildSection(
                  context,
                  'Educational Resources',
                  [
                    _buildResourceCard(
                      context,
                      'Health Tips',
                      'Daily health tips for mothers',
                      Icons.health_and_safety,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthTipsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildResourceCard(
                      context,
                      'Nutrition Tips',
                      'Healthy eating during pregnancy',
                      Icons.restaurant,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NutritionTipsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildResourceCard(
                      context,
                      'Health Videos',
                      'Educational videos for pregnant women',
                      Icons.video_library,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthVideosScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Healthcare Resources Section
                _buildSection(
                  context,
                  'Healthcare Resources',
                  [
                    _buildResourceCard(
                      context,
                      'Emergency Contacts',
                      'Important healthcare contacts',
                      Icons.phone,
                      () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.phone_in_talk_rounded,
                                          color: Colors.red, size: 32),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Emergency Contacts',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  ListTile(
                                    leading: Icon(Icons.local_phone,
                                        color: Colors.red),
                                    title:
                                        const Text('National Emergency Number'),
                                    subtitle: const Text('117'),
                                    trailing: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: const Icon(Icons.call),
                                      label: const Text('Call'),
                                      onPressed: () async {
                                        final url = Uri.parse('tel:117');
                                        // ignore: deprecated_member_use
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    _buildResourceCard(
                      context,
                      'Report an Issue',
                      'Report problems or suggest improvements',
                      Icons.bug_report,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ReportIssueIntroScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...cards,
      ],
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isEmergency = title == 'Emergency Contacts';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEmergency
                      ? Colors.red.withOpacity(0.1)
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      isEmergency ? Colors.red : Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEmergency ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
