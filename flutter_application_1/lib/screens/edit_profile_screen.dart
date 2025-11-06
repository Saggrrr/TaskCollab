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
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    // Using imageQuality to reduce file size before upload (Recommended fix for slowness)
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); 

    if (picked != null) {
      setState(() {
        pickedImageFile = File(picked.path);
      });
    }
  }

  // Helper function for uploading image
  Future<String> _uploadImage(String uid, File imageFile) async {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
  }

  // Helper function for updating Firebase data
  Future<void> _updateProfileData(User user, String newName, String finalImageUrl) async {
      // 1. Update Firebase Auth Profile (CRITICAL for ProfileScreen)
      await user.updateDisplayName(newName);
      await user.updatePhotoURL(finalImageUrl);

      // 2. Update Firestore (Database Record)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': newName,
        'imageUrl': finalImageUrl,
      }, SetOptions(merge: true));
  }
  
  Future<void> save() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _nameController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    String finalImageUrl = widget.currentImageUrl;
    final newName = _nameController.text.trim();

    try {
        // Wrap all save operations and enforce a 20-second timeout
        await Future.wait([
          // Only include the upload if a new image was picked
          if (pickedImageFile != null) 
            _uploadImage(user.uid, pickedImageFile!).then((url) => finalImageUrl = url),

          // Update Firestore and Auth Profile
          _updateProfileData(user, newName, finalImageUrl),

        ]).timeout(const Duration(seconds: 20), onTimeout: () {
             throw Exception('Profile save operation timed out. Check network or rules.');
        });
        
        // Final screen exit after all saves are complete
        if (mounted) {
            Navigator.pop(context, {
                "name": newName,
                "imageUrl": finalImageUrl
            });
        }

    } catch (error) {
        // Print error to console for debugging security rules/network issues
        print('Profile Save Error: $error'); 
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to save profile. Check your Firebase Rules.')),
            );
        }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
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
              onTap: _isLoading ? null : pickImage,
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
              enabled: !_isLoading, 
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : save, // Disable button if loading
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: _isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : const Text("Save", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}