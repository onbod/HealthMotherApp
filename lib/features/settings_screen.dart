import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'notifications_screen.dart';
import 'password_management_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pin_lock_screen.dart';
import '../auth/login_screen.dart';
import 'pin_verification_screen.dart';
import 'pin_setup_screen.dart';
import '../providers/user_session_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color primaryColor = const Color(0xFF7C4DFF);
  bool _notificationsEnabled = true;
  bool _hasPassword = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPassword();
  }

  Future<void> _checkExistingPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final pinSetupCompleted = prefs.getBool('pin_setup_completed') ?? false;
    final hasPin = prefs.getString('user_pin') != null;

    setState(() {
      _hasPassword = pinSetupCompleted && hasPin;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error signing out')));
      }
    }
  }

  void _showPasswordManagementOptions() {
    if (!_hasPassword) {
      // If no password exists, directly navigate to add password screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PinLockScreen()),
      );
      return;
    }

    // If password exists, show options to change or delete
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (BuildContext bottomSheetContext) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change PIN'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    debugPrint('Opening PIN lock screen for verification');
                    // First verify the current PIN using PinLockScreen
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const PinLockScreen(isChangingPin: true),
                      ),
                    );
                    debugPrint('PIN lock screen result: $result');
                    if (result == true && mounted) {
                      debugPrint('Opening PIN setup screen for new PIN');
                      // If verification successful, show PIN setup screen for new PIN
                      if (mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const PinSetupScreen(isChangingPin: true),
                          ),
                        );
                        debugPrint('Returned from PIN setup screen');
                        _checkExistingPassword();
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete PIN',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    // First verify the current PIN using PinLockScreen
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const PinLockScreen(isDeletingPin: true),
                      ),
                    );
                    if (result == true) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('user_pin');
                      await prefs.setBool('pin_setup_completed', false);
                      if (mounted) {
                        setState(() {
                          _hasPassword = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PIN deleted successfully'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userSession = Provider.of<UserSessionProvider>(context);
    final clientName = userSession.getClientName() ?? 'User';
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return GlobalNavigation(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: SharedAppBar(
          visitNumber: 'Settings',
          onNotificationPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            clientName.isNotEmpty
                                ? clientName
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .take(2)
                                    .join()
                                    .toUpperCase()
                                : '',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: primaryColor),
                        onPressed: () {
                          // Handle edit profile
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Section
                _buildSectionTitle('Account'),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: _hasPassword ? 'Change Password' : 'Set Password',
                      onTap: _showPasswordManagementOptions,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: _handleLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Preferences Section
                _buildSectionTitle('Preferences'),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                        activeColor: primaryColor,
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
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56, endIndent: 16);
  }
}
