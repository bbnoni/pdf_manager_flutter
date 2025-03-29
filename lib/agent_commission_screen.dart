import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdf_manager/dio_client.dart';

import 'commission_details_screen.dart';
import 'login_screen.dart';

const String baseUrl = "https://pdf-manager-eygj.onrender.com";

class AgentCommissionScreen extends StatefulWidget {
  const AgentCommissionScreen({super.key});

  @override
  _AgentCommissionScreenState createState() => _AgentCommissionScreenState();
}

class _AgentCommissionScreenState extends State<AgentCommissionScreen> {
  //final Dio dio = Dio();
  final Dio dio = DioClient.dio;
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> commissions = [];
  List<Map<String, dynamic>> filteredCommissions = [];
  bool _isLoading = true;
  String searchQuery = "";
  String? firstName; // 🟢 Add this

  @override
  void initState() {
    super.initState();
    DioClient.init(context); // Initialize Dio client with interceptors
    loadUserInfo();
    fetchCommissions();
  }

  Future<void> loadUserInfo() async {
    final name = await storage.read(key: "first_name");
    setState(() {
      firstName = name;
    });
  }

  Future<void> fetchCommissions() async {
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
          commissions.sort((a, b) =>
              DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

          filteredCommissions = commissions;
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
      _showMessage(
          "❌ ERROR: ${e.response?.data?['error'] ?? 'Something went wrong'}");
    }
  }

  void _filterCommissions(String query) {
    setState(() {
      searchQuery = query;
      filteredCommissions = commissions.where((commission) {
        return commission['commission_period']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            commission['date']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _logout() async {
    await storage.deleteAll();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: isMobile
              ? AppBar(
                  title: const Text("MM Agent Portal"),
                  backgroundColor: Colors.blueAccent,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                )
              : null,
          drawer: isMobile ? _buildDrawer() : null,
          body: Row(
            children: [
              if (!isMobile) _buildSidebar(),
              Expanded(
                child: Center(
                  child: Container(
                    width: constraints.maxWidth > 1000
                        ? 800
                        : constraints.maxWidth * 0.9,
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
                        : Column(
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search by week or date',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: _filterCommissions,
                              ),
                              const SizedBox(height: 15),
                              Expanded(
                                child: filteredCommissions.isEmpty
                                    ? const Center(
                                        child: Text("No commissions found."))
                                    : ListView.builder(
                                        itemCount: filteredCommissions.length,
                                        itemBuilder: (context, index) {
                                          final commission =
                                              filteredCommissions[index];
                                          return Card(
                                            elevation: 4,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.all(10),
                                              title: Text(
                                                "GH₵${commission['amount']}",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18),
                                              ),
                                              subtitle: Text(
                                                //"Date: ${commission['date']}  •  Period: ${commission['commission_period']}",
                                                "Period: ${commission['commission_period']}",
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                    Icons.remove_red_eye,
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
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.blueAccent,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "👋 Welcome, ${firstName ?? "Agent"}!",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "MM Agent Portal",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    _buildSidebarItem(Icons.dashboard, "Dashboard"),
                    _buildSidebarItem(
                      Icons.money,
                      "My Commissions",
                      isActive: true,
                      onTap: () async {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context); // close Drawer on mobile
                        }

                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        // Reset and fetch commissions
                        setState(() {
                          searchQuery = "";
                        });

                        await fetchCommissions(); // refresh commissions

                        // Close loading indicator after fetch
                        if (mounted) Navigator.pop(context);

                        _showMessage("✅ Refreshed commissions!");
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildAccountSection(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "© DocMgt Francis 2025",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.blueAccent,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "👋 Welcome, ${firstName ?? "Agent"}!",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "MM Agent Portal",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSidebarItem(Icons.dashboard, "Dashboard"),
                    _buildSidebarItem(
                      Icons.money,
                      "My Commissions",
                      isActive: true,
                      onTap: () async {
                        Navigator.pop(context); // close drawer
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        setState(() => searchQuery = "");
                        await fetchCommissions();

                        if (mounted) Navigator.pop(context);
                        _showMessage("✅ Refreshed commissions!");
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildAccountSection(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "© DocMgt Francis 2025",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title,
      {VoidCallback? onTap, bool isActive = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      tileColor: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white70),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("ACCOUNT",
              style: TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
        ),
        _buildSidebarItem(Icons.settings, "Settings"),
        _buildSidebarItem(Icons.logout, "Logout", onTap: _logout),
      ],
    );
  }
}
