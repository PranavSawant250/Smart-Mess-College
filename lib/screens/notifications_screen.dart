import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    final notifications = provider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: const Text('Mark all as read', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textLight),
                      SizedBox(height: 16),
                      Text('No notifications yet.', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final dateStr = DateFormat('MMM d, h:mm a').format(n.createdAt);
                      
                      return Card(
                        color: n.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: n.isRead ? 1 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: n.isRead ? BorderSide.none : const BorderSide(color: AppColors.primary, width: 0.5),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: n.isRead ? AppColors.divider : AppColors.primary,
                            child: Icon(
                              _getIconForType(n.type),
                              color: n.isRead ? AppColors.textLight : Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(n.body, style: TextStyle(color: n.isRead ? AppColors.textLight : AppColors.textDark, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                          onTap: () {
                            if (!n.isRead) provider.markAsRead(n.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'poll_opened': return Icons.poll;
      case 'poll_finalized': return Icons.check_circle;
      case 'request_approved': return Icons.verified_user;
      case 'request_rejected': return Icons.cancel;
      case 'kitchen_order': return Icons.restaurant;
      case 'feedback_reminder': return Icons.feedback;
      default: return Icons.notifications;
    }
  }
}
