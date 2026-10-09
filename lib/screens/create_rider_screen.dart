import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRiderScreen extends StatefulWidget {
  final String storeHubId; // Hub ID of the Store Admin

  const CreateRiderScreen({Key? key, required this.storeHubId}) : super(key: key);

  @override
  State<CreateRiderScreen> createState() => _CreateRiderScreenState();
}

class _CreateRiderScreenState extends State<CreateRiderScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createRiderAccount() async {
    setState(() => _isLoading = true);
    try {
      // Create secondary Firebase App instance so Store Admin isn't logged out
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 1. Create Rider Credentials on Secondary App
      UserCredential userCredential = await secondaryAuth
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String riderUid = userCredential.user!.uid;

      // 2. Save Rider Profile with 'rider' role linked to store hub
      await FirebaseFirestore.instance.collection('users').doc(riderUid).set({
        'uid': riderUid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'rider',
        'hubId': widget.storeHubId,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Terminate secondary app after creation
      await secondaryApp.delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider account created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create rider: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Rider')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Rider Full Name')),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Rider Email')),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Temporary Password')),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: _createRiderAccount,
                    child: const Text('Create Rider Account'),
                  ),
          ],
        ),
      ),
    );
  }
}