import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'view_users_screen.dart'; // 🔹 Import View Users Screen

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

  /// **Select File (But Do Not Upload Yet)**
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
    print("📂 File selected: ${selectedFile.name}");

    setState(() {
      _selectedFile = selectedFile;
      _uploadedFileName = selectedFile.name;
      _recordsUploaded = null;
      _totalRecords = null;
    });
  }

  /// **Upload File (When Submit is Clicked)**
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
      print("🚀 Uploading file: ${_selectedFile!.name}");

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
          double progress = total > 0 ? (sent / total) : 0;
          print("📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%");
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        int recordsUploaded = responseData['records_uploaded'] ?? 0;
        int totalRecords = responseData['total_records'] ?? 0;

        print("✅ Upload completed: ${_selectedFile!.name}");
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

  /// **Shows a Snackbar message**
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          /// **Sidebar for Navigation**
          Container(
            width: 250,
            color: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                const Text(
                  "MM Manager Portal",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 30),
                _buildSidebarItem(Icons.dashboard, "Dashboard"),
                _buildSidebarItem(Icons.bar_chart, "Statistics"),
                _buildSidebarItem(Icons.payment, "View Payments", onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ViewUsersScreen()), // 🔹 Navigate to View Payments
                  );
                }),
                const Spacer(),
                const Text(
                  "© DocMgt Francis 2025",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          /// **Main Content (Centered)**
          Expanded(
            child: Center(
              child: Container(
                width: 600,
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
                    /// **Title & Commission Period Input**
                    const Text(
                      "Upload Commissions",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

                    /// **Select File Button**
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : selectFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Select CSV/XLSX File"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// **Upload Progress**
                    if (_isUploading)
                      Column(
                        children: [
                          const Text("Uploading..."),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: _uploadProgress),
                        ],
                      ),
                    const SizedBox(height: 20),

                    /// **Submit Button**
                    if (_uploadedFileName != null && !_isUploading)
                      ElevatedButton.icon(
                        onPressed: uploadFile,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text("Submit"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// **Show Upload Status**
                    if (_recordsUploaded != null && _totalRecords != null)
                      Text(
                        "✅ $_recordsUploaded/$_totalRecords records uploaded successfully!",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
