import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/profile_provider.dart';

class ErrorMapScreen extends ConsumerWidget {
  const ErrorMapScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final p = ref.watch(profileProvider);
    final max = p.mistakesByTheme.values.isEmpty ? 1 : p.mistakesByTheme.values.reduce((a,b)=>a>b?a:b);
    return Scaffold(appBar: AppBar(title: const Text('Карта ошибок')), body: ListView(padding: const EdgeInsets.all(16), children:[
      const Text('Билеты (цвет = число ошибок)', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, crossAxisSpacing: 6, mainAxisSpacing: 6), itemCount: 40, itemBuilder: (_, i){
        final key='Билет ${i+1}';
        final n=p.mistakesByTheme[key] ?? 0;
        final t = max==0?0:n/max;
        return Container(decoration: BoxDecoration(color: n==0?Colors.green.withOpacity(0.3):Colors.red.withOpacity(0.3+t*0.7), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('${i+1}', style: const TextStyle(fontWeight: FontWeight.w700))));
      }),
      const SizedBox(height: 20),
      const Text('Топ ошибок по темам', style: TextStyle(fontWeight: FontWeight.w700)),
      ...(p.mistakesByTheme.entries.toList()..sort((a,b)=>b.value.compareTo(a.value))).map((e)=> ListTile(title: Text(e.key), trailing: Chip(label: Text('${e.value}')))),
      if(p.mistakesByTheme.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Ошибок пока нет 🎉'))),
    ]));
  }
}
