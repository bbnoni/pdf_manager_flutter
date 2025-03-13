import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class ResetPasswordScreen extends StatefulWidget {
  final String token; // 🔹 Use token for authentication
  const ResetPasswordScreen(
      {super.key, required this.token, required String phoneNumber});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final Dio dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      Response response = await dio.post(
        '$baseUrl/reset_password',
        data: {
          "new_password": _newPasswordController.text.trim(),
        },
        options: Options(
          headers: {
            "Authorization": "Bearer ${widget.token}", // 🔹 Use token for auth
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        // 🔹 Store new token after reset
        await storage.write(key: 'token', value: response.data['token']);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Password reset successful! Please log in."),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context); // Go back to login
      } else {
        setState(() {
          errorMessage = response.data['error'] ?? "❌ Password reset failed.";
        });
      }
    } on DioException catch (e) {
      setState(() {
        errorMessage = e.response?.data['error'] ?? "❌ Password reset failed.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter a new password for your account.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: "New Password"),
                obscureText: true,
                validator: (value) {
                  if (value!.trim().isEmpty) return "Enter a password";
                  if (value.trim().length < 6) return "Min 6 characters";
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
                obscureText: true,
                validator: (value) {
                  if (value!.trim().isEmpty) return "Confirm your password";
                  if (value.trim() != _newPasswordController.text.trim()) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: ElevatedButton(
                        onPressed: resetPassword,
                        child: const Text("Reset Password"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
