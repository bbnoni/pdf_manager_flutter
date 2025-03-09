import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class AgentCommissionScreen extends StatefulWidget {
  const AgentCommissionScreen({super.key});

  @override
  _AgentCommissionScreenState createState() => _AgentCommissionScreenState();
}

class _AgentCommissionScreenState extends State<AgentCommissionScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCommissions();
  }

  /// **Fetch Commissions for the Logged-in Agent**
  Future<void> fetchCommissions() async {
    print("🔹 Fetching commissions...");

    String? token = await storage.read(key: "token");
    if (token == null) {
      _showMessage("ERROR: No JWT token found. Please log in again.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      Response response = await dio.get(
        '$baseUrl/get_commissions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          commissions = response.data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });

        if (commissions.isEmpty) {
          _showMessage("No commissions assigned yet.");
        }
      } else {
        _showMessage("ERROR: Unexpected API response.");
        setState(() => _isLoading = false);
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = "Failed to fetch commissions.";
      if (e.response?.statusCode == 403) {
        errorMessage = "Access Denied: Unauthorized request.";
      } else if (e.response?.statusCode == 500) {
        errorMessage = "Server error. Please try again later.";
      } else if (e.response?.data != null) {
        errorMessage = e.response?.data['error'] ?? errorMessage;
      }
      _showMessage(errorMessage);
    }
  }

  /// **Download Commission Report**
  Future<void> downloadReport(String commissionId) async {
    String? token = await storage.read(key: "token");
    if (token == null) return;

    try {
      Response response = await dio.get(
        '$baseUrl/download_commission/$commissionId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes, // Download as bytes
        ),
      );

      if (response.statusCode == 200) {
        _showMessage("✅ Download started!");
        // Implement file saving logic (Flutter file picker required)
      } else {
        _showMessage("❌ Download failed.");
      }
    } catch (e) {
      _showMessage("❌ Error downloading report.");
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
      appBar: AppBar(title: const Text("My Commissions")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : commissions.isEmpty
              ? const Center(child: Text("No commissions assigned yet."))
              : ListView.builder(
                  itemCount: commissions.length,
                  itemBuilder: (context, index) {
                    final commission = commissions[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          "Commission Earned: GH₵${commission['amount']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date: ${commission['date']}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (commission.containsKey('commission_period'))
                              Text(
                                "Commission Period: ${commission['commission_period']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_red_eye,
                                  color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CommissionDetailsScreen(
                                      commission: commission,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.download, color: Colors.green),
                              onPressed: () =>
                                  downloadReport(commission['id'].toString()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// **🔹 Commission Details Screen**
class CommissionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> commission;
  const CommissionDetailsScreen({super.key, required this.commission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Commission Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Commission Earned: GH₵${commission['amount']}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Date: ${commission['date']}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (commission.containsKey('commission_period'))
              Text(
                "Commission Period: ${commission['commission_period']}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text("Download Report"),
              onPressed: () {
                // Add logic to handle downloading
              },
            ),
          ],
        ),
      ),
    );
  }
}
