import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class AlertsTab extends StatelessWidget {
  const AlertsTab({Key? key}) : super(key: key);

  // Helper method to resolve notification icons based on category/type
  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping;
      case 'promo':
        return Icons.local_offer;
      case 'safety':
        return Icons.security;
      default:
        return Icons.notifications;
    }
  }

  // Helper method to resolve icon colors based on category/type
  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'order':
        return PryceColors.secondaryNavy;
      case 'promo':
        return PryceColors.accentAmber;
      case 'safety':
        return PryceColors.primaryRed;
      default:
        return PryceColors.primaryRed;
    }
  }

  // Formatter for Firestore timestamps
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final DateTime dateTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  // Mark notification as read in Firestore
  Future<void> _markAsRead(String docId, String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerts & Notifications')),
        body: const Center(
          child: Text('Please log in to view your notifications.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load notifications.'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title = data['title'] ?? '';
              final String body = data['body'] ?? '';
              final String type = data['type'] ?? 'general';
              final bool isRead = data['isRead'] ?? false;
              final Timestamp? timestamp = data['createdAt'] as Timestamp?;

              final icon = _getNotificationIcon(type);
              final iconColor = _getNotificationColor(type);

              return Container(
                color: isRead
                    ? Colors.transparent
                    : PryceColors.primaryRed.withOpacity(0.04),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: iconColor.withOpacity(0.15),
                        child: Icon(icon, color: iconColor),
                      ),
                      if (!isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: PryceColors.primaryRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(body),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(timestamp),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!isRead) {
                      await _markAsRead(doc.id, user.uid);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}