import 'package:flutter/material.dart';
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 80});
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accent.withOpacity(0.4)]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 20)]),
        child: Center(child: Icon(Icons.directions_car, size: size * 0.5, color: Colors.white)),
      ),
      const SizedBox(height: 12),
      Text('DriveMind', style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w900, letterSpacing: 1, color: Theme.of(context).colorScheme.onBackground)),
    ]);
  }
}
