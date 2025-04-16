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

  bool isLoading = false; // ✅ Track loading state

  Future<void> registerAgent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

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
          "role": "agent",
        },
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Registration successful! Please log in."),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      final res = e.response;

      if (res?.statusCode == 403 &&
          res?.data != null &&
          res?.data!['reset_required'] == true) {
        final phone = res?.data['phone_number'];
        final inputFirstName = firstNameController.text.trim();
        final inputLastName = lastNameController.text.trim();
        final inputPassword = passwordController.text.trim();

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Complete Registration"),
            content: Text(
              "This number is already registered but not completed.\n\n"
              "Use the following to complete registration?\n\n"
              "First Name: $inputFirstName\n"
              "Last Name: $inputLastName\n"
              "Password: $inputPassword",
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text("Yes, Complete"),
                onPressed: () async {
                  Navigator.pop(context, true); // close dialog immediately
                },
              )
            ],
          ),
        );

        if (confirmed == true) {
          final token = await showDialog<String>(
            context: context,
            builder: (context) {
              final tokenController = TextEditingController();
              return AlertDialog(
                title: const Text("Verify Registration"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Enter the 6-digit code sent to your phone"),
                    TextField(
                      controller: tokenController,
                      decoration: const InputDecoration(labelText: "Token"),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, tokenController.text.trim()),
                    child: const Text("Submit"),
                  ),
                ],
              );
            },
          );

          if (token == null || token.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("❌ Token required to complete registration."),
              backgroundColor: Colors.red,
            ));
            return;
          }

          try {
            final completeResponse = await dio.post(
              '$baseUrl/complete_registration',
              data: {
                "phone_number": phone,
                "first_name": inputFirstName,
                "last_name": inputLastName,
                "password": inputPassword,
                "token": token, // ✅ Add the reset token to payload
              },
            );

            if (completeResponse.statusCode == 200) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("✅ Registration completed! Please log in."),
                backgroundColor: Colors.green,
              ));
              Navigator.pop(context); // Go back to login
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    "❌ ${completeResponse.data['error'] ?? 'Failed to complete registration.'}"),
                backgroundColor: Colors.red,
              ));
            }
          } on DioException catch (err) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "❌ ${err.response?.data['error'] ?? 'Completion failed.'}"),
              backgroundColor: Colors.red,
            ));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ ${res?.data['error'] ?? 'Registration failed.'}"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() {
        isLoading = false;
      });
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
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: isLoading ? null : registerAgent,
                      child: const Text("Register"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
