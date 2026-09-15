import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/storage/profile_provider.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});
  @override Widget build(BuildContext context)=> Scaffold(appBar: AppBar(title: const Text('Мини-игры')), body: ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: ListTile(leading: const Icon(Icons.abc), title: const Text('🚦 Угадай знак'), subtitle: const Text('К какой группе относится знак?'), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const GuessSignGame())))),
    Card(child: ListTile(leading: const Icon(Icons.timer), title: const Text('⚡ Да/Нет за 5 сек'), subtitle: const Text('Успей ответить по ПДД'), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const TrueFalseGame())))),
  ]));
}

class GuessSignGame extends ConsumerStatefulWidget { const GuessSignGame({super.key}); @override ConsumerState<GuessSignGame> createState()=>_G(); }
class _G extends ConsumerState<GuessSignGame> {
  List<Map<String,dynamic>> signs=[]; int idx=0, ok=0;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { signs = List<Map<String,dynamic>>.from(jsonDecode(await rootBundle.loadString('assets/data/signs.json'))); setState((){}); }
  @override Widget build(BuildContext context){
    if(signs.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if(idx>=signs.length) return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ Text('Результат: $ok/${signs.length}', style: const TextStyle(fontSize:22, fontWeight: FontWeight.w800)), FilledButton(onPressed: ()=>Navigator.pop(context), child: const Text('Назад'))])));
    final s=signs[idx]; final cats = signs.map((e)=>e['cat'] as String).toSet().toList()..shuffle();
    Widget signImg(){
      final img = s['image'] as String?;
      if(img!=null && img.isNotEmpty){
        final path='assets/images/$img';
        if(img.endsWith('.svg')) return SvgPicture.asset(path, height: 120, placeholderBuilder: (_)=> Text(s['icon'] ?? '🚦', style: const TextStyle(fontSize:64)));
        return Image.asset(path, height: 120, errorBuilder: (_,__,___)=> Text(s['icon'] ?? '🚦', style: const TextStyle(fontSize:64)));
      }
      return Text(s['icon'] ?? '🚦', style: const TextStyle(fontSize:64));
    }
    return Scaffold(appBar: AppBar(title: Text('Угадай знак ${idx+1}/${signs.length}')), body: ListView(padding: const EdgeInsets.all(16), children:[
      Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children:[ signImg(), const SizedBox(height:8), Text(s['name'], textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium), Text(s['desc'] ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)]))),
      const SizedBox(height:8), ...cats.map((c)=> Card(child: ListTile(title: Text(c), onTap: ()=> setState((){ if(c==s['cat']) ok++; idx++; if(c==s['cat']) ref.read(profileProvider.notifier).addCoins(1); })))),
    ]));
  }
}

class TrueFalseGame extends ConsumerStatefulWidget { const TrueFalseGame({super.key}); @override ConsumerState<TrueFalseGame> createState()=>_T(); }
class _T extends ConsumerState<TrueFalseGame> {
  final facts = const [
    ('Велосипедист — это водитель.', true),
    ('На перекрёстке с круговым движением преимущество у въезжающего.', false),
    ('Зелёный мигающий сигнал означает «переход запрещён».', false),
    ('Пешеход имеет преимущество на «зебре».', true),
    ('Шипованные шины можно использовать круглый год.', false),
    ('Автобус, начавший движение от остановки, имеет преимущество.', true),
    ('Знак «Стоянка запрещена» запрещает только стоянку.', false),
    ('Ремень безопасности обязателен для водителя.', true),
  ];
  int idx=0, ok=0, sec=5; Timer? t;
  @override void initState(){super.initState(); _tick();}
  void _tick(){ t=Timer.periodic(const Duration(seconds:1), (_){ if(sec>0) setState(()=>sec--); else _next(false); }); }
  void _next(bool ans){ t?.cancel(); final correct = facts[idx].$2==ans; if(correct){ ok++; ref.read(profileProvider.notifier).addCoins(1);} if(idx<facts.length-1){ setState((){ idx++; sec=5; }); _tick(); } else { setState(()=> idx=-1); } }
  @override void dispose(){ t?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context){
    if(idx==-1) return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ Text('Результат: $ok/${facts.length}', style: const TextStyle(fontSize:22, fontWeight: FontWeight.w800)), Text('+${ok}🪙'), FilledButton(onPressed: ()=>Navigator.pop(context), child: const Text('Назад'))]))); 
    final f=facts[idx];
    return Scaffold(appBar: AppBar(title: Text('Да/Нет $secс')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
      Padding(padding: const EdgeInsets.all(24), child: Text(f.$1, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center)),
      const SizedBox(height:20), Row(mainAxisAlignment: MainAxisAlignment.center, children:[ FilledButton(onPressed: ()=>_next(true), child: const Text('ДА')), const SizedBox(width:20), FilledButton(onPressed: ()=>_next(false), child: const Text('НЕТ')) ]),
    ])));
  }
}
