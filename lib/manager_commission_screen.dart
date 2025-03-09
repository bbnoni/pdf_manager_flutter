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
  PlatformFile? _selectedFile; // Store the selected file
  final TextEditingController _commissionPeriodController =
      TextEditingController(); // 🔹 Manual Commission Period Entry

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
      withData: kIsWeb, // Needed for web (preloads bytes)
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
        print("✅ Upload completed: ${_selectedFile!.name}");
        _showMessage("✅ Upload completed: ${_selectedFile!.name}");

        // 🔹 Clear Fields After Successful Upload
        setState(() {
          _uploadedFileName = null;
          _selectedFile = null;
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
      appBar: AppBar(title: const Text("Upload Commissions")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// **Commission Period Input**
              TextField(
                controller: _commissionPeriodController,
                decoration: InputDecoration(
                  labelText: "Enter Commission Period",
                  hintText: "e.g., January Week 3",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              /// **Select File Button**
              ElevatedButton.icon(
                onPressed: _isUploading ? null : selectFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Select CSV/XLSX File"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 10),

              /// **Show Selected File Name**
              if (_uploadedFileName != null)
                Text(
                  "📂 Selected File: $_uploadedFileName",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),

              const SizedBox(height: 20),

              /// **Upload Progress Bar**
              if (_isUploading)
                Column(
                  children: [
                    const Text("Uploading...",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),

              const SizedBox(height: 30),

              /// **View Users & Payments Button**
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ViewUsersScreen()), // 🔹 Navigate to View Users Screen
                  );
                },
                icon: const Icon(Icons.people),
                label: const Text("View Users & Payments"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
