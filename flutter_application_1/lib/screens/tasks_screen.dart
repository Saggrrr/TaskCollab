import 'package:flutter/material.dart';
import 'dart:math';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  String _selectedPriority = 'Low';

  // 🌟 Quote list
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
    final random = Random();
    _todayQuote = _quotes[random.nextInt(_quotes.length)];
  }

  void _addTask() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _tasks.add({
          'title': _controller.text,
          'done': false,
          'priority': _selectedPriority,
        });
        _controller.clear();
      });
    }
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

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['done'] = !_tasks[index]['done'];
      _tasks.sort((a, b) => a['done'] == b['done'] ? 0 : (a['done'] ? 1 : -1));
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  void _reorderTasks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final task = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, task);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // 🌟 Daily Quote Header
            Center(
              child: Text(
                _todayQuote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 👥 Collaborators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
                  radius: 22,
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=2'),
                  radius: 22,
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'),
                  radius: 22,
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Task input + priority
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
                      dropdownColor: Colors.white,
                      value: _selectedPriority,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      items: [
                        DropdownMenuItem(
                          value: 'Low',
                          child: Text(
                            'Low',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Medium',
                          child: Text(
                            'Medium',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'High',
                          child: Text(
                            'High',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Task list with draggable behavior
            Expanded(
              child: Listener(
                onPointerMove: (_) {}, // Prevents crash on desktop drag
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: _tasks.length,
                  onReorder: _reorderTasks,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return LongPressDraggable<int>(
                      key: ValueKey(task),
                      data: index,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.scale(
                          scale: 1.05,
                          child: Opacity(
                            opacity: 0.95,
                            child: _buildTaskCard(task, index),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildTaskCard(task, index),
                      ),
                      child: _buildReorderableCard(task, index),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableCard(Map<String, dynamic> task, int index) {
    return ReorderableDelayedDragStartListener(
      index: index,
      child: _buildTaskCard(task, index),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: task['done']
          ? Colors.grey[200]
          : _getPriorityColor(task['priority']).withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Checkbox(
          value: task['done'],
          activeColor: Colors.greenAccent[700],
          onChanged: (_) => _toggleTask(index),
        ),
        title: Text(
          task['title'],
          style: TextStyle(
            fontSize: 16,
            decoration:
                task['done'] ? TextDecoration.lineThrough : TextDecoration.none,
            color: task['done'] ? Colors.grey : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          "Priority: ${task['priority']}",
          style: TextStyle(
            color: _getPriorityColor(task['priority']).withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _deleteTask(index),
        ),
      ),
    );
  }
}
