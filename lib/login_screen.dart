import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'agent_commission_screen.dart';
import 'forgot_password_reset_screen.dart';
import 'manager_commission_screen.dart';
import 'register_screen.dart'; // ✅ Import Register Screen
import 'reset_password_screen.dart';

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
    _checkLoginStatus();
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

  /// **🔹 Normalize Phone Number**
  String _normalizePhoneNumber(String phoneNumber) {
    phoneNumber = phoneNumber.trim();
    if (phoneNumber.startsWith("0")) {
      return "233${phoneNumber.substring(1)}"; // Convert `024xxxxxxx` → `23324xxxxxxx`
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
          'phone_number': phoneNumber,
          'password': passwordController.text.trim(),
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        await storage.write(key: 'token', value: response.data['token'] ?? '');
        await storage.write(key: 'role', value: response.data['role'] ?? '');

        setState(() {
          isLoading = false;
        });

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
      } else {
        _handleInvalidLogin(null);
      }
    } on DioException catch (e) {
      print("❌ API Error: ${e.response?.data}");

      if (e.response?.statusCode == 403 &&
          e.response?.data['reset_required'] == true) {
        String token = e.response?.data['token'] ?? ''; // Get JWT token
        String phoneNumber = phoneController.text.trim();

        print("🔹 Navigating to Reset Password Screen...");

        setState(() {
          isLoading = false; // ✅ Ensure loading state resets before navigating
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              token: token, // ✅ JWT token to authenticate reset
              phoneNumber: phoneNumber, // ✅ Pass phone number
              isFirstTimeLogin: true, // ✅ Ensure flag is set
            ),
          ),
        );
        return;
      }

      _handleInvalidLogin(e);
    }
  }

  /// **🔹 Handle Invalid Login (Show Error & Reset Password Field)**
  void _handleInvalidLogin(DioException? e) {
    String errorMsg = "❌ Invalid phone number or password.";

    if (e != null && e.response?.data is Map<String, dynamic>) {
      errorMsg = e.response?.data['error'] ?? errorMsg;
    }

    setState(() {
      isLoading = false;
      errorMessage = errorMsg;
      passwordController.clear(); // ✅ Clear password field for re-entry
    });

    _showMessage(errorMsg); // ✅ Show Snackbar Message
  }

  /// **🔹 Forgot Password: Open Channel Selection Dialog**
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: const Text("How would you like to receive your reset code?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendForgotPasswordRequest("sms");
            },
            child: const Text("📱 SMS"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendForgotPasswordRequest("email");
            },
            child: const Text("📩 Email"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendForgotPasswordRequest("whatsapp");
            },
            child: const Text("💬 WhatsApp"),
          ),
        ],
      ),
    );
  }

  /// **🔹 Send Forgot Password Request & Redirect to Reset Token Entry Screen**
  Future<void> _sendForgotPasswordRequest(String channel) async {
    String phoneNumber = _normalizePhoneNumber(phoneController.text);

    if (phoneNumber.isEmpty) {
      _showMessage("❌ Please enter your phone number first.");
      return;
    }

    try {
      final response = await dio.post(
        '$baseUrl/forgot_password',
        data: {
          'phone_number': phoneNumber,
          'channel': channel,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      print("API Response: ${response.data}");

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        _showMessage("✅ Reset code sent via $channel!");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordResetScreen(
              phoneNumber: phoneNumber, // ✅ Pass the phone number
            ),
          ),
        );
      } else {
        _showMessage("❌ Unexpected response format.");
      }
    } on DioException catch (e) {
      print("Error: ${e.response?.data}");

      if (e.response?.data is Map<String, dynamic>) {
        _showMessage(
            "❌ ${e.response?.data['error'] ?? 'Something went wrong'}");
      } else {
        _showMessage("❌ Something went wrong.");
      }
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
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text("Forgot Password?"),
                ),
              ),
              const SizedBox(height: 10),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: const Text("Not yet registered? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
