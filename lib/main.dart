import 'package:agentportal/firebase_options.dart';
import 'package:agentportal/widgets/inactivity_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'agent_commission_screen.dart';
import 'login_screen.dart';
import 'manager_commission_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://gottknpkjqqlmghyilcf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvdHRrbnBranFxbG1naHlpbGNmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MzAyOTIzOSwiZXhwIjoyMDU4NjA1MjM5fQ.Fq6ya6EpS7yQFn3IbUUsh7LQIImF9soGpCv56VyPp5k',
  );
  //runApp(const MyApp());
  runApp(InactivityHandler(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Agent Portal",
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
