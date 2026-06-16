import 'package:flutter/material.dart';

class LoginActivityPage extends StatelessWidget {
  const LoginActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Login Activity', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _activityEntry('April 13, 10:30', 'Johannesburg', 'Chrome - Windows', 'Successful', Icons.check_circle, Colors.teal),
            const Divider(),
            _activityEntry('April 12, 22:10', 'Unknown Location', 'Unknown', 'Failed Login', Icons.error, Colors.red),
            const SizedBox(height: 16),

            // Suspicious activity card
            Card(
              color: Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Suspicious Activity!', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('This login was from a new location.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2F6F7), foregroundColor: Colors.black, elevation: 0),
                      child: const Text('Secure Account'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2F6F7), foregroundColor: Colors.black, elevation: 0, minimumSize: const Size.fromHeight(44)),
              child: const Text('Report Suspicious Activity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityEntry(String date, String location, String device, String status, IconData icon, Color iconColor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(date),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(location),
          Text(device),
        ],
      ),
      trailing: Text(status, style: TextStyle(color: iconColor)),
    );
  }
}
