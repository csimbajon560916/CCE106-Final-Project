import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateStoreAdminScreen extends StatefulWidget {
  const CreateStoreAdminScreen({Key? key}) : super(key: key);

  @override
  State<CreateStoreAdminScreen> createState() => _CreateStoreAdminScreenState();
}

class _CreateStoreAdminScreenState extends State<CreateStoreAdminScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _hubNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createStoreAdminAccount() async {
    setState(() => _isLoading = true);
    try {
      // Secondary App to preserve Main Admin Login
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryAppAdmin',
        options: Firebase.app().options,
      );

      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential userCredential = await secondaryAuth
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String storeAdminUid = userCredential.user!.uid;

      // Save Store Admin Info
      await FirebaseFirestore.instance
          .collection('users')
          .doc(storeAdminUid)
          .set({
        'uid': storeAdminUid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'store_admin',
        'hubName': _hubNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryApp.delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store Admin Created Successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Station/Store Admin')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Admin Name')),
            TextField(controller: _hubNameController, decoration: const InputDecoration(labelText: 'Assigned Hub/Station Name (e.g. Dumoy Hub)')),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Admin Email')),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                    onPressed: _createStoreAdminAccount,
                    child: const Text('Create Store Admin'),
                  ),
          ],
        ),
      ),
    );
  }
}