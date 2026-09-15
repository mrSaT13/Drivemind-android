import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_logo.dart';
import '../../core/storage/storage_service.dart';

class SplashScreen extends ConsumerStatefulWidget { const SplashScreen({super.key}); @override ConsumerState<SplashScreen> createState()=>_S(); }
class _S extends ConsumerState<SplashScreen> {
  @override void initState(){ super.initState(); _go(); }
  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final started = await StorageService.getOnboarded();
    if(!mounted) return;
    Navigator.pushReplacementNamed(context, started ? '/' : '/onboarding');
  }
  @override Widget build(BuildContext context)=> Scaffold(body: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).colorScheme.primary.withOpacity(0.3), Theme.of(context).scaffoldBackgroundColor])), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ const AppLogo(size: 110), const SizedBox(height: 24), const CircularProgressIndicator() ]))));
}
