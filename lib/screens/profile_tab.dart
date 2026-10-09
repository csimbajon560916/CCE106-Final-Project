import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pryce_hatid/screens/auth_wrapper.dart';
import '../auth/auth_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  // 1. Personal Details Dialog (Fetches saved phone/name from Firestore)
  void _showPersonalDetails(BuildContext context, user) async {
    if (user == null) return;

    // Show loading indicator while fetching saved user data from Firestore
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: PryceColors.primaryRed),
      ),
    );

    String savedName = user.displayName ?? '';
    String savedPhone = '';

    try {
      // Fetch latest profile document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        savedName = data['name'] ?? savedName;
        savedPhone = data['phone'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading indicator

    final nameController = TextEditingController(text: savedName);
    final phoneController = TextEditingController(text: savedPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_outline, color: PryceColors.primaryRed),
            SizedBox(width: 8),
            Text('Personal Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            Text(user.email ?? 'N/A', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '09123456789',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PryceColors.primaryRed),
            onPressed: () async {
              final phoneText = phoneController.text.trim();

              if (phoneText.isNotEmpty) {
                if (!phoneText.startsWith('09')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number must start with 09'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (phoneText.length != 11) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number must be exactly 11 digits'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              try {
                await user.updateDisplayName(nameController.text.trim());

                // Save to Firestore 'users' collection
                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'name': nameController.text.trim(),
                  'phone': phoneText,
                  'email': user.email,
                }, SetOptions(merge: true));

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Details updated successfully!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating details: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. Saved Delivery Addresses Sheet
  void _showSavedAddresses(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saved Delivery Addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('addresses')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text('No saved addresses found.\nAdd one during checkout!', textAlign: TextAlign.center),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: PryceColors.primaryRed),
                              title: Text(data['label'] ?? 'Address ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(data['address'] ?? 
                                             data['fullAddress'] ??
                                             data['street'] ?? 
                                             data['details'] ?? 
                                             'No detail'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () {
                                  docs[index].reference.delete();
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. Payment Methods Dialog
  void _showPaymentMethods(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment_outlined, color: PryceColors.primaryRed),
            SizedBox(width: 8),
            Text('Payment Methods'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money, color: Colors.green),
              title: const Text('Cash on Delivery (COD)'),
              subtitle: const Text('Default payment mode'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
              title: const Text('GCash / E-Wallet'),
              subtitle: const Text('Available during checkout'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // 4. Transaction History Sheet
  void _showTransactionHistory(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('userId', isEqualTo: uid)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text('No previous transactions found.'),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final String orderId = data['orderId'] ?? 'ORD';
                            final double total = (data['totalPayment'] ?? data['totalPrice'] ?? 0.0).toDouble();
                            final String status = data['status'] ?? 'Completed';
                            final Timestamp? timestamp = data['createdAt'] as Timestamp?;
                            final String formattedDate = timestamp != null
                                ? DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate())
                                : 'Recent';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: status == 'Delivered' || status == 'Completed'
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                child: Icon(
                                  status == 'Delivered' || status == 'Completed'
                                      ? Icons.check
                                      : Icons.receipt_long,
                                  color: status == 'Delivered' || status == 'Completed'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              title: Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('$formattedDate\nStatus: $status'),
                              isThreeLine: true,
                              trailing: Text(
                                '₱${total.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: PryceColors.primaryRed),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: PryceColors.secondaryNavy,
              child: Text(
                user?.email != null && user!.email!.isNotEmpty
                    ? user.email![0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.email ?? 'User Email',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Divider(),

            // 1. Personal Details
            ListTile(
              leading: const Icon(Icons.person_outline, color: PryceColors.primaryRed),
              title: const Text('Personal Details'),
              subtitle: const Text('Name, phone number, email'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPersonalDetails(context, user),
            ),

            // 2. Saved Delivery Addresses
            ListTile(
              leading: const Icon(Icons.location_on_outlined, color: PryceColors.primaryRed),
              title: const Text('Saved Delivery Addresses'),
              subtitle: const Text('Home, Office, Shop'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (user != null) {
                  _showSavedAddresses(context, user.uid);
                }
              },
            ),

            // 3. Payment Methods
            ListTile(
              leading: const Icon(Icons.payment_outlined, color: PryceColors.primaryRed),
              title: const Text('Payment Methods'),
              subtitle: const Text('GCash, COD, Cards'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPaymentMethods(context),
            ),

            // 4. Transaction History
            ListTile(
              leading: const Icon(Icons.history_outlined, color: PryceColors.primaryRed),
              title: const Text('Transaction History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (user != null) {
                  _showTransactionHistory(context, user.uid);
                }
              },
            ),

            const Divider(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await AuthService().signOut();

                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}