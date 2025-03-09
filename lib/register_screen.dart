import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final Dio dio = Dio();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Future<void> registerAgent() async {
    if (!_formKey.currentState!.validate()) return;

    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();
    String phoneNumber = phoneController.text.trim();
    String password = passwordController.text.trim();

    try {
      Response response = await dio.post(
        '$baseUrl/register',
        data: {
          "first_name": firstName,
          "last_name": lastName,
          "phone_number": phoneNumber,
          "password": password,
        },
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Registration successful! Please log in."),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context); // Go back to login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ ${response.data['error']}"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("❌ Registration failed."),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
                validator: (value) =>
                    value!.trim().isEmpty ? "Enter first name" : null,
              ),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
                validator: (value) =>
                    value!.trim().isEmpty ? "Enter last name" : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.trim().isEmpty ? "Enter phone number" : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) {
                  if (value!.trim().length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
                obscureText: true,
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Confirm your password";
                  }
                  if (value.trim() != passwordController.text.trim()) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerAgent,
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
