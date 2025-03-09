import 'package:flutter/material.dart';

import 'agent_commission_screen.dart';
import 'login_screen.dart';
import 'manager_commission_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PDF Manager",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
      routes: {
        '/manager_commissions': (context) => const ManagerCommissionScreen(),
        '/agent_commissions': (context) => const AgentCommissionScreen(),
      },
    );
  }
}
