import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/storage/profile_provider.dart';

class SignsTrainer extends ConsumerStatefulWidget { const SignsTrainer({super.key}); @override ConsumerState<SignsTrainer> createState()=>_S(); }
class _S extends ConsumerState<SignsTrainer> {
  List<Map<String,dynamic>> signs=[]; int idx=0, ok=0; String? sel;
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async { final raw=await rootBundle.loadString('assets/data/signs.json'); signs=List<Map<String,dynamic>>.from(jsonDecode(raw)); setState((){}); }
  List<String> get cats => signs.map((s)=>s['cat'] as String).toSet().toList();
  void _ans(String c){
    final correct = signs[idx]['cat']==c;
    if(correct){ ok++; ref.read(profileProvider.notifier).addCoins(1); }
    if(idx<signs.length-1) setState(()=>idx++); else setState(()=>idx=-1);
  }
  @override Widget build(BuildContext context){
    if(signs.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if(idx==-1) return Scaffold(body: Center(child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[ Text('🚦 Готово! $ok/${signs.length}', style: const TextStyle(fontSize:22, fontWeight:FontWeight.w800)), Text('+${ok}🪙'), FilledButton(onPressed: ()=>Navigator.pop(context), child: const Text('Назад'))])));
    final s=signs[idx];
    final opts = cats..shuffle();
    Widget signImage() {
      final img = s['image'] as String?;
      if (img != null && img.isNotEmpty) {
        final path = 'assets/images/$img';
        if (img.endsWith('.svg')) {
          return SvgPicture.asset(path, height: 120, placeholderBuilder: (_) => Text(s['icon'] ?? '🚦', style: const TextStyle(fontSize: 64)));
        } else {
          return Image.asset(path, height: 120, errorBuilder: (_,__,___)=> Text(s['icon'] ?? '🚦', style: const TextStyle(fontSize: 64)));
        }
      }
      return Text(s['icon'] ?? '🚦', style: const TextStyle(fontSize: 64));
    }
    return Scaffold(appBar: AppBar(title: Text('Знаки ${idx+1}/${signs.length}')), body: ListView(padding: const EdgeInsets.all(16), children:[
      Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children:[ signImage(), const SizedBox(height:8), Text(s['name'], style: Theme.of(context).textTheme.titleLarge, textAlign:TextAlign.center), Text(s['desc'], style: Theme.of(context).textTheme.bodySmall, textAlign:TextAlign.center)]))),
      const SizedBox(height:12),
      const Text('К какой группе относится знак?', style: TextStyle(fontWeight:FontWeight.w700)),
      const SizedBox(height:8),
      ...opts.map((c)=> Card(child: ListTile(title: Text(c), trailing: const Icon(Icons.chevron_right), onTap: ()=>_ans(c)))),
    ]));
  }
}
