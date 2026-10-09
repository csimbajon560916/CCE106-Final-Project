import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pryce_hatid/screens/inventory_screen.dart';
import '../auth/auth_service.dart';

class StoreAdminScreen extends StatelessWidget {
  const StoreAdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Store / Hub Admin'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Stock & Inventory
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: const Icon(Icons.inventory, color: Colors.blue),
              title: const Text('Stock & Inventory Management', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Manage LPG cylinder counts & pricing'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              // REPLACE lines 38-42 with:
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventoryScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 2. Incoming Station Orders (Clickable)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: const Icon(Icons.assignment, color: Colors.orange),
              title: const Text('Incoming Station Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Assign orders to available riders'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StationOrdersScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Order Assignment Screen
class StationOrdersScreen extends StatelessWidget {
  const StationOrdersScreen({Key? key}) : super(key: key);

  void _showAssignRiderDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Rider'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'rider')
                  .where('isOnDuty', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No active riders found. Create a rider account first.');
                }

                var riders = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: riders.length,
                  itemBuilder: (context, index) {
                    var rider = riders[index].data() as Map<String, dynamic>;
                    String riderId = riders[index].id;
                    String riderName = rider['name'] ?? 'Unnamed Rider';
                    String phone = rider['phone'] ?? 'No phone';

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(riderName),
                      subtitle: Text(phone),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        // Update order with rider information in Firestore
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderId)
                            .update({
                          'riderId': riderId,
                          'riderName': riderName,
                          'riderPhone': phone,
                          'status': 'Out for Delivery',
                          'currentStep': 2,
                          'statusSubtitle': 'Rider $riderName is delivering your LPG',
                          'lastUpdate': DateTime.now().toString(),
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Order assigned to $riderName')),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Orders'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // REPLACE line 160 with:
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No incoming orders.'));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              var orderData = orders[index].data() as Map<String, dynamic>;
              String orderId = orders[index].id;
             // NEW:
            final addressMap = orderData['deliveryAddress'] is Map<String, dynamic>
                ? orderData['deliveryAddress'] as Map<String, dynamic>
                : {};

            String customerName = addressMap['fullName'] ?? orderData['customerName'] ?? 'Customer';

            final String street = addressMap['street'] ?? '';
            final String barangay = addressMap['barangayName'] ?? '';
            final String city = addressMap['cityName'] ?? '';
            final String province = addressMap['provinceName'] ?? '';

            final String formattedAddress = [street, barangay, city, province]
                .where((p) => p.toString().trim().isNotEmpty)
                .join(', ');

            String address = formattedAddress.isNotEmpty
                ? formattedAddress
                : (orderData['address'] ?? 'No address');
              String status = orderData['status'] ?? 'Processing';
              String? assignedRider = orderData['riderName'];

              final List itemsList = orderData['items'] is List ? orderData['items'] : [];
              final String itemsSummary = itemsList.isNotEmpty
                  ? itemsList.map((item) {
                      final name = item['title'] ?? item['name'] ?? item['productName'] ?? 'Item';
                      final qty = item['quantity'] ?? item['qty'] ?? 1;
                      return '$qty x $name';
                    }).join(', ')
                  : 'No items detailed';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #${orderId.substring(0, 6)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Chip(
                            label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: status == 'Delivered'
                                ? Colors.blue
                                : (status == 'Out for Delivery' ? Colors.green : Colors.orange),
                          ),
                        ],
                      ),
                      Text('Customer: $customerName'),
                      Text('Address: $address'),
                      Text(
                        'Items: $itemsSummary',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignedRider != null ? 'Assigned to: $assignedRider' : 'Rider: Unassigned',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: assignedRider != null ? Colors.green.shade800 : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: Text(assignedRider != null ? 'Reassign Rider' : 'Assign Rider'),
                        onPressed: () => _showAssignRiderDialog(context, orderId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}