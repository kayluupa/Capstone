import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendEmail() async {
    final String email = _emailController.text;
    final String message = _messageController.text;
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: dotenv.env['GROUP_EMAIL'],
      query: 'subject=User Feedback from $email&body=$message',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not send email. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Feedback'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If you have any questions or found a bug, please let us know!',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Your Email',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Your Message',
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _sendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF227CFF), // Match the blue color
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
