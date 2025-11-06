import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _controller = TextEditingController();
  String _selectedPriority = 'Low';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _uid;
  bool _isLoading = true;

  final List<String> _quotes = [
    "Small steps every day lead to big changes.",
    "Focus on progress, not perfection.",
    "One task at a time, one day at a time.",
    "Dream big. Start small. Act now.",
    "Consistency beats motivation.",
    "Your future is created by what you do today.",
  ];
  late String _todayQuote;

  @override
  void initState() {
    super.initState();
    _todayQuote = _quotes[Random().nextInt(_quotes.length)];
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _uid = user.uid;
        _isLoading = false;
      });
    } else {
      _auth.authStateChanges().listen((user) {
        if (user != null && mounted) {
          setState(() {
            _uid = user.uid;
            _isLoading = false;
          });
        }
      });
    }
  }

  Future<void> _addTask() async {
    if (_controller.text.isEmpty || _uid == null) return;

    await _db.collection('tasks').add({
      'title': _controller.text,
      'done': false,
      'priority': _selectedPriority,
      'userId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Tasks'),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(
                    backgroundImage:
                        NetworkImage('https://i.pravatar.cc/150?img=1'),
                    radius: 22),
                SizedBox(width: 8),
                CircleAvatar(
                    backgroundImage:
                        NetworkImage('https://i.pravatar.cc/150?img=2'),
                    radius: 22),
                SizedBox(width: 8),
                CircleAvatar(
                    backgroundImage:
                        NetworkImage('https://i.pravatar.cc/150?img=3'),
                    radius: 22),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter a task',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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
                      onChanged: (v) =>
                          setState(() => _selectedPriority = v!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[700],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('tasks')
                    .where('userId', isEqualTo: _uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tasks yet. Add one!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: data['done']
                            ? Colors.grey[200]
                            : _getPriorityColor(data['priority'])
                                .withOpacity(0.35),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: Checkbox(
                            value: data['done'],
                            activeColor: Colors.greenAccent[700],
                            onChanged: (val) {
                              _db
                                  .collection('tasks')
                                  .doc(docs[index].id)
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
                              color: data['done'] ? Colors.grey : Colors.black87,
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
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () {
                              _db
                                  .collection('tasks')
                                  .doc(docs[index].id)
                                  .delete();
                            },
                          ),
                        ),
                      );
                    },
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
