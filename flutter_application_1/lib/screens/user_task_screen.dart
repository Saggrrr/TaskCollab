import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTaskScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String roomCode;
  final String imageUrl;

  const UserTaskScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.roomCode,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final _db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text("$userName's Tasks"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('rooms')
            .doc(roomCode)
            .collection('tasks')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs;
          if (tasks.isEmpty) {
            return Center(
              child: Text("$userName hasn't added any tasks yet."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final data = tasks[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                  title: Text(data['title']),
                  subtitle: Text("Priority: ${data['priority']}"),
                  trailing: Icon(
                    data['done']
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: data['done'] ? Colors.green : Colors.grey,
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
