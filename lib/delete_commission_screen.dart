import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class DeleteCommissionScreen extends StatefulWidget {
  const DeleteCommissionScreen({super.key});

  @override
  _DeleteCommissionScreenState createState() => _DeleteCommissionScreenState();
}

class _DeleteCommissionScreenState extends State<DeleteCommissionScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();
  final _periodController = TextEditingController();

  bool isLoading = false;
  bool deleteGlobally = true;
  String? selectedAgent;
  List<Map<String, dynamic>> agents = [];
  List<Map<String, dynamic>> commissions = [];
  List<String> commissionPeriods = [];

  @override
  void initState() {
    super.initState();
    fetchAgents();
    fetchCommissionPeriods();
  }

  Future<void> fetchAgents() async {
    String? token = await storage.read(key: "token");
    if (token == null) return;

    try {
      final response = await dio.get(
        '$baseUrl/get_agents',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          agents = response.data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  Future<void> fetchCommissionPeriods() async {
    String? token = await storage.read(key: "token");
    if (token == null) return;

    try {
      final response = await dio.get(
        '$baseUrl/get_commission_periods',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          commissionPeriods = response.data.cast<String>();
        });
      }
    } catch (_) {}
  }

  Future<void> fetchMatchingCommissions() async {
    if (_periodController.text.trim().isEmpty) {
      _showMessage("Please enter the commission period.");
      return;
    }

    String? token = await storage.read(key: "token");
    setState(() {
      commissions.clear();
      isLoading = true;
    });

    try {
      final queryParams = {
        "commission_period": _periodController.text.trim(),
        if (!deleteGlobally && selectedAgent != null) "user_id": selectedAgent,
      };

      final response = await dio.get(
        '$baseUrl/fetch_commissions',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          commissions = response.data.cast<Map<String, dynamic>>();
        });
      } else {
        _showMessage("No matching commissions found.");
      }
    } catch (_) {
      _showMessage("Error loading commissions.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteCommissions() async {
    if (_periodController.text.trim().isEmpty) {
      _showMessage("Please enter the commission period.");
      return;
    }

    bool confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => isLoading = true);
    String? token = await storage.read(key: "token");

    try {
      final data = {
        "commission_period": _periodController.text.trim(),
        "user_id": deleteGlobally ? null : selectedAgent,
      };

      final response = await dio.delete(
        '$baseUrl/delete_commissions',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        _showMessage("✅ Commissions deleted successfully!");
        setState(() {
          _periodController.clear();
          commissions.clear();
          selectedAgent = null;
          deleteGlobally = true;
        });
      } else {
        _showMessage("❌ Delete failed.");
      }
    } on DioException catch (e) {
      _showMessage("❌ Error: ${e.response?.data?['error'] ?? 'Unknown error'}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: const Text(
                "Are you sure you want to delete the commissions? This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes, Delete"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delete Commissions")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return commissionPeriods.where((period) => period
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _periodController.text = selection;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                controller.text = _periodController.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: const InputDecoration(
                      labelText: "Commission Period (e.g., Feb Week 1)"),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: deleteGlobally,
                  onChanged: (value) {
                    setState(() {
                      deleteGlobally = value!;
                      if (deleteGlobally) selectedAgent = null;
                    });
                  },
                ),
                const Text("Delete for all agents")
              ],
            ),
            if (!deleteGlobally)
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Select Agent"),
                value: selectedAgent,
                items: agents
                    .map((agent) => DropdownMenuItem(
                          value: agent['id'].toString(),
                          child: Text(
                              "${agent['first_name']} ${agent['last_name']} (${agent['phone_number']})"),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAgent = value;
                  });
                },
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchMatchingCommissions,
              child: const Text("🔍 Preview Matching Commissions"),
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            if (commissions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: commissions.length,
                  itemBuilder: (context, index) {
                    final c = commissions[index];
                    return ListTile(
                      leading: const Icon(Icons.monetization_on),
                      title: Text("GHS ${c['amount']}"),
                      subtitle: Text(
                          "User: ${c['user'] ?? 'N/A'} • Date: ${c['date'] ?? ''}"),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: deleteCommissions,
              icon: const Icon(Icons.delete_forever),
              label: const Text("Delete Commissions"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
