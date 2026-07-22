import 'package:flutter/material.dart';

class AfriOfflineBanner extends StatelessWidget {
  const AfriOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF57C00), // Savanna Amber
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Offline Mode — Changes saved locally',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
