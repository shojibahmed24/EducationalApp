import 'package:flutter/material.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.title, required this.meta, required this.progress, this.locked = false, this.onTap});
  final String title;
  final String meta;
  final double progress;
  final bool locked;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(locked ? Icons.lock : Icons.menu_book, color: locked ? AppTheme.inkMuted : AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
            ]),
            const SizedBox(height: 4),
            Text(meta, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            if (!locked) ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 8, color: AppTheme.success)),
            if (locked) Text('🔒', style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
      ),
    );
  }
}
