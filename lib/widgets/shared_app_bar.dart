import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_session_provider.dart';
import '../features/notifications_screen.dart'; // Import the notifications screen
import '../providers/theme_provider.dart';
import '../features/settings_screen.dart'; // Import the settings screen
import '../services/notification_service.dart';
import '../services/firestore_notification_service.dart';

class SharedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String visitNumber;
  final VoidCallback? onNotificationPressed;
  final Widget? leadingWidget;
  final VoidCallback? onLeadingPressed;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarOpen;
  final bool isSimpleLayout;
  final bool isHomeScreen;
  final String? screenTitle;

  const SharedAppBar({
    Key? key,
    required this.visitNumber,
    this.onNotificationPressed,
    this.leadingWidget,
    this.onLeadingPressed,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
    this.isSimpleLayout = false,
    this.isHomeScreen = false,
    this.screenTitle,
  }) : super(key: key);

  @override
  _SharedAppBarState createState() => _SharedAppBarState();

  @override
  Size get preferredSize =>
      Size.fromHeight(isSimpleLayout ? (85.0 + 16.0) : (50.0 + 16.0));
}

class _SharedAppBarState extends State<SharedAppBar> {
  final NotificationService _notificationService = NotificationService();
  final FirestoreNotificationService _firestoreNotificationService =
      FirestoreNotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchUnreadCount();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUnreadCount();
  }

  @override
  void didUpdateWidget(SharedAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    if (!mounted) return;
    final userSession =
        Provider.of<UserSessionProvider>(context, listen: false);
    final clientNumber = userSession.clientNumber;

    if (clientNumber != null && clientNumber.isNotEmpty) {
      try {
        // Get unread count from both services
        final reportCount =
            await _notificationService.getUnreadNotificationCount(clientNumber);
        final firestoreCount = await _firestoreNotificationService.getUnreadCount(
            context); // Count unread notifications from notifications collection

        final totalCount = reportCount + firestoreCount;

        if (mounted) {
          setState(() {
            _unreadCount = totalCount;
          });
        }
      } catch (e) {
        print('Error fetching unread count for app bar: $e');
        if (mounted) {
          setState(() {
            _unreadCount = 0;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
        });
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}';
    }
    return name[0];
  }

  @override
  Widget build(BuildContext context) {
    final userSession =
        Provider.of<UserSessionProvider>(context, listen: false);
    final clientName = userSession.getClientName() ?? 'User';
    final initials = _getInitials(clientName);

    return Container(
      color: widget.isSimpleLayout ? const Color(0xFF7C4DFF) : Colors.white,
      padding: EdgeInsets.only(
        top: widget.isSimpleLayout ? (38.0 + 16.0) : (10.0 + 16.0),
        left: 16,
        right: 16,
        bottom: widget.isSimpleLayout ? 5 : 7,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0, top: 8.0),
                child: widget.isHomeScreen
                    ? Image.asset('assets/icon/new_Icon.png', height: 40)
                    : (widget.onSidebarToggle == null
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Color(0xFF7C4DFF)),
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context)
                                    .pushReplacementNamed('/home');
                              }
                            },
                          )
                        : const SizedBox()),
              ),
              if (widget.isSimpleLayout)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.leadingWidget != null)
                      InkWell(
                          onTap: widget.onLeadingPressed,
                          child: widget.leadingWidget),
                    if (widget.onSidebarToggle != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: IconButton(
                          icon: Icon(
                            widget.isSidebarOpen ? Icons.menu_open : Icons.menu,
                            color: const Color(0xFF7C4DFF),
                            size: 40,
                          ),
                          onPressed: widget.onSidebarToggle,
                          tooltip: 'Toggle Chat History',
                        ),
                      ),
                  ],
                )
              else if (widget.leadingWidget != null)
                InkWell(
                    onTap: widget.onLeadingPressed, child: widget.leadingWidget)
              else if (widget.onSidebarToggle != null)
                IconButton(
                  icon: Icon(
                      widget.isSidebarOpen ? Icons.menu_open : Icons.menu,
                      color: const Color(0xFF7C4DFF),
                      size: 32),
                  onPressed: widget.onSidebarToggle,
                  tooltip: 'Toggle Sidebar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (!widget.isHomeScreen && widget.screenTitle != null)
                Expanded(
                  child: Center(
                    child: Text(
                      widget.screenTitle!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              const Spacer(),
              if (widget.isSimpleLayout)
                const SizedBox(width: 40)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: Colors.black,
                              size: 24,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationsScreen(),
                                ),
                              );
                              // Force refresh the badge count after returning from notifications
                              await _fetchUnreadCount();
                            },
                            tooltip: 'Notifications',
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showUserMenu(context, clientName, initials),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (widget.isSimpleLayout)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                widget.visitNumber,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context, String clientName, String initials) {
    final userSession =
        Provider.of<UserSessionProvider>(context, listen: false);

    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000.0, 80.0, 0.0, 0.0),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF7C4DFF),
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userSession.clientNumber ?? 'No Client ID',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
          ),
        ),
      ],
      elevation: 8.0,
    ).then((String? value) async {
      if (value == null) return;
      if (!mounted) return;

      switch (value) {
        case 'settings':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
          break;
        case 'logout':
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          );
          if (shouldLogout == true) {
            try {
              await FirebaseAuth.instance.signOut();
              userSession.clearSession();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: $e')));
            }
          }
          break;
      }
    });
  }
}
