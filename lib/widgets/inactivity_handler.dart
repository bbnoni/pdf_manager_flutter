import 'dart:async';

import 'package:agentportal/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InactivityHandler extends StatefulWidget {
  final Widget child;
  const InactivityHandler({super.key, required this.child});

  @override
  State<InactivityHandler> createState() => _InactivityHandlerState();
}

class _InactivityHandlerState extends State<InactivityHandler> {
  Timer? _inactivityTimer;
  static const Duration timeoutDuration = Duration(minutes: 5);
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(timeoutDuration, _handleTimeout);
  }

  void _handleTimeout() async {
    debugPrint("🔒 Logging out due to inactivity...");
    await storage.deleteAll();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out due to inactivity.")),
      );
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _startInactivityTimer(),
      onPointerMove: (_) => _startInactivityTimer(),
      onPointerUp: (_) => _startInactivityTimer(),
      child: widget.child,
    );
  }
}
