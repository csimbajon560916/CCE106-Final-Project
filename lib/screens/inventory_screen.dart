import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  void _showAddProductDialog(BuildContext context) {
  final nameController = TextEditingController();
  final subtitleController = TextEditingController();
  final stockController = TextEditingController();
  final priceController = TextEditingController();
  final badgeController = TextEditingController();

  String selectedCategory = 'LPG';
  final List<String> categories = ['LPG', 'Powerkalan', 'Accessories'];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'e.g. Complete Kitchen Starter Set',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle / Description',
                    hintText: 'e.g. 11kg Cylinder + Reg + Hose...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Initial Stock',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price (₱)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: badgeController,
                  decoration: const InputDecoration(
                    labelText: 'Badge Label (Optional)',
                    hintText: 'e.g. Package Bundle, Sale, Stove',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
              onPressed: () async {
                final name = nameController.text.trim();
                final subtitle = subtitleController.text.trim();
                final stock = int.tryParse(stockController.text.trim()) ?? 0;
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final badge = badgeController.text.trim();

                if (name.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('products').add({
                    'title': name,
                    'name': name,
                    'subtitle': subtitle,
                    'category': selectedCategory,
                    'stock': stock,
                    'price': price,
                    'badge': badge.isNotEmpty ? badge : null,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product added successfully!')),
                    );
                  }
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ),
  );
}

  void _showEditStockDialog(
      BuildContext context, String docId, String title, int currentStock, double currentPrice) {
    final stockController = TextEditingController(text: currentStock.toString());
    final priceController = TextEditingController(text: currentPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price (₱)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
            onPressed: () async {
              final newStock = int.tryParse(stockController.text.trim()) ?? currentStock;
              final newPrice = double.tryParse(priceController.text.trim()) ?? currentPrice;

              await FirebaseFirestore.instance.collection('products').doc(docId).update({
                'stock': newStock,
                'price': newPrice,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inventory updated successfully!')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock & Inventory Management'),
        backgroundColor: Colors.blue.shade800,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade800,
        onPressed: () => _showAddProductDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Tap + to add inventory.'),
            );
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title = data['title'] ?? data['name'] ?? 'Product';
              final int stock = (data['stock'] ?? 0) as int;
              final double price = (data['price'] ?? 0.0).toDouble();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Price: ₱${price.toStringAsFixed(2)} | Stock: $stock units'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditStockDialog(context, doc.id, title, stock, price),
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