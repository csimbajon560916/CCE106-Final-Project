import 'package:flutter/material.dart';
import 'package:pryce_hatid/screens/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  final Map<String, dynamic> selectedAddress;

  const ProductDetailScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.selectedAddress,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _selectedService = 'Refill';

  // Check if the item is an LPG Cylinder that requires Refill/New Tank service selection
  bool _isLPGTank(String name) {
    final lower = name.toLowerCase();
    return (lower.contains('11kg') ||
            lower.contains('22kg') ||
            lower.contains('50kg') ||
            lower.contains('cylinder')) &&
        !lower.contains('starter set');
  }

  // Exact descriptions matched to your PryceHatid product catalog
  String _getProductDescription(String name, String rawDesc) {
    if (rawDesc.trim().isNotEmpty) return rawDesc;

    final lower = name.toLowerCase();

    if (lower.contains('11kg')) {
      return 'Standard Household LPG Cylinder. PryceGas 11kg provides clean, safe, and reliable cooking gas for home use. Guaranteed accurate weight and safe cylinder inspection upon delivery.';
    } else if (lower.contains('22kg')) {
      return 'Commercial LPG Tank. Designed for small businesses, restaurants, and heavy home cooking requirements with high efficiency and guaranteed full content weight.';
    } else if (lower.contains('50kg')) {
      return 'Heavy Industrial LPG Tank. High-capacity 50kg cylinder engineered for restaurants, hotels, bakeries, and industrial applications.';
    } else if (lower.contains('starter set')) {
      return 'Package Bundle includes 11kg PryceGas Cylinder + Safety Regulator + Reinforced Safety Hose + Stainless Clamps. Everything you need to set up your kitchen.';
    } else if (lower.contains('powerkalan')) {
      return 'PryceGas Powerkalan Portable Camping & Household Stove. Compact, heavy-duty stove ideal for outdoor cooking and small living spaces.';
    } else if (lower.contains('single gas burner')) {
      return 'Cast Iron Single Burner Stove. Built with durable cast-iron body for strong, heat-efficient flame distribution.';
    } else if (lower.contains('double gas burner')) {
      return 'Stainless Double Burner Stove. Premium stainless steel body with dual burner layout for multi-task cooking efficiency.';
    } else if (lower.contains('regulator')) {
      return 'Safety Gas Regulator with Auto Shut-off feature. Built-in pressure safety valve to automatically stop gas flow in case of sudden leaks.';
    } else if (lower.contains('reinforced') || lower.contains('hose')) {
      return 'Reinforced LPG Hose (1.5m). High-pressure multi-layer safety gas hose resistant to wear, heat, and pressure.';
    } else if (lower.contains('clamps')) {
      return 'Stainless Hose Clamps (2pcs). Rust-proof heavy-duty tighteners to keep your LPG hose firmly secured to the regulator and stove.';
    }

    return 'PryceGas authentic product. Guaranteed safe and inspected upon delivery.';
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = widget.cartItems.isNotEmpty ? widget.cartItems.first : {};
    final String productName = firstItem['name'] ?? 'PryceGas Product';
    final String rawDescription = firstItem['description'] ?? '';
    
    final bool isLPG = _isLPGTank(productName);
    final String description = _getProductDescription(productName, rawDescription);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDF301C),
        elevation: 0,
        centerTitle: true,
        title: Text(
          productName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Product Card Image Preview
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLPG ? Icons.propane_tank : Icons.shopping_bag_outlined,
                    size: 72,
                    color: const Color(0xFFDF301C),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // "Choose a service" (Only appears for 11kg, 22kg, and 50kg LPG tanks)
            if (isLPG) ...[
              const Text(
                'Choose a service',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedService = 'Refill'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedService == 'Refill'
                              ? Colors.grey.shade300
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedService == 'Refill'
                                ? const Color(0xFFDF301C)
                                : Colors.grey.shade400,
                            width: _selectedService == 'Refill' ? 1.5 : 1.0,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.refresh, color: Colors.black87),
                            SizedBox(height: 4),
                            Text('Refill', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedService = 'New tank'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedService == 'New tank'
                              ? Colors.grey.shade300
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedService == 'New tank'
                                ? const Color(0xFFDF301C)
                                : Colors.grey.shade400,
                            width: _selectedService == 'New tank' ? 1.5 : 1.0,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.propane_tank_outlined, color: Colors.black87),
                            SizedBox(height: 4),
                            Text('New tank', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Dynamic Description Section
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                description,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4),
              ),
            ),

            const Spacer(),

            // Proceed to Checkout Button
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
                  final updatedItems = widget.cartItems.map((item) {
                    final itemCopy = Map<String, dynamic>.from(item);
                    final itemName = (itemCopy['name'] ?? '').toString();
                    if (_isLPGTank(itemName)) {
                      itemCopy['selectedService'] = _selectedService;
                    }
                    return itemCopy;
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        cartItems: updatedItems,
                        totalAmount: widget.totalAmount,
                        selectedAddress: widget.selectedAddress,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Proceed to Checkout',
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
    );
  }
}