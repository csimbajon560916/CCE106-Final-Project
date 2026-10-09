import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Order #${orderId.substring(0, 8).toUpperCase()}'),
        backgroundColor: PryceColors.primaryRed,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: PryceColors.primaryRed));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order details not found.'));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          List items = data['items'] ?? [];
          double subtotal = double.tryParse(data['subtotal'].toString()) ?? 0.0;
          double deliveryFee = double.tryParse(data['deliveryFee'].toString()) ?? 50.0;
          double totalAmount = double.tryParse(data['totalAmount'].toString()) ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Banner
                Card(
                  color: PryceColors.primaryRed.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping, color: PryceColors.primaryRed),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${data['status'] ?? 'Processing'}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: PryceColors.primaryRed),
                            ),
                            const SizedBox(height: 4),
                            Text(data['statusSubtitle'] ?? 'Order placed'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery Info
                const Text('Delivery Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: ${data['customerName'] ?? 'N/A'}'),
                        const SizedBox(height: 6),
                        Text('Phone: ${data['customerPhone'] ?? 'N/A'}'),
                        const SizedBox(height: 6),
                        Text('Address: ${data['customerAddress'] ?? 'N/A'}'),
                        const SizedBox(height: 6),
                        Text('Payment Mode: ${data['paymentMethod'] ?? 'COD'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Items Breakdown
                const Text('Items Purchased', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ...items.map((item) {
                          int qty = item['quantity'] ?? 1;
                          double price = double.tryParse(item['price'].toString()) ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item['name']}  x$qty'),
                                Text('₱ ${(price * qty).toStringAsFixed(2)}'),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text('₱ ${subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee'),
                            Text('₱ ${deliveryFee.toStringAsFixed(2)}'),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('₱ ${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PryceColors.primaryRed)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}