import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

const String baseUrl =
    "https://pdf-manager-eygj.onrender.com"; // Backend API URL

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  _AgentScreenState createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> pdfs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPdfs();
  }

  /// Fetch PDFs assigned to the logged-in agent
  Future<void> fetchPdfs() async {
    String? token = await storage.read(key: "token");
    if (token == null) {
      _showMessage("ERROR: No JWT token found. Please log in again.");
      return;
    }

    try {
      print("DEBUG: Fetching assigned PDFs...");
      Response response = await dio.get(
        '$baseUrl/get_pdfs',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print("DEBUG: Response Status: ${response.statusCode}");
      print("DEBUG: Response Data: ${response.data}");

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          pdfs = response.data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
        print("DEBUG: PDFs fetched successfully -> $pdfs");
      } else {
        print("ERROR: Unexpected response format -> ${response.data}");
        _showMessage("ERROR: Failed to fetch PDFs.");
      }
    } on DioException catch (e) {
      print("DEBUG: Fetch failed - Status: ${e.response?.statusCode}");
      print("DEBUG: Error Response: ${e.response?.data}");
      _showMessage(
          "Failed to fetch PDFs: ${e.response?.data?['error'] ?? 'Unknown error'}");
    } catch (e) {
      print("DEBUG: Unexpected error while fetching PDFs: $e");
      _showMessage("Failed to fetch PDFs. Unexpected error.");
    }
  }

  /// Open PDF in a viewer
  void openPdf(String pdfUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pdfUrl: pdfUrl),
      ),
    );
  }

  /// Download PDF to local storage
  Future<void> downloadPdf(String filename) async {
    String? token = await storage.read(key: "token");
    if (token == null) {
      _showMessage("ERROR: No JWT token found. Please log in again.");
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      String savePath = '${dir.path}/$filename';

      // 🔹 Encode filename to prevent errors with special characters
      String encodedFilename = Uri.encodeComponent(filename);
      String downloadUrl = '$baseUrl/serve_pdf/$encodedFilename';

      print("DEBUG: Downloading PDF from: $downloadUrl");

      await dio.download(
        downloadUrl,
        savePath,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      _showMessage("Download successful: Saved to $savePath");
      print("DEBUG: Downloaded PDF -> $savePath");
    } on DioException catch (e) {
      print("ERROR: Download failed - Status: ${e.response?.statusCode}");
      print("ERROR: Response Data -> ${e.response?.data}");
      _showMessage(
          "Download failed: ${e.response?.data?['error'] ?? 'Unknown error'}");
    } catch (e) {
      print("ERROR: Unexpected error while downloading PDF -> $e");
      _showMessage("Download failed: Unexpected error.");
    }
  }

  /// Show a Snackbar message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Dashboard"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pdfs.isEmpty
              ? const Center(
                  child: Text(
                    "No PDFs assigned.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListView.builder(
                    itemCount: pdfs.length,
                    itemBuilder: (context, index) {
                      final pdf = pdfs[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            pdf['filename'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 🔹 View PDF Button
                              IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Colors.blueAccent),
                                onPressed: () => openPdf(
                                    "$baseUrl/serve_pdf/${Uri.encodeComponent(pdf['filename'])}"),
                              ),

                              // 🔹 Download PDF Button
                              IconButton(
                                icon: const Icon(Icons.download,
                                    color: Colors.green),
                                onPressed: () => downloadPdf(pdf['filename']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// **PDF Viewer Screen**
class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerScreen({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View PDF"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
