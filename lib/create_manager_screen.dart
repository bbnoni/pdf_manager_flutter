import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class CreateManagerScreen extends StatefulWidget {
  const CreateManagerScreen({super.key});

  @override
  _CreateManagerScreenState createState() => _CreateManagerScreenState();
}

class _CreateManagerScreenState extends State<CreateManagerScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;

  /// **Create New Manager**
  Future<void> _createManager() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _phoneNumberController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage("⚠️ All fields are required.");
      return;
    }

    String? token = await storage.read(key: "token");
    if (token == null) {
      _showMessage("❌ ERROR: No JWT token found. Please log in again.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      Response response = await dio.post(
        '$baseUrl/register',
        data: {
          "first_name": _firstNameController.text.trim(),
          "last_name": _lastNameController.text.trim(),
          "phone_number": _phoneNumberController.text.trim(),
          "password": _passwordController.text.trim(),
          "role": "manager", // Ensure new user is a manager
          "first_login": true, // ✅ Force first login reset
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 201) {
        _showMessage(
            "✅ Manager created successfully! First login reset required.");
        _clearFields();
      } else {
        _showMessage("❌ Failed to create manager.");
      }
    } on DioException catch (e) {
      _showMessage("❌ Error: ${e.response?.data?['error'] ?? 'Unknown error'}");
    } catch (e) {
      _showMessage("❌ Something went wrong. Please try again.");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// **Clear Input Fields After Submission**
  void _clearFields() {
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneNumberController.clear();
    _passwordController.clear();
  }

  /// **Show Message**
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Manager")),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 3,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Register a New Manager",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _buildTextField(_firstNameController, "First Name", Icons.person),
              const SizedBox(height: 10),
              _buildTextField(
                  _lastNameController, "Last Name", Icons.person_outline),
              const SizedBox(height: 10),
              _buildTextField(
                  _phoneNumberController, "Phone Number", Icons.phone,
                  isNumber: true),
              const SizedBox(height: 10),
              _buildTextField(_passwordController, "Password", Icons.lock,
                  isPassword: true),

              const SizedBox(height: 20),

              /// **Submit Button**
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _createManager,
                      icon: const Icon(Icons.add),
                      label: const Text("Create Manager"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Reusable Text Field**
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }
}
