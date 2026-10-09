import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class NewAddressScreen extends StatefulWidget {
  const NewAddressScreen({Key? key}) : super(key: key);

  @override
  State<NewAddressScreen> createState() => _NewAddressScreenState();
}

class _NewAddressScreenState extends State<NewAddressScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _streetController = TextEditingController();

  bool _isDefault = true;
  String _label = 'Home';

  // Cascading selections
  String? selectedRegion;
  String? selectedProvince;
  String? selectedCity;
  String? selectedBarangay;

  // Real street suggestions from Places API or local query
  List<String> _streetSuggestions = [];
  bool _isLoadingStreetSuggestions = false;

  // Real Philippine Administrative Structure Data
  final Map<String, Map<String, Map<String, List<String>>>> _phData = {
    'NCR (National Capital Region)': {
      'Metro Manila': {
        'Manila': ['Barangay 1', 'Barangay 2', 'Barangay 100', 'Binondo', 'Ermita'],
        'Quezon City': ['Central', 'Batasan Hills', 'Commonwealth', 'Cubao', 'Diliman'],
        'Makati': ['Bel-Air', 'Poblacion', 'San Lorenzo', 'Urdaneta'],
      }
    },
    'Region IX (Zamboanga Peninsula)': {
      'Zamboanga del Sur': {
        'Zamboanga City': ['Bato', 'Tetuan', 'Guiwan', 'Pasonanca', 'Tumaga', 'Santa Maria'],
        'Pagadian City': ['Balangasan', 'Dao', 'Gusa', 'San Pedro'],
      },
      'Zamboanga del Norte': {
        'Dipolog City': ['Central', 'Minaog', 'Estaka'],
        'Dapitan City': ['Poblacion', 'Taguilon'],
      }
    },
    'Region XI (Davao Region)': {
      'Davao del Sur': {
        'Davao City': ['Bato', 'Buhangin', 'Talomo', 'Poblacion', 'Toril'],
      }
    },
    'Region VII (Central Visayas)': {
      'Cebu': {
        'Cebu City': ['Lahug', 'Mabolo', 'Banilad', 'Guadalupe'],
        'Mandaue City': ['Subangdaku', 'Banilad', 'Bakilid'],
      }
    }
  };

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _postalCodeController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  // Step-by-step Cascading Picker Sheet (Region -> Province -> City -> Barangay)
  void _startLocationSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _LocationCascadePicker(
          phData: _phData,
          onCompleted: (region, province, city, barangay) {
            setState(() {
              selectedRegion = region;
              selectedProvince = province;
              selectedCity = city;
              selectedBarangay = barangay;
              _regionController.text = '$region, $province, $city, $barangay';
            });
          },
        );
      },
    );
  }

  // Fetch real Google Places / OpenStreetMap address suggestions for Street/Building
  Future<void> _fetchStreetSuggestions(String input) async {
    if (input.length < 3) {
      setState(() => _streetSuggestions = []);
      return;
    }

    setState(() => _isLoadingStreetSuggestions = true);

    // Contextual search query built from selected city/barangay
    final locationQuery = '$input, ${selectedBarangay ?? ''} ${selectedCity ?? ''} Philippines';

    try {
      // Free OpenStreetMap Nominatim API for real Philippine location suggestions
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(locationQuery)}&format=json&addressdetails=1&limit=5&countrycodes=ph',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'FlutterApp_PryceHatid',
      });

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final List<String> suggestions = data.map<String>((item) {
          final address = item['address'];
          final road = address['road'] ?? address['suburb'] ?? address['building'] ?? '';
          final name = item['display_name'] as String;
          return road.isNotEmpty ? '$road, ${name.split(',').first}' : name.split(',').take(2).join(',');
        }).where((s) => s.isNotEmpty).toSet().toList();

        setState(() {
          _streetSuggestions = suggestions;
        });
      }
    } catch (_) {
      // Fallback local suggestions if network fails
      setState(() {
        _streetSuggestions = [
          '$input Main Road',
          '$input Phase 1, Block 1',
          '$input Executive Village',
        ];
      });
    } finally {
      setState(() => _isLoadingStreetSuggestions = false);
    }
  }

  Future<void> _saveAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final regionStr = _regionController.text.trim();
    final street = _streetController.text.trim();

    if (name.isEmpty || phone.isEmpty || regionStr.isEmpty || street.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    if (phone.length != 11 || !phone.startsWith('09')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must be 11 digits and start with 09.'),
        ),
      );
      return;
    }

    final addressesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses');

    if (_isDefault) {
      final defaultQuery =
          await addressesRef.where('isDefault', isEqualTo: true).get();
      for (var doc in defaultQuery.docs) {
        await doc.reference.update({'isDefault': false});
      }
    }

    await addressesRef.add({
      'fullName': name,
      'phone': phone,
      'region': regionStr,
      'regionName': selectedRegion,
      'provinceName': selectedProvince,
      'cityName': selectedCity,
      'barangayName': selectedBarangay,
      'postalCode': _postalCodeController.text.trim(),
      'street': street,
      'isDefault': _isDefault,
      'label': _label,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Address',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Full Name Input
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                hintText: 'Full Name',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFDF301C)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Phone Number Input (Restricted to 11 digits starting with 09)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: const InputDecoration(
                hintText: 'Phone Number (e.g. 09123456789)',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFDF301C)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Region, Province, City, Barangay Cascading Picker
            GestureDetector(
              onTap: _startLocationSelection,
              child: AbsorbPointer(
                child: TextField(
                  controller: _regionController,
                  decoration: const InputDecoration(
                    hintText: 'Region, Province, City, Barangay',
                    suffixIcon: Icon(Icons.chevron_right),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFDF301C)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Postal Code Input
            TextField(
              controller: _postalCodeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Postal Code',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFDF301C)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Street Name, Building, House No. with Real Location Auto-Suggestions
            TextField(
              controller: _streetController,
              onChanged: (val) => _fetchStreetSuggestions(val),
              decoration: InputDecoration(
                hintText: 'Street Name, Building, House No.',
                suffixIcon: _isLoadingStreetSuggestions
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.arrow_drop_down),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFDF301C)),
                ),
              ),
            ),

            // Dropdown Suggestion Overlay List
            if (_streetSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Column(
                  children: _streetSuggestions.map((suggestion) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined, size: 18),
                      title: Text(suggestion, style: const TextStyle(fontSize: 13)),
                      onTap: () {
                        setState(() {
                          _streetController.text = suggestion;
                          _streetSuggestions = [];
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // Set as Default Address
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set as Default Address',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Switch(
                  value: _isDefault,
                  activeColor: const Color(0xFFDF301C),
                  onChanged: (val) {
                    setState(() {
                      _isDefault = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Label As (Work / Home)
            Row(
              children: [
                const Text('Label As:'),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Work'),
                  selected: _label == 'Work',
                  selectedColor: Colors.grey.shade300,
                  onSelected: (val) {
                    if (val) setState(() => _label = 'Work');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_label == 'Home') ...[
                        const Icon(Icons.check, size: 16, color: Colors.black),
                        const SizedBox(width: 4),
                      ],
                      const Text('Home'),
                    ],
                  ),
                  selected: _label == 'Home',
                  selectedColor: Colors.grey.shade300,
                  onSelected: (val) {
                    if (val) setState(() => _label = 'Home');
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Save / Next Button
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
                onPressed: _saveAddress,
                child: const Text(
                  'Next',
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

// Stateful Bottom Sheet Widget for Step-by-step Selection
class _LocationCascadePicker extends StatefulWidget {
  final Map<String, Map<String, Map<String, List<String>>>> phData;
  final Function(String region, String province, String city, String barangay) onCompleted;

  const _LocationCascadePicker({
    Key? key,
    required this.phData,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<_LocationCascadePicker> createState() => _LocationCascadePickerState();
}

class _LocationCascadePickerState extends State<_LocationCascadePicker> {
  int _step = 0; // 0: Region, 1: Province, 2: City, 3: Barangay
  String? _region;
  String? _province;
  String? _city;
  String? _barangay;

  @override
  Widget build(BuildContext context) {
    List<String> currentList = [];
    String title = 'Select Region';

    if (_step == 0) {
      title = 'Select Region';
      currentList = widget.phData.keys.toList();
    } else if (_step == 1 && _region != null) {
      title = 'Select Province in $_region';
      currentList = widget.phData[_region]!.keys.toList();
    } else if (_step == 2 && _region != null && _province != null) {
      title = 'Select City / Municipality';
      currentList = widget.phData[_region]![_province]!.keys.toList();
    } else if (_step == 3 && _region != null && _province != null && _city != null) {
      title = 'Select Barangay';
      currentList = widget.phData[_region]![_province]![_city]!;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_step > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _step--;
                    });
                  },
                ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              itemCount: currentList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = currentList[index];
                return ListTile(
                  title: Text(item, style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    if (_step == 0) {
                      _region = item;
                      _step = 1;
                    } else if (_step == 1) {
                      _province = item;
                      _step = 2;
                    } else if (_step == 2) {
                      _city = item;
                      _step = 3;
                    } else if (_step == 3) {
                      _barangay = item;
                      widget.onCompleted(_region!, _province!, _city!, _barangay!);
                      Navigator.pop(context);
                    }
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}