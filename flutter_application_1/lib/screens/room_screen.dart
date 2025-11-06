import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_task_screen.dart';

class RoomScreen extends StatefulWidget {
  final String roomCode;
  const RoomScreen({required this.roomCode, super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _controller = TextEditingController();
  String _selectedPriority = 'Low';

  final List<String> _quotes = [
    "Collaboration fuels innovation.",
    "Alone we can do so little; together we can do so much.",
    "Every idea counts — share it here!",
    "One room, one goal, one dream.",
    "Teamwork makes the dream work.",
    "Your effort adds value to the whole."
  ];
  late String _todayQuote;

  @override
  void initState() {
    super.initState();
    _todayQuote = _quotes[Random().nextInt(_quotes.length)];
  }

  Future<void> _addTask() async {
    if (_controller.text.isEmpty) return;
    await _db.collection('rooms').doc(widget.roomCode).collection('tasks').add({
      'title': _controller.text,
      'done': false,
      'priority': _selectedPriority,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': _auth.currentUser!.uid,
    });
    _controller.clear();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }

  Future<void> _leaveRoom() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Room"),
        content: const Text("Are you sure you want to leave this room?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _db.collection('rooms').doc(widget.roomCode).update({
      'members': FieldValue.arrayRemove([uid])
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _buildMemberAvatars(List members) {
    return FutureBuilder<QuerySnapshot>(
      future: _db.collection('users').where(FieldPath.documentId, whereIn: members).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 40);
        final users = snapshot.data!.docs;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var user in users)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserTaskScreen(
                          userId: user.id,
                          userName: user['name'] ?? 'Unnamed',
                          roomCode: widget.roomCode,
                          imageUrl: user['imageUrl'] ??
                              "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(
                      user['imageUrl'] ??
                          "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Room: ${widget.roomCode}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _leaveRoom,
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Leave Room",
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Text(
                _todayQuote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),

            StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('rooms').doc(widget.roomCode).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null || data['members'] == null) return const SizedBox();
                final members = List<String>.from(data['members']);
                if (members.isEmpty) return const SizedBox();
                return _buildMemberAvatars(members);
              },
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter a shared task',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPriority,
                      items: ['Low', 'Medium', 'High']
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p,
                                  style: TextStyle(
                                    color: _getPriorityColor(p),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPriority = v!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Shared task list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('rooms')
                    .doc(widget.roomCode)
                    .collection('tasks')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No shared tasks yet!',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  return ListView(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: data['done']
                            ? Colors.grey[200]
                            : _getPriorityColor(data['priority']).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: Checkbox(
                            value: data['done'],
                            activeColor: Colors.deepPurpleAccent,
                            onChanged: (val) {
                              _db
                                  .collection('rooms')
                                  .doc(widget.roomCode)
                                  .collection('tasks')
                                  .doc(doc.id)
                                  .update({'done': val});
                            },
                          ),
                          title: Text(
                            data['title'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              decoration: data['done']
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color:
                                  data['done'] ? Colors.grey : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            "Priority: ${data['priority']}",
                            style: TextStyle(
                              color: _getPriorityColor(data['priority'])
                                  .withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
