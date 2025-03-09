import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class UserPaymentsScreen extends StatefulWidget {
  final int userId;
  const UserPaymentsScreen({super.key, required this.userId});

  @override
  _UserPaymentsScreenState createState() => _UserPaymentsScreenState();
}

class _UserPaymentsScreenState extends State<UserPaymentsScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();
  bool _isLoading = true;
  List<Map<String, dynamic>> payments = [];

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  /// **Fetch Payments for User**
  Future<void> fetchPayments() async {
    String? token = await storage.read(key: "token");
    if (token == null) {
      _showMessage("❌ ERROR: No authentication token found.");
      return;
    }

    try {
      Response response = await dio.get(
        '$baseUrl/get_payments/${widget.userId}',
        options: Options(headers: {
          'Authorization': 'Bearer $token', // ✅ Send token for authentication
        }),
      );

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          payments = response.data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        _showMessage("❌ Failed to load payments.");
      }
    } on DioException catch (e) {
      _showMessage(
          "❌ Error fetching payments: ${e.response?.data?['error'] ?? 'Unknown error'}");
    } catch (e) {
      _showMessage("❌ Something went wrong. Please try again.");
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
      appBar: AppBar(title: const Text("User Payments")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
              ? const Center(child: Text("No payments found for this user."))
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          "Amount: GH₵${payment['amount']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${payment['date']}"),
                            Text(
                              "Commission Period: ${payment['commission_period']}", // ✅ Now showing commission period
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
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
