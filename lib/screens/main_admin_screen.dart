import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_service.dart';
import 'create_store_admin_screen.dart';
import 'create_rider_screen.dart';

class MainAdminScreen extends StatelessWidget {
  const MainAdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Pryce Main Admin Console'),
        backgroundColor: const Color(0xFFD32F2F), // Pryce Red theme
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total System Sales Card (Real-time Firestore Aggregation)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (context, snapshot) {
                double totalSales = 0.0;

                if (snapshot.hasData && snapshot.data != null) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // Sum sales from completed/delivered orders (or all non-cancelled orders)
                    final String status = (data['status'] ?? '').toString().toLowerCase();
                    if (status == 'delivered' || status == 'completed') {
                      final double amount = (data['totalPayment'] ?? data['subtotal'] ?? 0.0).toDouble();
                      totalSales += amount;
                    }
                  }
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: const Color(0xFFFFEBEE),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bar_chart,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total System Sales',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱ ${totalSales.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Account & Station Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // Card 1: Create Store Admin
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                title: const Text(
                  'Create Store Admin Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Provision Store/Station Admin to manage refilling hubs'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateStoreAdminScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Card 2: Create Rider Account directly
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.two_wheeler, color: Colors.blue),
                title: const Text(
                  'Create Rider Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Provision Rider account linked to a delivery hub'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateRiderScreen(
                        storeHubId: 'main_hub_01', // Default or selected hub
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

          ],
        ),
      ),
    );
  }
}