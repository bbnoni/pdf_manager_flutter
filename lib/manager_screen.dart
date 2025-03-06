import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com"; // API Base URL

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  _ManagerScreenState createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();
  bool _isUploading = false;
  String? selectedAgentId;
  List<Map<String, String>> agents = [];

  @override
  void initState() {
    super.initState();
    fetchAgents();
  }

  /// Fetches agents from the backend and updates the dropdown
  Future<void> fetchAgents() async {
    String? token = await storage.read(key: "token");

    if (token == null || token.isEmpty) {
      _showMessage("ERROR: No JWT token found. Please log in again.");
      return;
    }

    try {
      Response response = await dio.get(
        '$baseUrl/get_agents',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is List) {
        List<Map<String, String>> fetchedAgents = (response.data as List)
            .map((agent) => {
                  "id": agent["id"].toString(),
                  "name": agent["username"].toString()
                })
            .toList();

        setState(() {
          agents = fetchedAgents;
        });
      } else {
        _showMessage("ERROR: Unexpected response format.");
      }
    } catch (e) {
      _showMessage("Failed to fetch agents.");
    }
  }

  /// Handles file upload to backend
  void uploadFile(BuildContext context) async {
    String? token = await storage.read(key: "token");
    if (token == null) {
      _showMessage("ERROR: No JWT token found. Please log in again.");
      return;
    }

    if (selectedAgentId == null) {
      _showMessage("ERROR: Please select an agent to assign the PDF.");
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);

      String filePath = result.files.single.path!;
      String fileName = result.files.single.name;

      try {
        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: fileName),
          'assigned_to': selectedAgentId!.toString(),
        });

        Response response = await dio.post(
          '$baseUrl/upload_pdf',
          data: formData,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (response.statusCode == 200) {
          _showMessage("Upload successful!");
        } else {
          _showMessage("Upload failed.");
        }
      } catch (e) {
        _showMessage("Upload failed: Unexpected error.");
      } finally {
        setState(() => _isUploading = false);
      }
    } else {
      _showMessage("ERROR: No file selected.");
    }
  }

  /// Shows a Snackbar message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Assign PDF to an Agent",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    agents.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: "Select an Agent",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            value: selectedAgentId,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedAgentId = newValue;
                              });
                            },
                            items: agents.map((agent) {
                              return DropdownMenuItem(
                                  value: agent['id'],
                                  child: Text(agent['name']!));
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isUploading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => uploadFile(context),
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload PDF"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
