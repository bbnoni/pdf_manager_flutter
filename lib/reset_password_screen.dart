import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'login_screen.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final String phoneNumber;
  final bool isFirstTimeLogin; // ✅ Track if it's a first-time login reset

  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.phoneNumber,
    required this.isFirstTimeLogin,
  });

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
  final TextEditingController _tokenController = TextEditingController();

  // ✅ First-time login name controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 🟡 Print data before sending
      print({
        "phone_number": widget.phoneNumber,
        "new_password": _newPasswordController.text.trim(),
        if (widget.isFirstTimeLogin) ...{
          "first_name": _firstNameController.text.trim(),
          "last_name": _lastNameController.text.trim(),
        },
        if (!widget.isFirstTimeLogin) "token": _tokenController.text.trim(),
      });

      Response response = await dio.post(
        '$baseUrl/reset_password',
        data: {
          "phone_number": widget.phoneNumber,
          "new_password": _newPasswordController.text.trim(),
          if (widget.isFirstTimeLogin) ...{
            "first_name": _firstNameController.text.trim(),
            "last_name": _lastNameController.text.trim(),
          },
          if (!widget.isFirstTimeLogin) "token": _tokenController.text.trim(),
        },
        options: Options(
          headers: {
            if (widget.isFirstTimeLogin)
              "Authorization": "Bearer ${widget.token}",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        await storage.write(key: 'token', value: response.data['token']);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Password reset successful! Please log in."),
          backgroundColor: Colors.green,
        ));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
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
              if (widget.isFirstTimeLogin)
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: "First Name"),
                  validator: (value) {
                    if (value!.trim().isEmpty) return "Enter first name";
                    return null;
                  },
                ),
              if (widget.isFirstTimeLogin)
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: "Last Name"),
                  validator: (value) {
                    if (value!.trim().isEmpty) return "Enter last name";
                    return null;
                  },
                ),
              if (!widget.isFirstTimeLogin)
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(labelText: "Reset Token"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.trim().isEmpty) return "Enter reset token";
                    return null;
                  },
                ),
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
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
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

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// import 'login_screen.dart';

// const String baseUrl = "https://pdf-manager-eygj.onrender.com";

// class ResetPasswordScreen extends StatefulWidget {
//   final String token;
//   final String phoneNumber;
//   final bool isFirstTimeLogin; // ✅ Track if it's a first-time login reset

//   const ResetPasswordScreen({
//     super.key,
//     required this.token,
//     required this.phoneNumber,
//     required this.isFirstTimeLogin, // ✅ Add isFirstTimeLogin flag
//   });

//   @override
//   _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
// }

// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final Dio dio = Dio();
//   final _formKey = GlobalKey<FormState>();
//   final storage = FlutterSecureStorage();

//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController =
//       TextEditingController();
//   final TextEditingController _tokenController =
//       TextEditingController(); // ✅ Only needed for forgot password

//   bool isLoading = false;
//   String? errorMessage;

//   Future<void> resetPassword() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       Response response = await dio.post(
//         '$baseUrl/reset_password',
//         data: {
//           "phone_number": widget.phoneNumber,
//           "new_password": _newPasswordController.text.trim(),
//           if (!widget.isFirstTimeLogin)
//             "token": _tokenController.text
//                 .trim(), // ✅ Include token only if not first-time login
//         },
//         options: Options(
//           headers: {
//             if (widget.isFirstTimeLogin)
//               "Authorization":
//                   "Bearer ${widget.token}", // ✅ Use JWT for first-time login reset
//             "Content-Type": "application/json",
//           },
//         ),
//       );

//       if (response.statusCode == 200) {
//         // 🔹 Store new token after reset
//         await storage.write(key: 'token', value: response.data['token']);

//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content: Text("✅ Password reset successful! Please log in."),
//           backgroundColor: Colors.green,
//         ));

//         // ✅ Navigate back to login screen after success
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginScreen()),
//         );
//       } else {
//         setState(() {
//           errorMessage = response.data['error'] ?? "❌ Password reset failed.";
//         });
//       }
//     } on DioException catch (e) {
//       setState(() {
//         errorMessage = e.response?.data['error'] ?? "❌ Password reset failed.";
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Reset Password")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Enter a new password for your account.",
//                 style: TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 20),

//               // ✅ Show token field only if not first-time login
//               if (!widget.isFirstTimeLogin)
//                 TextFormField(
//                   controller: _tokenController,
//                   decoration: const InputDecoration(labelText: "Reset Token"),
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     if (value!.trim().isEmpty) return "Enter reset token";
//                     return null;
//                   },
//                 ),

//               TextFormField(
//                 controller: _newPasswordController,
//                 decoration: const InputDecoration(labelText: "New Password"),
//                 obscureText: true,
//                 validator: (value) {
//                   if (value!.trim().isEmpty) return "Enter a password";
//                   if (value.trim().length < 6) return "Min 6 characters";
//                   return null;
//                 },
//               ),
//               TextFormField(
//                 controller: _confirmPasswordController,
//                 decoration:
//                     const InputDecoration(labelText: "Confirm Password"),
//                 obscureText: true,
//                 validator: (value) {
//                   if (value!.trim().isEmpty) return "Confirm your password";
//                   if (value.trim() != _newPasswordController.text.trim()) {
//                     return "Passwords do not match";
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               if (errorMessage != null)
//                 Text(errorMessage!, style: const TextStyle(color: Colors.red)),
//               const SizedBox(height: 10),
//               isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : Center(
//                       child: ElevatedButton(
//                         onPressed: resetPassword,
//                         child: const Text("Reset Password"),
//                       ),
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
