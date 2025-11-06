import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRoomsScreen extends StatelessWidget {
  const MyRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Rooms")),
        body: const Center(child: Text("Please login to see your rooms.")),
      );
    }

    final roomsQuery = FirebaseFirestore.instance
        .collection('rooms')
        .where('members', arrayContains: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: AppBar(
        title: const Text("My Rooms"),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: roomsQuery.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_rounded, size: 80, color: Colors.deepPurpleAccent.shade100),
                  const SizedBox(height: 20),
                  Text("No Rooms Yet 😔", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  const Text("Join or create one to get started!"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final id = d.id;
              final name = (d.data() as Map<String, dynamic>)['name'] ?? 'Unnamed Room';

              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/room', arguments: id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF00BCD4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.group, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                            Text("Code: $id", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ]),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 22),
                    ],
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
