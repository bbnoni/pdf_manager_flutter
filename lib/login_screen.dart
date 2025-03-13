import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'agent_commission_screen.dart';
import 'manager_commission_screen.dart';
import 'register_screen.dart'; // 🔹 Ensure correct import
import 'reset_password_screen.dart'; // 🔹 Import Reset Password Screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final storage = FlutterSecureStorage();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Dio dio = Dio();

  bool isLoading = false;
  String? errorMessage;

  final String baseUrl = "https://pdf-manager-eygj.onrender.com";

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // 🔹 Check if user is already logged in
  }

  /// **🔹 Check if user is already logged in**
  Future<void> _checkLoginStatus() async {
    String? token = await storage.read(key: 'token');
    String? role = await storage.read(key: 'role');

    if (token != null && role != null) {
      Future.delayed(Duration.zero, () {
        if (role == 'manager') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const ManagerCommissionScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const AgentCommissionScreen()),
          );
        }
      });
    }
  }

  /// **🔹 Normalize Phone Number (Handles `024xxxxxxx` and `23324xxxxxxx`)**
  String _normalizePhoneNumber(String phoneNumber) {
    phoneNumber = phoneNumber.trim();
    if (phoneNumber.startsWith("0")) {
      return "233${phoneNumber.substring(1)}"; // Remove `0` and add `233`
    }
    return phoneNumber;
  }

  /// **🔹 Handle User Login**
  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String phoneNumber = _normalizePhoneNumber(phoneController.text);

    try {
      final response = await dio.post(
        '$baseUrl/login',
        data: {
          'phone_number': phoneNumber, // ✅ Send normalized phone number
          'password': passwordController.text.trim(),
        },
        options: Options(headers: {
          "Content-Type": "application/json",
        }),
      );

      if (response.statusCode == 200) {
        await storage.write(key: 'token', value: response.data['token']);
        await storage.write(key: 'role', value: response.data['role']);

        // Redirect based on role
        if (response.data['role'] == 'manager') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const ManagerCommissionScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const AgentCommissionScreen()),
          );
        }
      }
    } on DioException catch (e) {
      setState(() {
        isLoading = false;
      });

      if (e.response != null) {
        if (e.response!.statusCode == 403 &&
            e.response!.data['reset_required'] == true) {
          // 🔹 Store token before navigating
          await storage.write(key: 'token', value: e.response!.data['token']);

          // 🔹 Redirect user to Reset Password screen with JWT token
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ResetPasswordScreen(token: e.response!.data['token'])),
          );
        } else if (e.response!.statusCode == 401) {
          errorMessage = "❌ Invalid phone number or password.";
        } else {
          errorMessage = "❌ Failed to connect. Please try again.";
        }
      } else {
        errorMessage = "❌ Server unreachable. Check your internet connection.";
      }
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
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: login,
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Navigate to RegisterScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RegisterScreen()), // 🔹 Fix here
                  );
                },
                child: const Text(
                  "Not yet registered? Sign up",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
