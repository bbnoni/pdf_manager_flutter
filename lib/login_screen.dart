import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'agent_screen.dart';
import 'manager_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final storage = FlutterSecureStorage();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Dio dio = Dio();

  bool isLoading = false;
  String? errorMessage;

  // 🔹 Use your Render backend URL
  final String baseUrl = "https://pdf-manager-eygj.onrender.com";

  void login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await dio.post(
        '$baseUrl/login',
        data: {
          'username': usernameController.text.trim(),
          'password': passwordController.text.trim(),
        },
        options: Options(headers: {
          "Content-Type": "application/json",
        }),
      );

      if (response.statusCode == 200) {
        await storage.write(key: 'token', value: response.data['token']);
        await storage.write(key: 'role', value: response.data['role']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => response.data['role'] == 'manager'
                ? ManagerScreen()
                : AgentScreen(),
          ),
        );
      }
    } on DioException catch (e) {
      setState(() {
        isLoading = false;
        if (e.response != null && e.response!.statusCode == 401) {
          errorMessage = "Invalid username or password.";
        } else {
          errorMessage = "Failed to connect. Please try again.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: login,
                      child: Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
