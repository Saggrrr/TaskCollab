import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JoinOrCreateRoom extends StatefulWidget {
  const JoinOrCreateRoom({super.key});

  @override
  State<JoinOrCreateRoom> createState() => _JoinOrCreateRoomState();
}

class _JoinOrCreateRoomState extends State<JoinOrCreateRoom> {
  final _roomNameCtrl = TextEditingController();
  final _roomCodeCtrl = TextEditingController();
  final _db = FirebaseFirestore.instance;
  bool _loading = false;

  Future<void> createRoom() async {
    if (_roomNameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    String code = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    await _db.collection('rooms').doc(code).set({
      'name': _roomNameCtrl.text.trim(),
      'members': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() => _loading = false);
    Navigator.pushNamed(context, '/room', arguments: code);
  }

  Future<void> joinRoom() async {
    if (_roomCodeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    var code = _roomCodeCtrl.text.trim();
    var doc = await _db.collection('rooms').doc(code).get();
    setState(() => _loading = false);

    if (doc.exists) {
      Navigator.pushNamed(context, '/room', arguments: code);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("❌ Room not found")));
    }
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    context,
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
                    context,
                    title: "Join an Existing Room",
                    controller: _roomCodeCtrl,
                    hint: "Room Code",
                    buttonText: "Join Room",
                    icon: Icons.login_rounded,
                    color: Colors.green,
                    onPressed: joinRoom,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required String hint,
    required String buttonText,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

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
              style: theme.textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.bold)),
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
