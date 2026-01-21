import 'package:flutter/material.dart';

/// A responsive wrapper that adds horizontal margins on large screens
/// to constrain content width and create a modern, centered layout.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
    this.backgroundColor,
  });

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if current screen is considered wide (tablet/desktop)
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get horizontal margin based on screen size
  static double getHorizontalMargin(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return (width - 1200) / 2; // Center with max 1200px content
    } else if (width >= tabletBreakpoint) {
      return width * 0.04; // 4% margin on each side
    } else if (width >= mobileBreakpoint) {
      return width * 0.02; // 2% margin on each side
    }
    return 0; // No extra margin on mobile
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= mobileBreakpoint;

    if (!isWide) {
      // Mobile: No wrapper, just return child with optional padding
      return Container(
        color: backgroundColor,
        padding: padding,
        child: child,
      );
    }

    // Calculate content width
    double contentWidth;
    if (screenWidth >= desktopBreakpoint) {
      contentWidth = maxWidth;
    } else if (screenWidth >= tabletBreakpoint) {
      contentWidth = screenWidth * 0.92; // 92% of screen width
    } else {
      contentWidth = screenWidth * 0.96; // 96% of screen width
    }

    return Container(
      color: backgroundColor ?? const Color(0xFFF8F9FA),
      width: double.infinity,
      child: Center(
        child: Container(
          width: contentWidth,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// A responsive scaffold body wrapper that handles the common pattern
/// of having content with responsive margins
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= ResponsiveWrapper.mobileBreakpoint;

    if (!isWide) {
      return Container(
        color: backgroundColor,
        padding: padding,
        child: child,
      );
    }

    return Container(
      color: backgroundColor ?? const Color(0xFFF3F4F6),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: padding,
            decoration: isWide
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  )
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Helper extension for responsive sizing
extension ResponsiveSize on BuildContext {
  bool get isWideScreen => ResponsiveWrapper.isWideScreen(this);
  bool get isDesktop => ResponsiveWrapper.isDesktop(this);
  double get horizontalMargin => ResponsiveWrapper.getHorizontalMargin(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}
