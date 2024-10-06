// terms and conditions go here
import 'package:flutter/material.dart';

class TandCScreen extends StatelessWidget {
  const TandCScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: const Color.fromARGB(255, 124, 33, 243),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms and Conditions for Meet Me Halfway',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Effective Date: 10/01/2024',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 24),
              Text(
                '1. Introduction',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Welcome to Meet Me Halfway! By using our app, you agree to comply with and be bound by the following terms and conditions. These terms apply to all users of the app. Please read them carefully before using the app.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '2. Account Creation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'To access and use Meet Me Halfway, you must create an account. You agree to provide accurate and complete information during the account creation process. You are responsible for maintaining the confidentiality of your login credentials and for any activity that occurs under your account.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '3. Location Access',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'To provide its core features, Meet Me Halfway requires access to your location. By using the app, you consent to sharing your location data, which is necessary to calculate meeting points and provide location-based services. Your location data is used solely for these purposes and is not shared with third parties or used for any other reason beyond the functioning of the app.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '4. Data Security',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We take the security of your data seriously. All user data, including account information and location data, is encrypted using Firebase to prevent unauthorized access. We do not collect or use your data for any purpose outside of the app’s functionality.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '5. Permitted Use',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You are granted a limited, non-exclusive, and non-transferable license to use Meet Me Halfway. You agree not to misuse the app in any way, including but not limited to attempting to reverse engineer the app, using the app for illegal activities, or harming other users.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '6. Termination',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We reserve the right to suspend or terminate your account if you violate these terms and conditions or engage in activities that harm the integrity or security of the app. You may also terminate your account at any time by contacting us.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '7. Limitation of Liability',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Meet Me Halfway is provided on an "as is" basis. We make no warranties regarding the app’s functionality or availability. To the fullest extent permitted by law, we disclaim any liability for damages arising out of or related to your use of the app.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '8. Changes to Terms and Conditions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We may update these Terms and Conditions from time to time to reflect changes in our practices or legal requirements. If changes are made, we will notify users by updating the effective date at the top of this document.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '9. Governing Law',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'These terms and conditions are governed by and construed in accordance with the laws of [Insert Country/Region].',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '10. Contact Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'If you have any questions about these Terms and Conditions or need further assistance, please contact us at:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Email: algorithmavengers4901@gmail.com',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              Text(
                'Thank you for using Meet Me Halfway. We are committed to providing you with a safe and reliable experience.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
