import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'new_address_screen.dart';
import 'product_detail_screen.dart';

class SelectDeliveryAddressScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const SelectDeliveryAddressScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<SelectDeliveryAddressScreen> createState() =>
      _SelectDeliveryAddressScreenState();
}

class _SelectDeliveryAddressScreenState
    extends State<SelectDeliveryAddressScreen> {
  String? _selectedAddressId;
  Map<String, dynamic>? _selectedAddressData;

  // Function to delete address from Firestore
  Future<void> _deleteAddress(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDF301C)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(docId)
          .delete();

      // Reset selection if deleted item was selected
      if (_selectedAddressId == docId) {
        setState(() {
          _selectedAddressId = null;
          _selectedAddressData = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Delivery Address')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDF301C),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Select Delivery Address',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NewAddressScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No addresses found.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDF301C),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NewAddressScreen(),
                        ),
                      );
                    },
                    child: const Text('Add New Address',
                        style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            );
          }

          final addresses = snapshot.data!.docs;

          // Auto-select initial default address or first address
          if (_selectedAddressId == null && addresses.isNotEmpty) {
            QueryDocumentSnapshot? defaultDoc;
            for (var doc in addresses) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data?['isDefault'] == true) {
                defaultDoc = doc;
                break;
              }
            }
            defaultDoc ??= addresses.first;

            _selectedAddressId = defaultDoc.id;
            _selectedAddressData = defaultDoc.data() as Map<String, dynamic>;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final doc = addresses[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final isSelected = _selectedAddressId == docId;

                    final name = data['fullName'] ?? '';
                    final phone = data['phone'] ?? '';
                    final region = data['region'] ?? '';
                    final postalCode = data['postalCode'] ?? '';
                    final street = data['street'] ?? '';
                    final isDefault = data['isDefault'] ?? false;

                    final fullAddressStr = '$street, $region, $postalCode';

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAddressId = docId;
                          _selectedAddressData = data;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFDF301C)
                                : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    fullAddressStr,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isDefault) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Radio<String>(
                                  value: docId,
                                  groupValue: _selectedAddressId,
                                  activeColor: const Color(0xFFDF301C),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedAddressId = val;
                                      _selectedAddressData = data;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteAddress(docId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Use Selected Address Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDF301C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: (_selectedAddressId == null ||
                            _selectedAddressData == null)
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  cartItems: widget.cartItems,
                                  totalAmount: widget.totalAmount,
                                  selectedAddress: _selectedAddressData!,
                                ),
                              ),
                            );
                          },
                    child: const Text(
                      'Use Selected Address',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}