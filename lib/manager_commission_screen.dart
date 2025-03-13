import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'create_manager_screen.dart'; // Import the CreateManagerScreen class
import 'login_screen.dart';
import 'view_users_screen.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class ManagerCommissionScreen extends StatefulWidget {
  const ManagerCommissionScreen({super.key});

  @override
  _ManagerCommissionScreenState createState() =>
      _ManagerCommissionScreenState();
}

class _ManagerCommissionScreenState extends State<ManagerCommissionScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadedFileName;
  int? _recordsUploaded;
  int? _totalRecords;
  PlatformFile? _selectedFile;
  final TextEditingController _commissionPeriodController =
      TextEditingController();

  bool _isSidebarOpen = false;

  Future<void> _logout() async {
    await storage.deleteAll();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> selectFile() async {
    if (_commissionPeriodController.text.trim().isEmpty) {
      _showMessage(
          "⚠️ Please enter the commission period before selecting a file.");
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: kIsWeb,
    );

    if (result == null) {
      _showMessage("❌ No file selected.");
      return;
    }

    PlatformFile selectedFile = result.files.single;
    setState(() {
      _selectedFile = selectedFile;
      _uploadedFileName = selectedFile.name;
      _recordsUploaded = null;
      _totalRecords = null;
    });
  }

  Future<void> uploadFile() async {
    if (_selectedFile == null) {
      _showMessage("⚠️ Please select a file before submitting.");
      return;
    }

    String? token = await storage.read(key: "token");
    if (token == null || token.isEmpty) {
      _showMessage("❌ ERROR: No JWT token found. Please log in again.");
      return;
    }

    try {
      MultipartFile multipartFile;
      if (kIsWeb) {
        multipartFile = MultipartFile.fromBytes(_selectedFile!.bytes!,
            filename: _selectedFile!.name);
      } else {
        multipartFile = await MultipartFile.fromFile(_selectedFile!.path!,
            filename: _selectedFile!.name);
      }

      FormData formData = FormData.fromMap({
        'file': multipartFile,
        'commission_period': _commissionPeriodController.text.trim(),
      });

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      Response response = await dio.post(
        '$baseUrl/upload_commissions',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        }),
        onSendProgress: (int sent, int total) {
          setState(() {
            _uploadProgress = total > 0 ? (sent / total) : 0;
          });
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        int recordsUploaded = responseData['records_uploaded'] ?? 0;
        int totalRecords = responseData['total_records'] ?? 0;

        _showMessage(
            "✅ Upload successful! $recordsUploaded/$totalRecords records uploaded.");

        setState(() {
          _uploadedFileName = null;
          _selectedFile = null;
          _recordsUploaded = recordsUploaded;
          _totalRecords = totalRecords;
          _commissionPeriodController.clear();
        });
      } else {
        _showMessage("❌ Upload failed.");
      }
    } on DioException catch (e) {
      _showMessage(
          "❌ Upload failed: ${e.response?.data?['error'] ?? 'Unknown error'}");
    } catch (e) {
      _showMessage("❌ Something went wrong. Please try again.");
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: isMobile
              ? AppBar(
                  title: const Text("MM Manager Portal"),
                  backgroundColor: Colors.blueAccent,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                )
              : null,
          drawer: isMobile ? _buildDrawer() : null,
          body: Row(
            children: [
              if (!isMobile) _buildSidebar(),
              Expanded(
                child: Center(
                  child: Container(
                    width: constraints.maxWidth > 1000
                        ? 800
                        : constraints.maxWidth * 0.9,
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
                          "Upload Commissions",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _commissionPeriodController,
                          decoration: InputDecoration(
                            labelText: "Enter Commission Period",
                            hintText: "e.g., January Week 3",
                            border: OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : selectFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text("Select CSV/XLSX File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (_isUploading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child:
                                LinearProgressIndicator(value: _uploadProgress),
                          ),
                        if (_selectedFile != null)
                          Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                    "📂 Selected File: $_uploadedFileName"),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : uploadFile,
                                icon: _isUploading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Icon(Icons.cloud_upload),
                                label: Text(
                                    _isUploading ? "Uploading..." : "Submit"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.blueAccent,
      child: _buildDrawerContent(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.blueAccent,
        child: _buildDrawerContent(),
      ),
    );
  }

  Widget _buildDrawerContent() {
    return Column(
      children: [
        const DrawerHeader(
          child: Text("MM Manager Portal",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        _buildSidebarItem(Icons.dashboard, "Dashboard"),
        _buildSidebarItem(Icons.payment, "View Payments", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewUsersScreen()),
          );
        }),
        _buildSidebarItem(Icons.person_add, "Create New Manager", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const CreateManagerScreen()), // ✅ FIXED: Added correct navigation
          );
        }),
        _buildSidebarItem(Icons.logout, "Logout", onTap: _logout),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
