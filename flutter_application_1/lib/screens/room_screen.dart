import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomScreen extends StatefulWidget {
  final String roomCode;
  const RoomScreen({required this.roomCode});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _db = FirebaseFirestore.instance;
  final _taskCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  // Add a task
  Future<void> addTask() async {
    if (_taskCtrl.text.trim().isEmpty) return;
    await _db
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('tasks')
        .add({
      'text': _taskCtrl.text,
      'done': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _taskCtrl.clear();
  }

  // Add a message
  Future<void> sendMsg() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    await _db
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('messages')
        .add({
      'text': _msgCtrl.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Room: ${widget.roomCode}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _db
                  .collection('rooms')
                  .doc(widget.roomCode)
                  .collection('tasks')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView(
                  children: docs
                      .map((d) => ListTile(
                            title: Text(d['text']),
                            trailing: Checkbox(
                              value: d['done'],
                              onChanged: (v) => d.reference.update({'done': v}),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _taskCtrl, decoration: InputDecoration(hintText: "Add task..."))),
                IconButton(onPressed: addTask, icon: Icon(Icons.add)),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: StreamBuilder(
              stream: _db
                  .collection('rooms')
                  .doc(widget.roomCode)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox();
                var msgs = snapshot.data!.docs;
                return ListView(
                  children: msgs.map((m) => ListTile(title: Text(m['text']))).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _msgCtrl, decoration: InputDecoration(hintText: "Send message..."))),
                IconButton(onPressed: sendMsg, icon: Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
