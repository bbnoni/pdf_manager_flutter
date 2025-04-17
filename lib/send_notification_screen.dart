import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();

  String message = "";
  bool sendToAll = false;
  bool showPreview = true;
  bool isLoading = false;

  List<Map<String, dynamic>> contacts = [];
  List<String> selectedAgents = [];
  List<String> failed = [];

  @override
  void initState() {
    super.initState();
    fetchAgentContacts();
  }

  Future<void> fetchAgentContacts() async {
    String? token = await storage.read(key: "token");
    if (token == null || token.isEmpty) return;

    try {
      Response response = await dio.get(
        '$baseUrl/get_agent_contacts',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          contacts = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      _showMessage("❌ Failed to fetch agent contacts.");
    }
  }

  Future<void> sendNotification() async {
    String? token = await storage.read(key: "token");
    if (token == null) return;

    if (message.isEmpty) {
      _showMessage("Please enter a message.");
      return;
    }

    setState(() => isLoading = true);

    Map<String, dynamic> payload = {
      "message": message,
      "agent_wallets": sendToAll ? [] : selectedAgents
    };

    try {
      Response response = await dio.post(
        '$baseUrl/notifications/send_notifications',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          failed = List<String>.from(response.data['failed'] ?? []);
          isLoading = false;
        });
        _showMessage("✅ Notifications sent.");
      } else {
        _showMessage("⚠️ Failed to send notifications.");
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showMessage("🚨 Error sending notifications.");
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String normalize(String number) {
    if (number.startsWith("0") && number.length == 10) {
      return "233${number.substring(1)}";
    } else if (number.length == 9) {
      return "233$number";
    } else if (number.startsWith("233")) {
      return number;
    } else {
      return number;
    }
  }

  // ✅ Updated to reflect all available channels
  String getChannelSymbol(Map<String, dynamic> contact) {
    final email = contact['email']?.toString().trim();
    final phone = contact['phone_number']?.toString().trim();
    final whatsapp = contact['whatsapp_number']?.toString().trim();

    List<String> symbols = [];

    if (email != null && email.isNotEmpty) symbols.add("📧");
    if (phone != null && phone.isNotEmpty) symbols.add("📱");
    if (whatsapp != null && whatsapp.isNotEmpty) symbols.add("💬");

    return symbols.isEmpty ? "❌" : symbols.join(" ");
  }

  Map<String, dynamic> findContact(String wallet) {
    return contacts.firstWhere(
      (c) {
        final storedWallet = c['agent_wallet_number']?.toString() ?? '';
        return storedWallet == wallet || normalize(storedWallet) == wallet;
      },
      orElse: () => {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text("Send Notifications")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Message",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => message = val,
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                value: sendToAll,
                title: const Text("Send to All Agents"),
                onChanged: (val) => setState(() => sendToAll = val),
              ),
              const SizedBox(height: 12),
              if (!sendToAll)
                MultiSelectDialogField<String>(
                  items: contacts.map((c) {
                    String wallet = c['agent_wallet_number'] ?? 'unknown';
                    return MultiSelectItem<String>(
                      wallet,
                      showPreview ? "$wallet ${getChannelSymbol(c)}" : wallet,
                    );
                  }).toList(),
                  initialValue: selectedAgents,
                  listType: MultiSelectListType.CHIP,
                  searchable: true,
                  title: const Text("Select Specific Agents"),
                  buttonText: const Text("Select Specific Agents"),
                  chipDisplay: MultiSelectChipDisplay(
                    chipColor: Colors.grey[200],
                    textStyle: const TextStyle(color: Colors.black),
                    icon: const Icon(Icons.close),
                    items: selectedAgents.map((wallet) {
                      final contact = findContact(wallet);
                      return MultiSelectItem<String>(
                        wallet,
                        showPreview
                            ? "$wallet ${getChannelSymbol(contact)}"
                            : wallet,
                      );
                    }).toList(),
                  ),
                  onConfirm: (values) =>
                      setState(() => selectedAgents = values),
                ),
              const SizedBox(height: 20),
              SwitchListTile(
                value: showPreview,
                title: const Text("Show Channel Preview"),
                onChanged: (val) => setState(() => showPreview = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text("Send Notification"),
                  onPressed: sendNotification,
                ),
              ),
              const SizedBox(height: 20),
              if (failed.isNotEmpty) ...[
                const Text("Failed to Deliver to:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...failed.map((id) => Text("• $id")),
              ]
            ]),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
      ],
    );
  }
}
