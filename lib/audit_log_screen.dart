// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:url_launcher/url_launcher.dart';

// class AuditLogScreen extends StatefulWidget {
//   const AuditLogScreen({super.key});

//   @override
//   State<AuditLogScreen> createState() => _AuditLogScreenState();
// }

// class _AuditLogScreenState extends State<AuditLogScreen> {
//   final Dio dio = Dio();
//   final storage = FlutterSecureStorage();
//   List<dynamic> _logs = [];
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchAuditLogs();
//   }

//   Future<void> fetchAuditLogs() async {
//     String? token = await storage.read(key: "token");
//     if (token == null) return;

//     try {
//       final response = await dio.get(
//         'https://pdf-manager-eygj.onrender.com/audit_logs',
//         options: Options(headers: {'Authorization': 'Bearer $token'}),
//       );

//       setState(() {
//         _logs = response.data;
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() => _loading = false);
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text("Failed to fetch logs")));
//     }
//   }

//   Future<void> _downloadAndOpenFile(String url, String filename) async {
//     String? token = await storage.read(key: "token");
//     if (token == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("No token found")));
//       return;
//     }

//     try {
//       if (url.startsWith("http")) {
//         final uri = Uri.parse(url);
//         if (await canLaunchUrl(uri)) {
//           await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("❌ Could not launch the file URL")),
//           );
//         }
//         return;
//       }

//       // ✅ Flask local path (e.g., /download_failed_commissions)
//       final fullUrl = "https://pdf-manager-eygj.onrender.com$url";

//       final response = await dio.get(
//         fullUrl,
//         options: Options(
//           headers: {'Authorization': 'Bearer $token'},
//           responseType: ResponseType.bytes,
//         ),
//       );

//       final bytes = response.data;
//       final dir = await getTemporaryDirectory();
//       final filePath = "${dir.path}/$filename";
//       final file = File(filePath);
//       await file.writeAsBytes(bytes);

//       await OpenFile.open(filePath);
//     } catch (e) {
//       debugPrint("❌ Download error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("❌ Failed to download file")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Commission Upload History")),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _logs.isEmpty
//               ? const Center(child: Text("No uploads found."))
//               : ListView.builder(
//                   itemCount: _logs.length,
//                   itemBuilder: (context, index) {
//                     final log = _logs[index];
//                     return Card(
//                       margin: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 6),
//                       child: ListTile(
//                         title: Text(log['filename']),
//                         subtitle: Text("📆 ${log['commission_period']}\n"
//                             "✅ ${log['successful_records']} / ${log['total_records']} records\n"
//                             "❌ ${log['failed_records']} failed"),
//                         isThreeLine: true,
//                         trailing: Wrap(
//                           spacing: 10,
//                           children: [
//                             if (log['original_file_url'] != null)
//                               IconButton(
//                                 icon: const Icon(Icons.file_present),
//                                 tooltip: "Download Original",
//                                 onPressed: () => _downloadAndOpenFile(
//                                   log['original_file_url'],
//                                   log['filename'],
//                                 ),
//                               ),
//                             if (log['failed_file_url'] != null)
//                               IconButton(
//                                 icon: const Icon(Icons.error_outline),
//                                 tooltip: "Download Failed",
//                                 onPressed: () => _downloadAndOpenFile(
//                                   log['failed_file_url'],
//                                   "failed_${log['commission_period'].replaceAll(" ", "_")}.xlsx",
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final Dio dio = Dio();
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> auditLogs = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAuditLogs();
  }

  Future<void> fetchAuditLogs() async {
    setState(() => isLoading = true);

    try {
      final token = await storage.read(key: 'token');
      final response = await dio.get(
        '$baseUrl/audit_logs',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(
          () => auditLogs = List<Map<String, dynamic>>.from(response.data));
    } catch (e) {
      debugPrint("❌ Failed to fetch audit logs: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _downloadFile(String url, String defaultName) async {
    if (kIsWeb) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }

    try {
      final token = await storage.read(key: 'token');
      final response = await dio.get(
        url.startsWith("http") ? url : '$baseUrl$url',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/$defaultName";
      final file = File(filePath);
      await file.writeAsBytes(response.data);
      await OpenFile.open(filePath);
    } catch (e) {
      debugPrint("❌ Error opening file: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Failed to download file.")));
    }
  }

  Widget _buildAuditCard(Map<String, dynamic> log) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        title: Text("🗂 ${log['commission_period']}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Records: ${log['successful_records']} successful / ${log['failed_records']} failed"),
            Text("Uploaded: ${log['timestamp']}"),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            final url = value == "original"
                ? log['original_file_url']
                : log['failed_file_url'];
            final filename = value == "original"
                ? "original_${log['commission_period']}.xlsx"
                : "failed_${log['commission_period']}.xlsx";
            _downloadFile(url, filename);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "original",
              child: Text("📥 Download Original"),
            ),
            if (log['failed_file_url'] != null)
              const PopupMenuItem(
                value: "failed",
                child: Text("⚠️ Download Failed Records"),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audit Logs"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : auditLogs.isEmpty
              ? const Center(child: Text("No audit logs found."))
              : ListView(
                  children: auditLogs.map(_buildAuditCard).toList(),
                ),
    );
  }
}
