import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_session_provider.dart';
import '../features/notifications_screen.dart'; // Import the notifications screen
import '../features/settings_screen.dart'; // Import the settings screen
import '../services/notification_service.dart';
import '../services/backend_notification_service.dart';

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
    super.key,
    required this.visitNumber,
    this.onNotificationPressed,
    this.leadingWidget,
    this.onLeadingPressed,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
    this.isSimpleLayout = false,
    this.isHomeScreen = false,
    this.screenTitle,
  });

  @override
  _SharedAppBarState createState() => _SharedAppBarState();

  @override
  Size get preferredSize =>
      Size.fromHeight(isSimpleLayout ? (85.0 + 16.0) : (50.0 + 18.0));
}

class _SharedAppBarState extends State<SharedAppBar> {
  final NotificationService _notificationService = NotificationService();
  final BackendNotificationService _backendNotificationService =
      BackendNotificationService();
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
    // Use post-frame callback to ensure Provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchUnreadCount();
      }
    });
  }

  @override
  void didUpdateWidget(SharedAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Use post-frame callback to ensure Provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchUnreadCount();
      }
    });
  }

  Future<void> _fetchUnreadCount() async {
    if (!mounted) return;
    try {
      // Add a small delay to ensure Provider context is available
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      
      final userSession = Provider.of<UserSessionProvider>(
        context,
        listen: false,
      );
      // Prefer schema's patient.identifier when clientNumber is not available
      final clientNumber =
          userSession.clientNumber ?? userSession.patient?['identifier'];

      if (clientNumber != null && clientNumber.isNotEmpty) {
        try {
          // Get unread count from both services
          final reportCount = await _notificationService
              .getUnreadNotificationCount(clientNumber);
          // Get unread count from backend notifications
          final backendCount = await _backendNotificationService.getUnreadCount();

          final totalCount = reportCount + backendCount;

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
    } catch (e) {
      print('Error accessing Provider in SharedAppBar: $e');
      if (mounted) {
        setState(() {
          _unreadCount = 0;
        });
      }
    }
  }

  String _getInitials(UserSessionProvider userSession) {
    // First, try to get first_name and last_name directly from patient data
    final firstName = userSession.patient?['first_name'];
    final lastName = userSession.patient?['last_name'];
    
    if (firstName != null && lastName != null && 
        firstName.toString().isNotEmpty && lastName.toString().isNotEmpty) {
      return '${firstName.toString()[0].toUpperCase()}${lastName.toString()[0].toUpperCase()}';
    }
    
    // Fallback to parsing getClientName()
    final clientName = userSession.getClientName();
    if (clientName != null && clientName.isNotEmpty) {
      final nameParts = clientName.trim().split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0].toUpperCase()}${nameParts[1][0].toUpperCase()}';
      }
      if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
        return nameParts[0][0].toUpperCase();
      }
    }
    
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final userSession = Provider.of<UserSessionProvider>(
      context,
      listen: true, // Changed to true to rebuild when user session data changes
    );
    // Get first name for dropdown display
    final firstName = userSession.patient?['first_name']?.toString().trim();
    final displayName = firstName != null && firstName.isNotEmpty
        ? firstName
        : (userSession.getClientName() ?? 'User');
    final initials = _getInitials(userSession);

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 80, // Adjust as needed for your design
        ),
        color: widget.isSimpleLayout
            ? const Color(0xFF7C4DFF)
            : Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.only(
          top: widget.isSimpleLayout ? 24.0 : 8.0, // Reduced padding
          left: 16,
          right: 16,
          bottom: 4, // Reduced padding
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 8.0),
                  child:
                      widget.isHomeScreen
                          ? Image.asset('assets/icon/new_Icon.png', height: 40)
                          : (widget.onSidebarToggle == null
                              ? IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFF7C4DFF),
                                ),
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.of(context).pop();
                                  } else {
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/home');
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
                          child: widget.leadingWidget,
                        ),
                      if (widget.onSidebarToggle != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: IconButton(
                            icon: Icon(
                              widget.isSidebarOpen
                                  ? Icons.menu_open
                                  : Icons.menu,
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
                    onTap: widget.onLeadingPressed,
                    child: widget.leadingWidget,
                  )
                else if (widget.onSidebarToggle != null)
                  IconButton(
                    icon: Icon(
                      widget.isSidebarOpen ? Icons.menu_open : Icons.menu,
                      color: const Color(0xFF7C4DFF),
                      size: 32,
                    ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color ??
                              Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                if (widget.isSimpleLayout)
                  const SizedBox(width: 40)
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Stack(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications_none,
                                color: Theme.of(context).iconTheme.color ?? Colors.black,
                                size: 24,
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
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
                        onTap:
                            () => _showUserMenu(context, displayName, initials),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showUserMenu(BuildContext context, String displayName, String initials) {
    final userSession = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );
    // Recalculate initials in case userSession data changed
    final currentInitials = _getInitials(userSession);
    // Get first name for display in dropdown menu header
    final firstName = userSession.patient?['first_name']?.toString().trim();
    final menuDisplayName = firstName != null && firstName.isNotEmpty
        ? firstName
        : (userSession.getClientName() ?? 'User');

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
                  currentInitials,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    (userSession.clientNumber ??
                        userSession.patient?['identifier'] ??
                        'No Client ID'),
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
          child: ListTile(leading: Icon(Icons.logout), title: Text('Logout')),
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
            builder:
                (context) => AlertDialog(
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
            }
          }
          break;
      }
    });
  }
}
