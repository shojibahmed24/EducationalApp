// One benefit row on the paywall. Pure display, no navigation.
import 'package:flutter/material.dart';

class PremiumFeatureRow extends StatelessWidget {
  const PremiumFeatureRow({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [Icon(icon, color: Colors.green), const SizedBox(width: 12), Expanded(child: Text(text))]),
    );
  }
}
