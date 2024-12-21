// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Task',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Database database;
  List<Map<String, dynamic>> tasks = [];
  var roundCorner = 8.0;
  var dateFormat = 'd MMM yyyy, hh:mm';

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'tasks.db'),
      version: 1,
    );
    _refreshTasks();
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(this.context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _refreshTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    final data = await database.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    setState(() {
      tasks = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Task'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(roundCorner),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      containerTitle('My Task'),
                      ...tasks.where((task) => task['isDone'] == 0).map((task) {
                        return buildTaskCard(
                          task: task,
                          onCheckboxChanged: (value) {
                            _updateTask(
                                task['id'],
                                task['title'],
                                task['description'],
                                value ? 1 : 0,
                                task['date']);
                          },
                          onDelete: () {
                            _deleteTask(task['id']);
                          },
                          onTap: () => _showTaskDialog(task: task),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 16.0),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(roundCorner),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      containerTitle('Completed'),
                      ...tasks.where((task) => task['isDone'] == 1).map((task) {
                        return buildTaskCard(
                          task: task,
                          onCheckboxChanged: (value) {
                            _updateTask(
                                task['id'],
                                task['title'],
                                task['description'],
                                value ? 1 : 0,
                                task['date']);
                          },
                          onDelete: () {
                            _deleteTask(task['id']);
                          },
                          onTap: () => _showTaskDialog(task: task),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget containerTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Text(
        title,
        style: Theme.of(this.context).textTheme.titleMedium,
      ),
    );
  }

  Widget buildTaskCard({
    required Map<String, dynamic> task,
    required Function(bool) onCheckboxChanged,
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        title: Text(
          task['title'],
          style: TextStyle(
            decoration: task['isDone'] == 1
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['description']),
            if (task['date'] != null)
              Text(
                DateFormat(dateFormat).format(DateTime.parse(task['date'])),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        leading: Checkbox(
          value: task['isDone'] == 1,
          onChanged: (value) => onCheckboxChanged(value!),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          icon: Icon(Icons.more_vert),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showTaskDialog({Map<String, dynamic>? task}) {
    final TextEditingController titleController = TextEditingController(
      text: task != null ? task['title'] : '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: task != null ? task['description'] : '',
    );
    final TextEditingController dateController = TextEditingController(
      text: task != null
          ? DateFormat(dateFormat).format(DateTime.parse(task['date']))
          : '',
    );

    showDialog(
      context: this.context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundCorner),
          ),
          title: Text(task == null ? 'New Task' : 'Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(roundCorner),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(roundCorner),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date & Time',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(roundCorner),
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: this.context,
                      initialDate: task != null
                          ? DateTime.parse(task['date'])
                          : DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: this.context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTime != null) {
                        final DateTime fullDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );

                        dateController.text = DateFormat(dateFormat).format(
                            DateTime.parse(fullDateTime.toIso8601String()));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    dateController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('All fields are required')),
                  );
                  return;
                }

                DateTime parsedDate =
                    DateFormat(dateFormat).parse(dateController.text);
                String iso8601Date = parsedDate.toIso8601String();

                if (task == null) {
                  _addTask(
                    titleController.text,
                    descriptionController.text,
                    iso8601Date,
                  );
                } else {
                  _updateTask(
                    task['id'],
                    titleController.text,
                    descriptionController.text,
                    task['isDone'],
                    iso8601Date,
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addTask(String title, String description, String date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    await database.insert('tasks', {
      'user_id': userId,
      'title': title,
      'description': description,
      'isDone': 0,
      'date': date,
    });
    _refreshTasks();
  }

  Future<void> _updateTask(
      int id, String title, String description, int isDone, String date) async {
    await database.update(
      'tasks',
      {
        'title': title,
        'description': description,
        'isDone': isDone,
        'date': date,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _refreshTasks();
  }

  Future<void> _deleteTask(int id) async {
    await database.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    _refreshTasks();
  }
}
