import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({Key? key}) : super(key: key);

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
          'My Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user?.uid ?? '')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFDF301C)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading orders: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No orders placed yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final orderDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orderDocs.length,
            itemBuilder: (context, index) {
              final doc = orderDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              // 1. Order ID handling (Shortened Firestore doc ID if no explicit order ID field exists)
              final String rawDocId = doc.id;
              final String orderId = data['orderId'] ??
                  'ORD-${rawDocId.substring(0, 6).toUpperCase()}';

              // 2. Status parsing
              final String status = data['status'] ?? 'Pending';

              // 3. Price field lookup fallback (Reads 'totalPayment', 'totalAmount', or 'total')
              final double total = (data['totalPayment'] ??
                      data['totalAmount'] ??
                      data['total'] ??
                      0.0)
                  .toDouble();

              // 4. Cart Items parsing
              final List items = data['items'] is List ? data['items'] : [];

              // 5. Address formatting
              final addressData = data['deliveryAddress'] is Map<String, dynamic>
                  ? data['deliveryAddress'] as Map<String, dynamic>
                  : {};

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
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Header (ID & Status Badge)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            orderId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Item list summary
                      ...items.map((item) {
                        final String name = item['name'] ?? 'Product';
                        final int qty = item['quantity'] ?? 1;
                        final String service = item['selectedService'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            '• $name (x$qty)${service.isNotEmpty ? ' - Service: $service' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 10),

                      // Formatted Delivery Address
                      if (formattedAddress.isNotEmpty) ...[
                        Text(
                          'Delivery Address: $formattedAddress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Order Total
                      Row(
                        children: [
                          const Text(
                            'Total: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '₱${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFFDF301C),
                            ),
                          ),
                        ],
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