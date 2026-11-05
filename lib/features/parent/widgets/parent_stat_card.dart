// Read-only stat card for the parent dashboard. No buttons that
// change anything — parent mode is view-only by design.
import 'package:flutter/material.dart';

class ParentStatCard extends StatelessWidget {
  const ParentStatCard({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ]),
      ),
    );
  }
}
