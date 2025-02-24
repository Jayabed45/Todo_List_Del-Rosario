import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter To-Do List',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        primarySwatch: Colors.teal,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<String> _tasks = [];
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tasksString = prefs.getString('tasks');
      if (tasksString != null) {
        setState(() {
          _tasks.addAll(List<String>.from(json.decode(tasksString)));
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to load tasks: $e');
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('tasks', json.encode(_tasks));
    } catch (e) {
      _showErrorDialog('Failed to save tasks: $e');
    }
  }

  void _addTask(String task) {
    if (task.isNotEmpty) {
      setState(() {
        _tasks.add(task);
        _listKey.currentState?.insertItem(_tasks.length - 1);
      });
      _saveTasks();
      _textController.clear();
    }
  }

  void _editTask(int index, String newTask) {
    if (newTask.isNotEmpty) {
      setState(() {
        _tasks[index] = newTask;
      });
      _saveTasks();
    }
  }

  void _removeTask(int index) {
    setState(() {
      String removedTask = _tasks.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildTaskItem(removedTask, index, animation),
      );
    });
    _saveTasks();
  }

  Future<void> _showAddTaskDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Add a new task',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter a task',
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.teal),
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.tealAccent),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                _textController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Add', style: TextStyle(color: Colors.tealAccent)),
              onPressed: () {
                _addTask(_textController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditTaskDialog(int index) async {
    _textController.text = _tasks[index];
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Edit task', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Edit your task',
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.teal),
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.tealAccent),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                _textController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save',
                  style: TextStyle(color: Colors.tealAccent)),
              onPressed: () {
                _editTask(index, _textController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF181818),
        elevation: 6.0,
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _tasks.length,
              itemBuilder: (context, index, animation) {
                return _buildTaskItem(_tasks[index], index, animation);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildTaskItem(String task, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 3,
        child: ListTile(
          leading: const Icon(Icons.task_alt, color: Colors.tealAccent),
          title: Text(task, style: const TextStyle(color: Colors.white)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.tealAccent),
                onPressed: () => _showEditTaskDialog(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _removeTask(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error', style: TextStyle(color: Colors.redAccent)),
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2A2A2A),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('OK', style: TextStyle(color: Colors.tealAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
