import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_logo.dart';

class OnboardingScreen extends StatefulWidget { const OnboardingScreen({super.key}); @override State<OnboardingScreen> createState()=>_O(); }
class _O extends State<OnboardingScreen> {
  final pc = PageController(); int i=0;
  final pages = const [
    ('🧠','DriveMind','Учи ПДД 2025 в игровой форме'),
    ('🎨','Тёмные темы','Премиум-оформление, градиенты, Material You'),
    ('🔔','Напоминания','Ежедневные квесты и streak'),
    ('🏆','Достижения','Очки, магазин и ачивки за прогресс'),
  ];
  @override Widget build(BuildContext context){
    return Scaffold(body: Column(children: [
      const SizedBox(height: 40),
      const AppLogo(size: 70),
      Expanded(child: PageView(controller: pc, children: pages.map((p)=> Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ Text(p.$1, style: const TextStyle(fontSize: 80)), const SizedBox(height:16), Text(p.$2, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height:8), Text(p.$3, textAlign: TextAlign.center)]))).toList())),
      SmoothPageIndicator(controller: pc, count: pages.length),
      const SizedBox(height: 20),
      FilledButton(onPressed: () async { if(i<pages.length-1){ pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease); } else { await StorageService.setOnboarded(); Navigator.pushReplacementNamed(context, '/'); } }, child: Text(i<pages.length-1?'Далее':'Начать')),
      const SizedBox(height: 30),
    ],),);
  }
  @override void initState(){ super.initState(); pc.addListener(()=> setState(()=> i = pc.page?.round() ?? 0)); }
}
