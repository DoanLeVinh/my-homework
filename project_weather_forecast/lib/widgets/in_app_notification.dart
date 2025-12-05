import 'package:flutter/material.dart';
import 'dart:ui';

class InAppNotification extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final Duration displayDuration;

  const InAppNotification({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.notifications_active,
    this.primaryColor = Colors.blue,
    this.backgroundColor = Colors.white,
    this.onDismiss,
    this.onTap,
    this.displayDuration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<InAppNotification> createState() => _InAppNotificationState();

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.notifications_active,
    Color primaryColor = Colors.blue,
    Color backgroundColor = Colors.white,
    VoidCallback? onDismiss,
    VoidCallback? onTap,
    Duration displayDuration = const Duration(seconds: 5),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: InAppNotification(
          title: title,
          message: message,
          icon: icon,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
          displayDuration: displayDuration,
          onDismiss: () {
            overlayEntry.remove();
            onDismiss?.call();
          },
          onTap: () {
            overlayEntry.remove();
            onTap?.call();
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    Future.delayed(displayDuration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        onDismiss?.call();
      }
    });
  }
}

class _InAppNotificationState extends State<InAppNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.backgroundColor.withValues(alpha: 0.95),
                        widget.backgroundColor.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icon với gradient background
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.primaryColor,
                                    widget.primaryColor.withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.primaryColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      color: widget.primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.message,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Close button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                                onPressed: _handleDismiss,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class để tạo notification nhanh
class NotificationHelper {
  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    InAppNotification.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle,
      primaryColor: Colors.green,
      backgroundColor: Colors.white,
      onTap: onTap,
      displayDuration: duration ?? const Duration(seconds: 5),
    );
  }

  static void showError({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    InAppNotification.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.error,
      primaryColor: Colors.red,
      backgroundColor: Colors.white,
      onTap: onTap,
      displayDuration: duration ?? const Duration(seconds: 5),
    );
  }

  static void showWarning({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    InAppNotification.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.warning_amber,
      primaryColor: Colors.orange,
      backgroundColor: Colors.white,
      onTap: onTap,
      displayDuration: duration ?? const Duration(seconds: 5),
    );
  }

  static void showInfo({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    InAppNotification.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.info,
      primaryColor: Colors.blue,
      backgroundColor: Colors.white,
      onTap: onTap,
      displayDuration: duration ?? const Duration(seconds: 5),
    );
  }

  static void showWeatherAlert({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    InAppNotification.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.wb_sunny,
      primaryColor: Colors.amber,
      backgroundColor: Colors.white,
      displayDuration: duration ?? const Duration(seconds: 7),
      onTap: onTap,
    );
  }

  static void showEventReminder({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration? duration,
  }) {
    InAppNotification.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.event,
      primaryColor: Colors.purple,
      backgroundColor: Colors.white,
      displayDuration: duration ?? const Duration(seconds: 6),
      onTap: onTap,
    );
  }
}
