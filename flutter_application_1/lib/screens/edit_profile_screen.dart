// edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentImageUrl;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentImageUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  File? pickedImageFile;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        pickedImageFile = File(picked.path);
      });
    }
  }

  Future<void> save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    String finalImageUrl = widget.currentImageUrl;

    // Upload new image if selected
    if (pickedImageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      await ref.putFile(pickedImageFile!);
      finalImageUrl = await ref.getDownloadURL();
    }

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _nameController.text.trim(),
      'imageUrl': finalImageUrl,
    }, SetOptions(merge: true));

    // Return updated values to previous screen
    Navigator.pop(context, {
      "name": _nameController.text.trim(),
      "imageUrl": finalImageUrl
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: pickedImageFile != null
                    ? FileImage(pickedImageFile!)
                    : NetworkImage(widget.currentImageUrl) as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: save,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
