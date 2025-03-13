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
  String _activePage = "My Commissions"; // Track active sidebar item

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
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          /// **Sidebar Navigation**
          Container(
            width: 250,
            color: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MM Agent Portal",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 30),
                _buildSidebarItem(Icons.dashboard, "Dashboard"),
                _buildSidebarItem(Icons.money, "My Commissions",
                    isActive: true),
                const Spacer(),
                const Text(
                  "© DocMgt Francis 2025",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          /// **Main Content (Commission List)**
          Expanded(
            child: Center(
              child: Container(
                width: 800,
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : commissions.isEmpty
                        ? const Center(
                            child: Text("No commissions assigned yet."))
                        : ListView.builder(
                            itemCount: commissions.length,
                            itemBuilder: (context, index) {
                              final commission = commissions[index];
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  title: Text(
                                    "GH₵${commission['amount']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  subtitle: Text(
                                    "Date: ${commission['date']}  •  Period: ${commission['commission_period']}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_red_eye,
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
                                ),
                              );
                            },
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Sidebar Item Builder**
  Widget _buildSidebarItem(IconData icon, String title,
      {bool isActive = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      tileColor: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => setState(() => _activePage = title),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// **Commission Earned**
            Text(
              "Commission Earned: GH₵${commission['amount']}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

            /// **Transaction Sections**
            _buildTransactionSection("Cash-In Transactions", [
              _buildRow(
                  "Transactions", commission['cashin_total_transactions']),
              _buildRow("Valid Transactions",
                  commission['cashin_total_number_valid']),
              _buildRow("Value", "GH₵${commission['cashin_total_value']}"),
              _buildRow("Valid Value",
                  "GH₵${commission['cashin_total_value_valid']}"),
              _buildRow("Tax", "GH₵${commission['cashin_total_tax_on_valid']}"),
              _buildRow(
                  "Payout", "GH₵${commission['cashin_payout_commission']}"),
            ]),

            _buildTransactionSection("Cash-Out Transactions", [
              _buildRow(
                  "Transactions", commission['cashout_total_transactions']),
              _buildRow("Valid Transactions",
                  commission['cashout_total_number_valid']),
              _buildRow("Value", "GH₵${commission['cashout_total_value']}"),
              _buildRow("Valid Value",
                  "GH₵${commission['cashout_total_value_valid']}"),
              _buildRow(
                  "Tax", "GH₵${commission['cashout_total_tax_on_valid']}"),
              _buildRow(
                  "Payout", "GH₵${commission['cashout_payout_commission']}"),
            ]),

            /// **Total Commissions Due**
            const SizedBox(height: 20),
            const Divider(thickness: 1.5),
            _buildRow(
              "Total Commissions Due",
              "GH₵${commission['total_commissions_due']}",
              isBold: true,
              color: Colors.green,
              fontSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const Divider(thickness: 1.5), Text(title), ...rows],
    );
  }

  Widget _buildRow(String label, dynamic value,
      {bool isBold = false, Color? color, double fontSize = 14}) {
    return Text(
      "$label: ${value ?? "N/A"}",
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color,
        fontSize: fontSize,
      ),
    );
  }
}
