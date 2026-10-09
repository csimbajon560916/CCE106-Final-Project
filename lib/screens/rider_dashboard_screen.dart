import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';
import 'dart:convert';
//import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';


class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({Key? key}) : super(key: key);

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {

  Future<void> _toggleDutyStatus(bool isOnDuty) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'isOnDuty': isOnDuty}, SetOptions(merge: true));
  }

  Future<String?> _takeAndUploadDeliveryPhoto(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // 1. Open Camera to snap proof of delivery
  final XFile? image = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 70, // Optimize image size for faster uploads
  );

  if (image == null) return null; // Rider cancelled taking photo

  // Show a loading indicator dialog while uploading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // 2. Configure Cloudinary credentials
    const String cloudName = 'dto2zvdp'; // Replace with your Cloudinary Cloud Name
    const String uploadPreset = 'delivery_proofs'; // Replace with your Unsigned Preset Name

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'deliveries' // Optional folder in Cloudinary
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonMap = jsonDecode(responseData);

    if (Navigator.canPop(context)) Navigator.pop(context); // Close loading dialog

    if (response.statusCode == 200) {
      return jsonMap['secure_url'] as String; // Return Cloudinary URL
    } else {
      throw Exception(jsonMap['error']?['message'] ?? 'Upload failed');
    }
  } catch (e) {
    if (Navigator.canPop(context)) Navigator.pop(context); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload proof photo: $e')),
    );
    return null;
  }


  }

  @override
  Widget build(BuildContext context) {
    final currentRider = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Rider Delivery Hub'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (currentRider != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentRider.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                bool isOnDuty = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  isOnDuty = data?['isOnDuty'] ?? false;
                }

                return Row(
                  children: [
                    Text(
                      isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOnDuty ? Colors.greenAccent : Colors.grey,
                      ),
                    ),
                    Switch(
                      value: isOnDuty,
                      activeColor: Colors.greenAccent,
                      onChanged: (val) => _toggleDutyStatus(val),
                    ),
                  ],
                );
              },
            ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('riderId', isEqualTo: currentRider?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No active orders assigned.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          var assignedOrders = snapshot.data!.docs;

          // Sort orders locally: latest first
          assignedOrders.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            // Safely extract createdAt timestamps or fall back to empty string / epoch
            final dynamic aTime = aData['createdAt'] ?? aData['lastUpdate'] ?? '';
            final dynamic bTime = bData['createdAt'] ?? bData['lastUpdate'] ?? '';

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime); // Descending order
            } else if (aTime is String && bTime is String) {
              return bTime.compareTo(aTime); // Descending order
            }
            return 0;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: assignedOrders.length,
            itemBuilder: (context, index) {
              var orderData = assignedOrders[index].data() as Map<String, dynamic>;
              String orderId = assignedOrders[index].id;
              // 1. Safe parsing for customer & address
              final addressData = orderData['deliveryAddress'] is Map<String, dynamic>
                  ? orderData['deliveryAddress'] as Map<String, dynamic>
                  : {};

              final String customerName = (addressData['fullName'] ?? orderData['customerName'] ?? 'Customer').toString();
              final String phone = (addressData['phone'] ?? 'No phone number').toString();

              final String street = (addressData['street'] ?? '').toString();
              final String barangay = (addressData['barangayName'] ?? '').toString();
              final String city = (addressData['cityName'] ?? '').toString();
              final String province = (addressData['provinceName'] ?? '').toString();

              final String address = [street, barangay, city, province]
                  .where((p) => p.trim().isNotEmpty)
                  .join(', ');

              // 2. Payment & Items details
              final double totalPayment = (orderData['totalPayment'] ?? orderData['subtotal'] ?? 0.0).toDouble();
              final String paymentMethod = (orderData['paymentMethod'] ?? 'COD').toString();
              final List<dynamic> items = orderData['items'] is List ? (orderData['items'] as List) : [];
              final String status = (orderData['status'] ?? 'Assigned').toString();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${orderId.substring(0, 6)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Chip(
                            label: Text(
                              status,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: status == 'Delivered'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Deliver to: $customerName',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Address: $address',
                          style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 6),
                      Text(
                        'Phone: $phone',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Payment: $paymentMethod (₱${totalPayment.toStringAsFixed(2)})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Items: ${items.map((i) => i['name'] ?? 'Item').join(', ')}',
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (status != 'Delivered')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Mark as Delivered'),
                            onPressed: () async {
                            // 1. Take photo & upload to Cloudinary first
                            final String? proofImageUrl = await _takeAndUploadDeliveryPhoto(context);

                            // If rider cancels taking a photo or upload fails, stop here
                            if (proofImageUrl == null) return;

                            // 2. Save delivery status and photo URL to Firestore
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(orderId)
                                .update({
                              'status': 'Delivered',
                              'currentStep': 3,
                              'statusSubtitle': 'Package successfully delivered',
                              'proofOfDeliveryUrl': proofImageUrl,
                              'deliveredAt': DateTime.now().toString(),
                              'lastUpdate': DateTime.now().toString(),
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order marked as Delivered with proof photo!')),
                              );
                            }
                          },
                          ),
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