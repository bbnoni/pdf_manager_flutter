import 'dart:io' show File;

import 'package:agentportal/audit_log_screen.dart';
import 'package:agentportal/delete_commission_screen.dart';
import 'package:agentportal/dio_client.dart';
import 'package:agentportal/send_notification_screen.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:url_launcher/url_launcher.dart';

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
  final Dio dio = DioClient.dio;
  //final Dio dio = Dio();
  final storage = FlutterSecureStorage();

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    DioClient.init(context); // ✅ Set up global interceptor
  }

  double _uploadProgress = 0.0;
  String? _uploadedFileName;
  int? _recordsUploaded;
  int? _totalRecords;
  PlatformFile? _selectedFile;
  final TextEditingController _commissionPeriodController =
      TextEditingController();

  final bool _isSidebarOpen = false;

  final String _uploadMode = 'append'; // default

  final List<String> commissionPeriods = [
    for (var month in [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ])
      for (var week = 1; week <= 5; week++) "$month: Week $week Payment"
  ];

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

// =====================
// ⬇️ REPLACE THIS BLOCK ⬇️
// =====================
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

    final commissionPeriod = _commissionPeriodController.text.trim();
    if (commissionPeriod.isEmpty) {
      _showMessage("⚠️ Commission period cannot be empty.");
      return;
    }

    try {
      // Show spinner before API call
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Check if commission period exists
      Response checkResponse;
      try {
        checkResponse = await dio.get(
          '$baseUrl/check_commission_period',
          queryParameters: {'commission_period': commissionPeriod},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } finally {
        Navigator.pop(context); // Always close spinner
      }

      bool periodExists = checkResponse.data['exists'] == true;

      String action = "append"; // default action
      if (!periodExists) {
        _showMessage("✅ No existing commission period found. Continuing...");
        await Future.delayed(const Duration(seconds: 3));
      } else {
        final decision = await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Commission Period Exists"),
            content: const Text(
                "A commission with this period already exists. What would you like to do?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'append'),
                child: const Text("Append"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'replace'),
                child: const Text("Replace"),
              ),
            ],
          ),
        );

        if (decision == null || decision == 'cancel') {
          _showMessage("⚠️ Upload cancelled.");
          return;
        }
        action = decision;
      }

      // Prepare file for Supabase
      final supabase = supa.Supabase.instance.client;
      final bucket = supabase.storage.from('commissions');
      final String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';
      String publicUrl = "";

      try {
        if (kIsWeb) {
          await bucket.uploadBinary(
            'original/$uniqueFileName',
            _selectedFile!.bytes!,
          );
        } else {
          final file = File(_selectedFile!.path!);
          final bytes = await file.readAsBytes();
          await bucket.uploadBinary('original/$uniqueFileName', bytes);
        }

        final publicUrl = bucket.getPublicUrl('original/$uniqueFileName');
        debugPrint("✅ Supabase upload successful: $publicUrl");
      } catch (e) {
        debugPrint("❌ Supabase upload failed: $e");
      }

// Upload original file to Supabase
      try {
        if (kIsWeb) {
          await bucket.uploadBinary(
              'original/$uniqueFileName', _selectedFile!.bytes!);
        } else {
          final file = File(_selectedFile!.path!);
          final bytes = await file.readAsBytes();

          await bucket.uploadBinary('original/$uniqueFileName', bytes);
        }
        final publicUrl = bucket.getPublicUrl('original/$uniqueFileName');
        debugPrint("✅ Supabase upload successful: $publicUrl");
      } catch (e) {
        debugPrint("❌ Supabase upload failed: $e");
      }

// Prepare file for API
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
        'commission_period': commissionPeriod,
        'mode': action,
        'original_file_url':
            publicUrl, // ✅ Fix: Pass original file URL to backend
      });

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

// Upload to Render backend
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
        String? failedUrl = responseData['failed_download_url'];

        debugPrint("⚠️ failedUrl: $failedUrl"); // 👈 ADD THIS

        _showMessage(
            "✅ Upload successful! $recordsUploaded/$totalRecords records uploaded.");

        if (failedUrl != null) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("⚠️ Some Records Failed"),
                content: const Text(
                    "Some records were not successfully processed. Would you like to download the failed records for review?"),
                actions: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text("Download"),
                    onPressed: () async {
                      Navigator.of(context).pop();

                      if (kIsWeb) {
                        // Web: Open full URL (Supabase)
                        await launchUrl(
                            Uri.parse(failedUrl.startsWith("http")
                                ? failedUrl
                                : baseUrl + failedUrl),
                            mode: LaunchMode.externalApplication);
                        return;
                      }

                      if (failedUrl.startsWith("http")) {
                        // ✅ Fully qualified Supabase URL
                        await launchUrl(Uri.parse(failedUrl),
                            mode: LaunchMode.externalApplication);
                        return;
                      }

                      // ✅ Local backend download (e.g. /download_failed_commissions)
                      String? token = await storage.read(key: "token");
                      if (token == null) {
                        _showMessage("❌ No token found.");
                        return;
                      }

                      try {
                        final response = await dio.get(
                          baseUrl + failedUrl,
                          options: Options(
                            headers: {'Authorization': 'Bearer $token'},
                            responseType: ResponseType.bytes,
                          ),
                        );

                        final bytes = response.data;
                        final directory = await getTemporaryDirectory();
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        final failedFileName =
                            "failed_commissions_$timestamp.xlsx";
                        final filePath = "${directory.path}/$failedFileName";
                        final file = File(filePath);
                        await file.writeAsBytes(bytes);

                        await OpenFile.open(filePath);
                        _showMessage("✅ File saved and opened.");
                      } catch (e) {
                        _showMessage("❌ Failed to download file.");
                      }
                    },
                  ),
                ],
              );
            },
          );
        }

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
      Navigator.pop(context); // Ensure spinner closes on API failure
      _showMessage(
          "❌ Upload failed: ${e.response?.data?['error'] ?? 'Unknown error'}");
    } catch (e) {
      Navigator.pop(context); // Ensure spinner closes on any error
      _showMessage("❌ Something went wrong. Please try again.");
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

// =====================
// ⬆️ REPLACE THIS BLOCK ⬆️
// =====================

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
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return commissionPeriods.where((String option) {
                              return option.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            _commissionPeriodController.text = selection;
                          },
                          fieldViewBuilder: (context, controller, focusNode,
                              onEditingComplete) {
                            _commissionPeriodController.text = controller.text;
                            controller.addListener(() {
                              _commissionPeriodController.text =
                                  controller.text;
                            });
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: "Enter Commission Period",
                                hintText:
                                    "Start typing e.g. March: Week 3 Payment",
                                prefixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(),
                              ),
                            );
                          },
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
        _buildSidebarItem(Icons.delete, "Delete Commissions", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DeleteCommissionScreen(),
            ),
          );
        }),
        _buildSidebarItem(Icons.history, "Audit Logs", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AuditLogScreen(), // ✅ Here! //
            ),
          );
        }),
        _buildSidebarItem(Icons.message, "Send Notification", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SendNotificationScreen(),
            ),
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
