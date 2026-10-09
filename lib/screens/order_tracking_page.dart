import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDF301C),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Track Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFDF301C)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading track orders: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No active orders to track.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final orderDocs = snapshot.data!.docs;

          // Sort in memory by createdAt descending
          orderDocs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orderDocs.length,
            itemBuilder: (context, index) {
              final doc = orderDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              // 1. Generate Order ID from Document ID if orderId field is null
              final String rawDocId = doc.id;
              final String orderId = data['orderId'] ??
                  'ORD-${rawDocId.substring(0, 6).toUpperCase()}';

              final String status = data['status'] ?? 'Pending';
              final String riderName = data['riderName'] ?? 'Unassigned';

              // 2. Format Delivery Address
              final addressData = data['deliveryAddress'] is Map<String, dynamic>
                  ? data['deliveryAddress'] as Map<String, dynamic>
                  : {};

              final String fullName = addressData['fullName'] ?? '';
              final String street = addressData['street'] ?? '';
              final String barangay = addressData['barangayName'] ?? '';
              final String city = addressData['cityName'] ?? '';
              final String province = addressData['provinceName'] ?? '';

              final String formattedAddress = [street, barangay, city, province]
                  .where((p) => p.toString().isNotEmpty)
                  .join(', ');

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon + Order ID
                      Row(
                        children: [
                          const Icon(Icons.local_shipping,
                              color: Color(0xFFDF301C), size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Order ID: $orderId',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Rider info
                      Row(
                        children: [
                          const Icon(Icons.person_pin, color: Colors.grey, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Rider: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700),
                          ),
                          Text(
                            riderName,
                            style: TextStyle(
                              color: riderName == 'Unassigned'
                                  ? Colors.orange.shade800
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Delivery Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black87),
                                children: [
                                  TextSpan(
                                    text: 'Address: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (fullName.isNotEmpty)
                                    TextSpan(text: '$fullName - '),
                                  TextSpan(text: formattedAddress),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Status Progress Indicator Bar
                      _buildStatusTracker(status),
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

  // Visual status timeline widget
  Widget _buildStatusTracker(String currentStatus) {
    final statuses = ['Pending', 'Preparing', 'Out for Delivery', 'Delivered'];
    int currentIndex = statuses.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(statuses.length, (i) {
            bool isCompleted = i <= currentIndex;
            return Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isCompleted
                        ? const Color(0xFFDF301C)
                        : Colors.grey.shade300,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  if (i < statuses.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < currentIndex
                            ? const Color(0xFFDF301C)
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Status: $currentStatus',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFDF301C),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}