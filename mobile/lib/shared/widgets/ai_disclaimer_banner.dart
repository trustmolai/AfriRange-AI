import 'package:flutter/material.dart';

class AiDisclaimerBanner extends StatelessWidget {
  final String text;

  const AiDisclaimerBanner({
    Key? key,
    this.text = 'AI-assisted estimation. Verify plant toxicity and grazing decisions with a qualified local agronomist or rangeland specialist.',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
