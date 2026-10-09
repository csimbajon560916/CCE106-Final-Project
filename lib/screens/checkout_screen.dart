import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_navigation_screen.dart';
import 'dart:math';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount; // Merchandise subtotal
  final Map<String, dynamic> selectedAddress;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.selectedAddress,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Constant delivery fee
  final double _deliveryFee = 120.0;

  // Payment Method selection
  String _selectedPaymentMethod = 'Cash on Delivery';

  Future<void> checkoutCart({
    required String userId,
    required List<Map<String, dynamic>> selectedCartItems,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // 1. Create the new Order document
    final orderRef = firestore.collection('orders').doc();
    batch.set(orderRef, {
      'orderId': orderRef.id,
      'userId': userId,
      'items': selectedCartItems,
      'deliveryAddress': deliveryAddress,
      'status': 'Pending',
      'createdAt': DateTime.now().toString(),
    });

    // 2. Delete each checked-out item from user's cart subcollection
    for (var item in selectedCartItems) {
      if (item['id'] != null) {
        final cartItemRef = firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(item['id']); // Ensure 'id' matches doc.id from CartPage
        batch.delete(cartItemRef);
      }
    }

    // 3. Commit batch
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    // Total calculation: items total + delivery fee
    final double finalTotal = widget.totalAmount + _deliveryFee;

    // Address fields parsing
    final String fullName = widget.selectedAddress['fullName'] ?? 'Customer Name';
    final String phone = widget.selectedAddress['phone'] ?? '';
    final String street = widget.selectedAddress['street'] ?? '';
    final String barangay = widget.selectedAddress['barangayName'] ?? '';
    final String city = widget.selectedAddress['cityName'] ?? '';
    final String province = widget.selectedAddress['provinceName'] ?? '';
    final String region = widget.selectedAddress['regionName'] ?? '';
    final String postalCode = widget.selectedAddress['postalCode']?.toString() ?? '';

    final String fullAddress = [
      street,
      barangay,
      if (region.isNotEmpty) '$region,',
      province,
      city,
      postalCode,
    ].where((part) => part.isNotEmpty).join(' ');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDF301C),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Delivery Address Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.location_on, color: Color(0xFFDF301C), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      fullAddress,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Order Items List Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Items',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.cartItems.map((item) {
                      final name = item['name'] ?? 'Product';
                      final qty = item['quantity'] ?? 1;
                      final price = (item['price'] ?? 0.0) * qty;
                      final service = item['selectedService'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$name (x$qty)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (service != null && service.isNotEmpty)
                                    Text(
                                      'Service: $service',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '₱${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Payment Method Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.payment, color: Color(0xFFDF301C), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFDF301C),
                      title: const Text('Cash on Delivery (COD)'),
                      value: 'Cash on Delivery',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                    ),
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFDF301C),
                      title: const Text('GCash / E-Wallet'),
                      value: 'GCash',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Price Calculation Breakdown Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Merchandise Subtotal:',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                        ),
                        Text(
                          '₱${widget.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Fee:',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                        ),
                        Text(
                          '₱${_deliveryFee.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payment:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '₱${finalTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFDF301C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. Place Order Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDF301C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Place order logic (Save to Firestore)
                    _placeOrder(finalTotal);
                  },
                  child: const Text(
                    'Place Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generateOrderId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  final String randomCode = String.fromCharCodes(
    Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
  return 'ORD-$randomCode';
}

  void _placeOrder(double finalTotal) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(color: Color(0xFFDF301C)),
    ),
  );

  try {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // 1. Generate the formatted Order ID (e.g., ORD-SHMQBF)
    final String customOrderId = _generateOrderId();
    final orderRef = firestore.collection('orders').doc(); // Firestore doc reference

    // 2. Add order creation to the batch with custom order ID
    batch.set(orderRef, {
      'orderId': customOrderId, // Saved as ORD-XXXXXX for the Orders UI
      'userId': user.uid,
      'items': widget.cartItems,
      'subtotal': widget.totalAmount,
      'deliveryFee': _deliveryFee,
      'totalPayment': finalTotal,
      'paymentMethod': _selectedPaymentMethod,
      'deliveryAddress': widget.selectedAddress,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Delete checked-out items from cart & deduct stock from inventory
    for (var item in widget.cartItems) {
      final String? docId = item['cartDocId'] ?? item['id'];
      final String? productId = item['productId'];
      final String itemName = item['name'] ?? item['title'] ?? '';
      final int qtyOrdered = (item['quantity'] as num? ?? 1).toInt();

      // Delete item from user's cart subcollection
      if (docId != null && docId.isNotEmpty) {
        final cartItemRef = firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(docId);

        batch.delete(cartItemRef);
      }

      // Deduct stock: First try using productId, fallback to matching by product title/name
      DocumentReference? productRef;

      if (productId != null && productId.isNotEmpty) {
        final docSnap = await firestore.collection('products').doc(productId).get();
        if (docSnap.exists) {
          productRef = docSnap.reference;
        }
      }

      // Fallback: If productId was not in cart item, find document by matching 'title' or 'name'
      if (productRef == null && itemName.isNotEmpty) {
        final titleQuery = await firestore
            .collection('products')
            .where('title', isEqualTo: itemName)
            .limit(1)
            .get();

        if (titleQuery.docs.isNotEmpty) {
          productRef = titleQuery.docs.first.reference;
        } else {
          final nameQuery = await firestore
              .collection('products')
              .where('name', isEqualTo: itemName)
              .limit(1)
              .get();
          if (nameQuery.docs.isNotEmpty) {
            productRef = nameQuery.docs.first.reference;
          }
        }
      }

      // Perform stock deduction if product document reference was resolved
      if (productRef != null) {
        batch.update(productRef, {
          'stock': FieldValue.increment(-qtyOrdered),
        });
      }
    }
    
    // Create notification alert for the placed order
    final notificationRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc();

    batch.set(notificationRef, {
      'title': 'Order Placed!',
      'body': 'Your order $customOrderId for ₱${finalTotal.toStringAsFixed(2)} has been placed successfully.',
      'type': 'order',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // 4. Commit batch
    await batch.commit();

    if (mounted) Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(initialIndex: 1),
        ),
        (route) => false,
      );
    }
  } catch (e) {
    if (mounted) Navigator.pop(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
}