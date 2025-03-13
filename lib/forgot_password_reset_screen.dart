import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'login_screen.dart';

class ForgotPasswordResetScreen extends StatefulWidget {
  final String phoneNumber;

  const ForgotPasswordResetScreen({super.key, required this.phoneNumber});

  @override
  _ForgotPasswordResetScreenState createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final storage = FlutterSecureStorage();
  final Dio dio = Dio();

  bool isLoading = false;
  String? errorMessage;

  final String baseUrl = "https://pdf-manager-eygj.onrender.com";

  /// **🔹 Handle Password Reset Request**
  Future<void> resetPassword() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String token = tokenController.text.trim();
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (token.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        errorMessage = "❌ All fields are required.";
        isLoading = false;
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        errorMessage = "❌ Password must be at least 6 characters.";
        isLoading = false;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        errorMessage = "❌ Passwords do not match.";
        isLoading = false;
      });
      return;
    }

    try {
      final response = await dio.post(
        '$baseUrl/reset_password',
        data: {
          'phone_number': widget.phoneNumber,
          'token': token,
          'new_password': newPassword,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        _showMessage("✅ Password reset successful! Please log in.");

        // ✅ Clear stored reset token
        await storage.delete(key: 'reset_token');

        // ✅ Redirect to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        setState(() {
          errorMessage = "❌ Failed to reset password.";
        });
      }
    } on DioException catch (e) {
      setState(() {
        errorMessage = e.response?.data['error'] ?? "❌ Something went wrong.";
        isLoading = false;
      });
    }
  }

  /// **🔹 Show Snackbar Message**
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
              const Text(
                "Reset Password",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(labelText: 'Reset Token'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: resetPassword,
                      child: const Text('Reset Password'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
