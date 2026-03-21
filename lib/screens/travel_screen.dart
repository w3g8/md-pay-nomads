import 'package:flutter/material.dart';
import 'passport_screen.dart';
import 'visa_screen.dart';

class TravelScreen extends StatelessWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Services')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _serviceTile(
            context,
            icon: Icons.flight,
            title: 'Digital Nomad Visa',
            subtitle: '12 countries — Portugal, Thailand, Indonesia, Colombia...',
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisaScreen())),
          ),
          const SizedBox(height: 12),
          _serviceTile(
            context,
            icon: Icons.badge,
            title: 'Passport Renewal',
            subtitle: '10 countries — UK, US, Ireland, Australia, Canada...',
            color: Colors.indigo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassportScreen())),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Apply for digital nomad visas and renew your passport from anywhere. '
                'Pay directly from your wallet. Track status in real-time.',
                style: TextStyle(fontSize: 13, color: Colors.amber[800]),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _serviceTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}
