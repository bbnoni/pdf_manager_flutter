import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final TextEditingController _commissionPeriodController =
      TextEditingController(); // 🔹 Manual Commission Period Entry

  /// **Select and Upload File**
  Future<void> selectAndUploadFile() async {
    if (_commissionPeriodController.text.trim().isEmpty) {
      _showMessage("⚠️ Please enter the commission period before uploading.");
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
      _uploadedFileName = null;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    await _uploadCommissionFile(selectedFile);
  }

  /// **Uploads File with Progress**
  Future<void> _uploadCommissionFile(PlatformFile file) async {
    String? token = await storage.read(key: "token");

    if (token == null || token.isEmpty) {
      _showMessage("❌ ERROR: No JWT token found. Please log in again.");
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
      return;
    }

    try {
      print("🚀 Uploading file: ${file.name}");

      MultipartFile multipartFile;
      if (kIsWeb) {
        multipartFile =
            MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else {
        multipartFile =
            await MultipartFile.fromFile(file.path!, filename: file.name);
      }

      FormData formData = FormData.fromMap({
        'file': multipartFile,
        'commission_period':
            _commissionPeriodController.text.trim(), // 🔹 Manual Period
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
        print("✅ Upload completed: ${file.name}");
        setState(() {
          _uploadedFileName = file.name;
          _showMessage("✅ Upload completed: ${file.name}");
        });
      } else {
        print("❌ Upload failed: ${response.statusMessage}");
        _showMessage("❌ Upload failed.");
      }
    } on DioException catch (e) {
      print("❌ Upload error: ${e.response?.data}");
      _showMessage(
          "❌ Upload failed: ${e.response?.data?['error'] ?? 'Unknown error'}");
    } catch (e) {
      print("❌ Unexpected error: $e");
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

              ElevatedButton.icon(
                onPressed: _isUploading ? null : selectAndUploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Select & Upload CSV/XLSX"),
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

              const SizedBox(height: 20),

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
            ],
          ),
        ),
      ),
    );
  }
}
