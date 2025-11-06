import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chatroom_screen.dart';
import 'screens/join_or_create_room.dart';
import 'screens/room_screen.dart';
import 'screens/my_rooms.dart'; // ✅ added
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do App',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/joinRoom': (context) => const JoinOrCreateRoom(),
        '/myRooms': (context) => const MyRoomsScreen(), // ✅ added
        '/room': (context) {
          final code = ModalRoute.of(context)!.settings.arguments as String;
          return RoomScreen(roomCode: code);
        },
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return const MainHomeScreen();
          }

          return LoginScreen(onLogin: () {});
        },
      ),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    TasksScreen(),
    ProfileScreen(),
    ChatroomScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Week #"),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: "Join/Create Room",
            onPressed: () => Navigator.pushNamed(context, '/joinRoom'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text("Menu",
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text("Tasks"),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text("Chatroom"),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text("Create / Join Room"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/joinRoom');
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room_rounded),
              title: const Text("My Rooms"), // ✅ direct access from drawer too
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/myRooms');
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
