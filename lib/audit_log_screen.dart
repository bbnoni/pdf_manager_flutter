import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchAuditLogs();
  }

  Future<void> fetchAuditLogs() async {
    String? token = await storage.read(key: "token");
    if (token == null) return;

    try {
      final response = await dio.get(
        'https://pdf-manager-eygj.onrender.com/audit_logs',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(() {
        _logs = response.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to fetch logs")));
    }
  }

  Future<void> _downloadAndOpenFile(String url, String filename) async {
    if (url.startsWith("http")) {
      // ✅ Supabase or external link – open directly
      try {
        await OpenFile.open(url); // or use launchUrl if preferred
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to open the URL")),
        );
      }
      return;
    }

    // ✅ Local backend file – download using token
    String? token = await storage.read(key: "token");
    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No token found")));
      return;
    }

    final fullUrl = 'https://pdf-manager-eygj.onrender.com$url';

    try {
      final response = await dio.get(
        fullUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      final bytes = response.data;
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/$filename";
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to download file")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Commission Upload History")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text("No uploads found."))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(log['filename']),
                        subtitle: Text("📆 ${log['commission_period']}\n"
                            "✅ ${log['successful_records']} / ${log['total_records']} records\n"
                            "❌ ${log['failed_records']} failed"),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 10,
                          children: [
                            if (log['original_file_url'] != null)
                              IconButton(
                                icon: const Icon(Icons.file_present),
                                tooltip: "Download Original",
                                onPressed: () => _downloadAndOpenFile(
                                  log['original_file_url'],
                                  log['filename'],
                                ),
                              ),
                            if (log['failed_file_url'] != null)
                              IconButton(
                                icon: const Icon(Icons.error_outline),
                                tooltip: "Download Failed",
                                onPressed: () => _downloadAndOpenFile(
                                  log['failed_file_url'],
                                  "failed_${log['commission_period'].replaceAll(" ", "_")}.xlsx",
                                ),
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
