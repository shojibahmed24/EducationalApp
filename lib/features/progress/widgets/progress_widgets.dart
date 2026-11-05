import 'package:flutter/material.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

class StreakRow extends StatelessWidget {
  const StreakRow({super.key, required this.days, required this.label, this.active});
  final List<String> days;
  final String label;
  /// Per-day activity, same length as [days]; null = unknown (grey).
  final List<bool>? active;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.local_fire_department, color: AppTheme.amber), const SizedBox(width: 8), Expanded(child: Text(label, style: Theme.of(context).textTheme.headlineMedium))]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: days.asMap().entries.map((e) {
            final on = active == null || e.key >= active!.length ? false : active![e.key];
            return Column(children: [CircleAvatar(radius: 16, backgroundColor: on ? AppTheme.success : AppTheme.inkMuted.withValues(alpha: 0.3), child: Icon(on ? Icons.check : Icons.close, size: 16, color: Colors.white)), const SizedBox(height: 4), Text(e.value, style: Theme.of(context).textTheme.bodySmall)]);
          }).toList()),
        ]),
      ),
    );
  }
}

/// Daily-goal ring: today completed vs daily goal, from saved runs.
class GoalRing extends StatelessWidget {
  const GoalRing({super.key, required this.done, required this.goal, required this.label});
  final int done, goal;
  final String label;
  @override
  Widget build(BuildContext context) {
    final v = goal == 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          SizedBox(width: 72, height: 72, child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(child: CircularProgressIndicator(value: v, strokeWidth: 8, color: AppTheme.amber, backgroundColor: AppTheme.inkMuted.withValues(alpha: 0.3))),
            Text('$done/$goal', style: Theme.of(context).textTheme.headlineMedium),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.headlineMedium)),
        ]),
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.title, required this.done, this.onTap});
  final String title;
  final bool done;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(done ? Icons.check_circle : Icons.circle_outlined, color: done ? AppTheme.success : AppTheme.inkMuted),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
