import 'package:flutter/material.dart';
import '../../../core/theme/glass.dart';
class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const StatCard({super.key, required this.title, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return GlassContainer(child: Row(children: [Icon(icon), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.labelSmall), Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))])]));
  }
}
