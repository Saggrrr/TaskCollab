// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Get the current user reference
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  // State variables initialized from Firebase User
  String? userName;
  String userImage = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png"; 
  String userEmail = FirebaseAuth.instance.currentUser?.email ?? "No Email";

  @override
  void initState() {
    super.initState();
    // Load the initial name and image from the persisted Firebase data
    userName = _currentUser?.displayName;
    userImage = _currentUser?.photoURL ?? userImage; 
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    // Clears the navigation stack and pushes to the login route
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 50,
              // Use a Key to force the image to reload if the URL changes
              key: ValueKey(userImage), 
              backgroundImage: NetworkImage(userImage),
            ),
            const SizedBox(height: 20),

            // Show name or ask to set it
            Text(
              userName ?? "No name set",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),
            Text(
              userEmail,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'LOGOUT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // EDIT / SET NAME BUTTON
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      currentName: userName ?? "",
                      currentImageUrl: userImage,
                    ),
                  ),
                );

                // When result is received, update the local state
                if (result != null && mounted) {
                  setState(() {
                    userName = result["name"];
                    userImage = result["imageUrl"];
                  });
                }
              },
              icon: const Icon(Icons.edit),
              label: Text(userName == null ? 'Set Name' : 'Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}