import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('AfriRange AI Privacy Policy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Effective Date: July 22, 2026',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            Divider(height: 24),

            Text('1. Information We Collect',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
                'We collect personal information (name, email), precise location data for farm mapping, and camera photos for botanical plant identification.',
                style: TextStyle(fontSize: 14)),

            SizedBox(height: 16),
            Text('2. How We Use Your Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
                'Your data is processed to generate satellite biomass models, calculate carrying capacity, deliver drought early warning alerts, and process secure billing via Google Play Store.',
                style: TextStyle(fontSize: 14)),

            SizedBox(height: 16),
            Text('3. Data Storage & Security',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
                'All data in transit is encrypted using TLS 1.3 (HTTPS). Data at rest is securely hosted in cloud databases with strict access controls.',
                style: TextStyle(fontSize: 14)),

            SizedBox(height: 16),
            Text('4. Account & Data Deletion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
                'You may delete your account and associated personal data at any time from within the app under Account Settings or by contacting support.',
                style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('AfriRange AI Terms of Service',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Effective Date: July 22, 2026',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            Divider(height: 24),

            Text('1. AI & Rangeland Management Disclaimer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
                'AfriRange AI provides decision support tools for rangeland management, drought prediction, and plant identification. All AI-generated estimates and grazing recommendations should be verified by local agricultural extension officers or qualified agronomists.',
                style: TextStyle(fontSize: 14)),

            SizedBox(height: 16),
            Text('2. Subscriptions & Billing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
                'In-app digital subscriptions and AI credit packs are processed securely via the Google Play Store. Subscriptions renew automatically unless auto-renew is turned off at least 24 hours before the end of the current period in your Google Play settings.',
                style: TextStyle(fontSize: 14)),

            SizedBox(height: 16),
            Text('3. Limitation of Liability',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
                'AfriRange AI is not liable for agricultural losses, livestock death, or environmental damage resulting from reliance on satellite or AI model estimations.',
                style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
