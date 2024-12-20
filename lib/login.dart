// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'main.dart';
import 'registration.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  late Database database;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
    _initDatabase();
  }

  Future<void> _checkLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    if (userId != null) {
      Navigator.of(this.context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    }
  }

  Future<void> _initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'tasks.db'),
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) {
        db.execute(
          '''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE,
          password TEXT
        )
        ''',
        );

        db.execute(
          '''
        CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          description TEXT,
          isDone INTEGER,
          user_id INTEGER,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
        ''',
        );
      },
      version: 1,
    );
  }

  Future<void> _login() async {
    final List<Map<String, dynamic>> result = await database.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [usernameController.text, passwordController.text],
    );

    if (result.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', result.first['id']);

      Navigator.of(this.context).pushReplacement(
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } else {
      showDialog(
        context: this.context,
        builder: (context) => AlertDialog(
          title: Text('Login Failed'),
          content: Text('Invalid username or password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Enter your username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Enter your password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _login,
                child: Text('Login', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RegistrationPage()),
                ),
                child: Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
