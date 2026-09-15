import 'package:flutter/material.dart';
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? tint;
  const GlassContainer({super.key, required this.child, this.borderRadius = 16, this.padding = const EdgeInsets.all(16), this.blur = 12, this.tint});
  @override
  Widget build(BuildContext context) {
    final c = tint ?? Theme.of(context).colorScheme.surface.withOpacity(0.25);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: c,
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: child,
        ),
      ),
    );
  }
}
