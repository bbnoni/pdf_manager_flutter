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
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_red_eye,
                              color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommissionDetailsScreen(
                                  commission: commission,
                                ),
                              ),
                            );
                          },
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
      appBar: AppBar(title: const Text("Commission Details")),
      body: SingleChildScrollView(
        // ✅ Prevents bottom overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// **Commission Amount**
              Text(
                "Commission Earned: GH₵${commission['amount']}",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              /// **Date**
              Text(
                "Date: ${commission['date']}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              /// **Commission Period**
              Text(
                "Commission Period: ${commission['commission_period']}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),

              /// **Cash-In Section**
              const Divider(thickness: 1.5),
              const Text(
                "Cash-In Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildRow("Transactions", commission['cashin_total_transactions']),
              buildRow("Valid Transactions",
                  commission['cashin_total_number_valid']),
              buildRow("Value", "GH₵${commission['cashin_total_value']}"),
              buildRow("Valid Value",
                  "GH₵${commission['cashin_total_value_valid']}"),
              buildRow("Tax", "GH₵${commission['cashin_total_tax_on_valid']}"),
              buildRow(
                  "Payout", "GH₵${commission['cashin_payout_commission']}"),

              /// **Cash-Out Section**
              const SizedBox(height: 12),
              const Divider(thickness: 1.5),
              const Text(
                "Cash-Out Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildRow(
                  "Transactions", commission['cashout_total_transactions']),
              buildRow("Valid Transactions",
                  commission['cashout_total_number_valid']),
              buildRow("Value", "GH₵${commission['cashout_total_value']}"),
              buildRow("Valid Value",
                  "GH₵${commission['cashout_total_value_valid']}"),
              buildRow("Tax", "GH₵${commission['cashout_total_tax_on_valid']}"),
              buildRow(
                  "Payout", "GH₵${commission['cashout_payout_commission']}"),

              /// **Total Commissions Due**
              const SizedBox(height: 20),
              const Divider(thickness: 1.5),
              Text(
                "Total Commissions Due: GH₵${commission['total_commissions_due']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Reusable Row for Displaying Key-Value Data**
  Widget buildRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value != null ? value.toString() : "N/A",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
