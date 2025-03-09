import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'user_payments_screen.dart'; // ✅ Import UserPaymentsScreen

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class ViewUsersScreen extends StatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  _ViewUsersScreenState createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends State<ViewUsersScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();
  bool _isLoading = true;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  /// **Fetch Users & Agents**
  Future<void> fetchUsers() async {
    String? token = await storage.read(key: "token");
    if (token == null) {
      _showMessage("❌ ERROR: No authentication token found.");
      return;
    }

    try {
      Response response = await dio.get(
        '$baseUrl/get_agents',
        options: Options(headers: {
          'Authorization': 'Bearer $token', // ✅ Send token for authentication
        }),
      );

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          users = response.data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        _showMessage("❌ Failed to load users.");
      }
    } on DioException catch (e) {
      _showMessage(
          "❌ Error fetching users: ${e.response?.data?['error'] ?? 'Unknown error'}");
    } catch (e) {
      _showMessage("❌ Something went wrong. Please try again.");
    }
  }

  /// **Shows a Snackbar message**
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("View Users & Payments")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text("No users found."))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          "User: ${user['username']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Phone: ${user['phone_number']}"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UserPaymentsScreen(userId: user['id']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
