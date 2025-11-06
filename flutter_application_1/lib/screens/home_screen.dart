import 'package:flutter/material.dart';
import 'tasks_screen.dart';
import 'profile_screen.dart';
import 'chatroom_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    TasksScreen(),
    ProfileScreen(),
    ChatroomScreen(),
  ];

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Personal Tasks'),
              onTap: () => _selectPage(0),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => _selectPage(1),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chatroom'),
              onTap: () => _selectPage(2),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Create / Join Room'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/joinRoom');
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
