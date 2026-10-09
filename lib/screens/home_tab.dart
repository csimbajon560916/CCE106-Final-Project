import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_page.dart';

class HomeTab extends StatefulWidget {
  final Function(Map<String, dynamic>)? onAddToCart;
  final List<Map<String, dynamic>>? cartItems;
  final VoidCallback? onOpenDrawer;

  const HomeTab({
    Key? key,
    this.onAddToCart,
    this.cartItems,
    this.onOpenDrawer,
  }) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'LPG',
    'Powerkalan',
    'Accessories',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addToFirestoreCart(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add items to cart.')),
      );
      return;
    }

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final String itemName = item['name'] ?? item['title'] ?? 'Product';
    final query = await cartRef.where('name', isEqualTo: itemName).get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      int currentQty = (doc.data()['quantity'] as num? ?? 1).toInt();
      await cartRef.doc(doc.id).update({'quantity': currentQty + 1});
    } else {
      final cleanItem = Map<String, dynamic>.from(item);

      // Store standardized name key for downstream screens
      cleanItem['productId'] = item['id'];

      // Remove all non-Firestore-serializable UI objects
      cleanItem.removeWhere((key, value) =>
          value is Color ||
          value is IconData ||
          key == 'icon' ||
          key == 'badgeColor');

      cleanItem['quantity'] = 1;
      await cartRef.add(cleanItem);
    }

    if (widget.onAddToCart != null) {
      widget.onAddToCart!(item);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$itemName added to cart!')),
      );
    }
  }

  IconData _getCategoryIcon(String? category, String name) {
  final lowerName = name.toLowerCase();

  if (lowerName.contains('stove') || lowerName.contains('burner')) {
    return Icons.countertops_rounded;
  } else if (lowerName.contains('powerkalan') || category == 'Powerkalan') {
    return Icons.soup_kitchen_rounded;
  } else if (lowerName.contains('clamp') || lowerName.contains('hose') || lowerName.contains('regulator')) {
    return Icons.settings_input_component_rounded;
  } else {
    return Icons.propane_tank_rounded;
  }
}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDF301C),
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: const Text(
          'PryceHatid',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: user == null
                ? null
                : FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('cart')
                    .snapshots(),
            builder: (context, snapshot) {
              int totalCount = 0;
              if (snapshot.hasData && snapshot.data != null) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalCount += (data['quantity'] as num? ?? 1).toInt();
                }
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  if (totalCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$totalCount',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'search products, accessories, sets...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Horizontal Filter Categories
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFFDF301C),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 3. Section Heading
            const Text(
              'Browse Products & Accessories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 4. Products Grid Streamed Real-Time from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFDF301C)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No products available right now.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final search = _searchController.text.toLowerCase();

                // Map Firestore documents into local product map structure
                final productsList = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['title'] ?? data['name'] ?? 'Product';
                  final category = data['category'] ?? 'LPG';

                  return {
                    'id': doc.id,
                    'name': name,
                    'title': name,
                    'subtitle': data['subtitle'] ?? '',
                    'price': (data['price'] ?? 0.0).toDouble(),
                    'stock': (data['stock'] ?? 0) as int,
                    'category': category,
                    'badge': data['badge'],
                    'icon': _getCategoryIcon(category, name),
                  };
                }).toList();

                // Filter products based on selected category & search input
                final filteredProducts = productsList.where((p) {
                  final matchesCategory = _selectedCategory == 'All' ||
                      p['category'] == _selectedCategory;
                  final matchesSearch = (p['name'] as String)
                          .toLowerCase()
                          .contains(search) ||
                      ((p['subtitle'] ?? '') as String)
                          .toLowerCase()
                          .contains(search);
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No matching products found.'),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = filteredProducts[index];
                    return _buildProductCard(item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    int stock = (item['stock'] as int?) ?? 0;
    bool isOutOfStock = stock <= 0; // Check if stock is 0 or less

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: Icon(
                      (item['icon'] as IconData?) ?? Icons.propane_tank,
                      size: 48,
                      color: isOutOfStock ? Colors.grey : const Color(0xFFDF301C),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Name
                Text(
                  item['name'] ?? 'Product',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock ? Colors.grey : Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  item['subtitle'] ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),

                // Price
                Text(
                  '₱${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock ? Colors.grey : const Color(0xFFDF301C),
                  ),
                ),
                const SizedBox(height: 8),

                // Add to Cart / Out of Stock Button
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutOfStock ? Colors.grey.shade300 : Colors.grey.shade600,
                      foregroundColor: isOutOfStock ? Colors.grey.shade600 : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: isOutOfStock ? null : () => _addToFirestoreCart(item), // Disable button if out of stock
                    child: Text(
                      isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Out of Stock or Custom Badge
          if (isOutOfStock || item['badge'] != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOutOfStock ? Colors.grey.shade300 : ((item['badgeColor'] as Color?) ?? Colors.pink.shade100),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOutOfStock ? 'Out of Stock' : item['badge'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock ? Colors.grey.shade800 : Colors.redAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}