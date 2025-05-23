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
  bool whatsappOnly = false; // New flag for WhatsApp-only mode

  List<Map<String, dynamic>> contacts = [];
  List<String> selectedAgents = [];
  List<dynamic> failed =
      []; // Changed to dynamic to handle different failure formats

  List<String> weeks = [];
  String selectedWeek = "";

  @override
  void initState() {
    super.initState();
    fetchAgentContacts();
    fetchWeeks();
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

  Future<void> fetchWeeks() async {
    String? token = await storage.read(key: "token");
    if (token == null || token.isEmpty) return;

    try {
      Response response = await dio.get(
        '$baseUrl/get_commission_periods',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          weeks = List<String>.from(response.data);
        });
      }
    } catch (e) {
      _showMessage("❌ Failed to fetch weeks.");
    }
  }

  Future<void> sendNotification() async {
    String? token = await storage.read(key: "token");
    if (token == null) return;

    if (message.trim().isEmpty) {
      _showMessage("✏️ Please enter a message to send.");
      return;
    }

    List<String> finalRecipients = [];

    if (sendToAll) {
      finalRecipients =
          []; // Send to all, backend interprets empty as "broadcast"
    } else {
      if (selectedWeek.isEmpty) {
        _showMessage("📆 Please select a commission week.");
        return;
      }

      if (selectedAgents.isNotEmpty) {
        finalRecipients = selectedAgents;
      } else {
        // Filter contacts internally, don't show in UI
        finalRecipients = contacts
            .map((c) => c['agent_wallet_number']?.toString())
            .whereType<String>()
            .where((wallet) => wallet.trim().isNotEmpty)
            .toList();

        if (finalRecipients.isEmpty) {
          _showMessage("👤 No matching agents found for the selected week.");
          return;
        }
      }
    }

    setState(() => isLoading = true);

    Map<String, dynamic> payload = {
      "message": message,
      "agent_wallets": finalRecipients,
      "commission_week": selectedWeek.isEmpty ? null : selectedWeek
    };

    // Choose endpoint based on whatsappOnly flag
    final endpoint = whatsappOnly
        ? '$baseUrl/notifications/send_whatsapp_notifications'
        : '$baseUrl/notifications/send_notifications';

    try {
      Response response = await dio.post(
        endpoint,
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Handle different failure formats from different endpoints
          if (response.data['failed'] is List) {
            failed = response.data['failed'];
          } else {
            failed = [];
          }
          isLoading = false;
        });
        _showMessage(whatsappOnly
            ? "✅ WhatsApp notifications sent."
            : "✅ Notifications sent to all channels.");
      } else {
        _showMessage("⚠️ Failed to send notifications.");
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showMessage("🚨 Error sending notifications: ${e.toString()}");
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
    // Filter contacts based on whatsappOnly mode
    final displayContacts = whatsappOnly
        ? contacts
            .where((c) =>
                c['whatsapp_number'] != null &&
                c['whatsapp_number'].toString().trim().isNotEmpty)
            .toList()
        : contacts;

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
                onChanged: (val) {
                  setState(() {
                    message = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Commission week dropdown
              if (weeks.isNotEmpty && !sendToAll)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Select Commission Week",
                    border: OutlineInputBorder(),
                  ),
                  value: selectedWeek.isEmpty ? null : selectedWeek,
                  items: weeks.map((week) {
                    return DropdownMenuItem<String>(
                      value: week,
                      child: Text(week),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedWeek = val ?? ""),
                ),

              if (!sendToAll && selectedWeek.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text(
                    "⚠️ Please select a commission week to enable messaging.",
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              // Send to all switch
              SwitchListTile(
                value: sendToAll,
                title: const Text("Send to All Agents"),
                onChanged: (val) => setState(() => sendToAll = val),
              ),

              // WhatsApp only switch - NEW
              SwitchListTile(
                value: whatsappOnly,
                title: const Text("WhatsApp Only"),
                subtitle: const Text("Send messages only via WhatsApp"),
                secondary: Icon(Icons.message, color: Colors.green),
                onChanged: (val) => setState(() => whatsappOnly = val),
              ),

              const SizedBox(height: 12),

              // Agent selection
              if (!sendToAll)
                MultiSelectDialogField<String>(
                  items: displayContacts.map((c) {
                    String wallet = c['agent_wallet_number'] ?? 'unknown';
                    return MultiSelectItem<String>(
                      wallet,
                      showPreview ? "$wallet ${getChannelSymbol(c)}" : wallet,
                    );
                  }).toList(),
                  initialValue: selectedAgents,
                  listType: MultiSelectListType.CHIP,
                  searchable: true,
                  title: Text(whatsappOnly
                      ? "Select WhatsApp Agents"
                      : "Select Specific Agents"),
                  buttonText: Text(whatsappOnly
                      ? "Select WhatsApp Agents"
                      : "Select Specific Agents"),
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

              // Show channel preview switch
              SwitchListTile(
                value: showPreview,
                title: const Text("Show Channel Preview"),
                onChanged: (val) => setState(() => showPreview = val),
              ),
              const SizedBox(height: 20),

              // Send button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text(whatsappOnly
                      ? "Send WhatsApp Notification"
                      : "Send Notification"),
                  onPressed: sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whatsappOnly ? Colors.green : null,
                    foregroundColor: whatsappOnly ? Colors.white : null,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Failed deliveries
              if (failed.isNotEmpty) ...[
                const Text("Failed to Deliver to:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...failed.map((failure) {
                  if (failure is Map) {
                    return Text(
                        "• ${failure['name'] ?? 'Unknown'}: ${failure['reason'] ?? 'Unknown error'}");
                  } else {
                    return Text("• $failure");
                  }
                }),
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
