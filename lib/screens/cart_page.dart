import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pryce_hatid/screens/select_delivery_address_screen.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Set to keep track of selected item document IDs
  final Set<String> _selectedDocIds = {};

  void _updateQuantity(String docId, int currentQty, int change) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(docId);

    int newQty = currentQty + change;
    if (newQty <= 0) {
      // Remove item if quantity drops to 0
      await cartRef.delete();
      setState(() {
        _selectedDocIds.remove(docId);
      });
    } else {
      await cartRef.update({'quantity': newQty});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cart')),
        body: const Center(child: Text('Please log in to view cart.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDF301C),
        elevation: 0,
        title: const Text('My Cart', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Your cart is empty.'));
          }

          final docs = snapshot.data!.docs;

          // Compute grand total for selected items only
          double totalPrice = 0.0;
          final List<Map<String, dynamic>> selectedItemsToCheckout = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
            final quantity = (data['quantity'] as num? ?? 1).toInt();

            if (_selectedDocIds.contains(doc.id)) {
              totalPrice += price * quantity;
              selectedItemsToCheckout.add({
                ...data,
                'cartDocId': doc.id,
              });
            }
          }

          bool isAllSelected = docs.isNotEmpty && _selectedDocIds.length == docs.length;

          return Column(
            children: [
              // Select All Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: isAllSelected,
                      activeColor: const Color(0xFFDF301C),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedDocIds.addAll(docs.map((d) => d.id));
                          } else {
                            _selectedDocIds.clear();
                          }
                        });
                      },
                    ),
                    const Text(
                      'Select All Items',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Cart Items List
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    final String name = data['name'] ?? 'Item';
                    final double price =
                        double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
                    final int quantity = (data['quantity'] as num? ?? 1).toInt();
                    final bool isSelected = _selectedDocIds.contains(docId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFDF301C) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Item Checkbox
                          Checkbox(
                            value: isSelected,
                            activeColor: const Color(0xFFDF301C),
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedDocIds.add(docId);
                                } else {
                                  _selectedDocIds.remove(docId);
                                }
                              });
                            },
                          ),

                          // Icon placeholder
                          const Icon(
                            Icons.propane_tank_rounded,
                            color: Color(0xFFDF301C),
                            size: 32,
                          ),
                          const SizedBox(width: 8),

                          // Title and Subtotal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₱${price.toStringAsFixed(2)} x $quantity',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Quantity Controls (- 1 +)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.grey,
                                iconSize: 22,
                                onPressed: () =>
                                    _updateQuantity(docId, quantity, -1),
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: Colors.grey,
                                iconSize: 22,
                                onPressed: () =>
                                    _updateQuantity(docId, quantity, 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Checkout Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₱${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDF301C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDF301C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _selectedDocIds.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SelectDeliveryAddressScreen(
                                      cartItems: selectedItemsToCheckout,
                                      totalAmount: totalPrice,
                                    ),
                                  ),
                                );
                              },
                        child: Text(
                          _selectedDocIds.isEmpty
                              ? 'Select Items to Checkout'
                              : 'Proceed to Checkout (${_selectedDocIds.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}