import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinOrCreateRoom extends StatefulWidget {
  const JoinOrCreateRoom({super.key});

  @override
  State<JoinOrCreateRoom> createState() => _JoinOrCreateRoomState();
}

class _JoinOrCreateRoomState extends State<JoinOrCreateRoom> {
  final TextEditingController _roomNameCtrl = TextEditingController();
  final TextEditingController _roomCodeCtrl = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _loading = false;

  Future<void> createRoom() async {
    if (_roomNameCtrl.text.trim().isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    String code =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);

    await _db.collection('rooms').doc(code).set({
      'name': _roomNameCtrl.text.trim(),
      'members': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/room', arguments: code);
  }

  Future<void> joinRoom() async {
    if (_roomCodeCtrl.text.trim().isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    String code = _roomCodeCtrl.text.trim();
    DocumentSnapshot doc = await _db.collection('rooms').doc(code).get();

    setState(() => _loading = false);

    if (doc.exists) {
      await _db.collection('rooms').doc(code).update({
        'members': FieldValue.arrayUnion([uid])
      });
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/room', arguments: code);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Room not found")),
      );
    }
  }

  void viewMyRooms() {
    Navigator.pushNamed(context, '/myRooms');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        title: const Text("Join or Create Room"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.groups_rounded,
                      size: 90, color: Colors.blueAccent.shade100),
                  const SizedBox(height: 20),
                  Text(
                    "Collaborate Instantly",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  _buildCard(
                    title: "Create a Room",
                    controller: _roomNameCtrl,
                    hint: "Room Name",
                    buttonText: "Create Room",
                    icon: Icons.add_circle_outline,
                    color: Colors.blueAccent,
                    onPressed: createRoom,
                  ),
                  const SizedBox(height: 30),
                  Text("or",
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 30),
                  _buildCard(
                    title: "Join an Existing Room",
                    controller: _roomCodeCtrl,
                    hint: "Room Code",
                    buttonText: "Join Room",
                    icon: Icons.login_rounded,
                    color: Colors.green,
                    onPressed: joinRoom,
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF00BCD4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.meeting_room_rounded,
                            size: 50, color: Colors.white),
                        const SizedBox(height: 10),
                        const Text(
                          "View My Rooms",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: viewMyRooms,
                            icon: const Icon(Icons.arrow_forward_ios_rounded),
                            label: const Text("Open My Rooms"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required TextEditingController controller,
    required String hint,
    required String buttonText,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
