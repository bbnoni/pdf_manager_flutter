import 'package:flutter/material.dart';

class SmsBlastScreen extends StatefulWidget {
  const SmsBlastScreen({Key? key}) : super(key: key);

  @override
  _SmsBlastScreenState createState() => _SmsBlastScreenState();
}

class _SmsBlastScreenState extends State<SmsBlastScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _agents = [
    'Agent 1',
    'Agent 2',
    'Agent 3'
  ]; // Replace with dynamic data
  final List<String> _selectedAgents = [];

  void _sendSmsBlast() {
    if (_selectedAgents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one agent.')),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot be empty.')),
      );
      return;
    }
    // Implement the logic to send SMS here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SMS blast sent successfully!')),
    );
    _messageController.clear();
    setState(() {
      _selectedAgents.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send SMS Blast')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _agents.map((agent) {
                  return CheckboxListTile(
                    title: Text(agent),
                    value: _selectedAgents.contains(agent),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedAgents.add(agent);
                        } else {
                          _selectedAgents.remove(agent);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: _sendSmsBlast,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
