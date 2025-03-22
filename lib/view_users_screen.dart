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

  bool _deleteMode = false;
  Set<int> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

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
          'Authorization': 'Bearer $token',
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

  void _toggleDeleteMode() {
    setState(() {
      _deleteMode = !_deleteMode;
      _selectedUserIds.clear();
    });
  }

  void _toggleSelection(int userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _deleteSelectedUsers() async {
    if (_selectedUserIds.isEmpty) {
      _showMessage("⚠️ No users selected.");
      return;
    }

    bool confirm = await _showConfirmDialog();
    if (!confirm) return;

    String? token = await storage.read(key: "token");
    if (token == null) return;

    try {
      Response response = await dio.post(
        '$baseUrl/delete_agents',
        data: {'ids': _selectedUserIds.toList()},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          users.removeWhere((user) => _selectedUserIds.contains(user['id']));
          _selectedUserIds.clear();
          _deleteMode = false;
        });
        _showMessage("✅ Users deleted successfully.");
      } else {
        _showMessage("❌ Failed to delete users.");
      }
    } on DioException catch (e) {
      _showMessage(
          "❌ ERROR: ${e.response?.data?['error'] ?? 'Deletion failed'}");
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content:
                const Text("Are you sure you want to delete selected users?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text("Delete"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Users & Commissions"),
        actions: [
          IconButton(
            icon: Icon(_deleteMode ? Icons.cancel : Icons.delete),
            onPressed: _toggleDeleteMode,
          ),
          if (_deleteMode && _selectedUserIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _deleteSelectedUsers,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text("No users found."))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = user['id'];

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        onTap: _deleteMode
                            ? () => _toggleSelection(userId)
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserPaymentsScreen(userId: userId),
                                  ),
                                );
                              },
                        leading: _deleteMode
                            ? Checkbox(
                                value: _selectedUserIds.contains(userId),
                                onChanged: (_) => _toggleSelection(userId),
                              )
                            : const Icon(Icons.person),
                        title: Text(
                          "User: ${user['username']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Phone: ${user['phone_number']}"),
                      ),
                    );
                  },
                ),
    );
  }
}
