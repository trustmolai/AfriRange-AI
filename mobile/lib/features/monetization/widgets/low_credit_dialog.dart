import 'package:flutter/material.dart';
import '../screens/plans_screen.dart';
import '../screens/ai_credits_screen.dart';

class LowCreditDialog extends StatelessWidget {
  final int currentBalance;

  const LowCreditDialog({Key? key, required this.currentBalance}) : super(key: key);

  static void show(BuildContext context, int balance) {
    showDialog(
      context: context,
      builder: (context) => LowCreditDialog(currentBalance: balance),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 8),
          Text('Low AI Credits'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have $currentBalance AI credit${currentBalance == 1 ? '' : 's'} remaining.',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade your subscription or purchase additional credit packs through Google Play to continue using AI analyses without interruption.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AiCreditsScreen()),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
          child: const Text('Buy Credits', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlansScreen()),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
          child: const Text('Upgrade Plan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
