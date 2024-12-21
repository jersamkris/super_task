// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  late Database database;

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
  }

  Future<void> _register() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      showDialog(
        context: this.context,
        builder: (context) => AlertDialog(
          title: Text('Registration Failed'),
          content: Text('Please fill in both username and password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await database.insert('users', {
        'username': usernameController.text,
        'password': passwordController.text,
      });

      showDialog(
        context: this.context,
        builder: (context) => AlertDialog(
          title: Text('Registration Successful'),
          content: Text('You can now login with your credentials.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: this.context,
        builder: (context) => AlertDialog(
          title: Text('Registration Failed'),
          content: Text('Username already exists.'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: _register,
                child: Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
