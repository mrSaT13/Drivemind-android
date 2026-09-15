import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';
import '../../data/models/question.dart';
import '../exam/widgets/question_card.dart';

class SpeedScreen extends ConsumerStatefulWidget { const SpeedScreen({super.key}); @override ConsumerState<SpeedScreen> createState()=>_S(); }
class _S extends ConsumerState<SpeedScreen> {
  List<Question> qs=[]; int idx=0, correct=0; int sec=60; Timer? t;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { final a=await StorageService.loadQuestions(); a.shuffle(); qs=a; t=Timer.periodic(const Duration(seconds:1), (_){ if(sec>0) setState(()=>sec--); else _finish(); }); setState((){}); }
  void _ans(bool ok){ final q=qs[idx]; if(ok){ correct++; ref.read(profileProvider.notifier).addCoins(2); } ref.read(profileProvider.notifier).answerQuestion(q.topic, ok); ref.read(profileProvider.notifier).quest(1); if(idx<qs.length-1) setState(()=>idx++); else _finish(); }
  void _skip(){ final q=qs.removeAt(idx); qs.add(q); if(idx>=qs.length) idx=0; setState((){}); }
  void _finish(){ t?.cancel(); showDialog(context: context, builder: (_)=> AlertDialog(title: const Text('Время!'), content: Text('$correct правильных за минуту\n+${correct*2} 🪙'), actions: [FilledButton(onPressed: ()=>Navigator.pop(context), child: const Text('Ок'))])); }
  @override void dispose(){ t?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context){
    if(qs.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(appBar: AppBar(title: Text('⚡ Speed $secс'), bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: LinearProgressIndicator(value: sec/60)), actions: [TextButton.icon(onPressed: _skip, icon: const Icon(Icons.skip_next, color: Colors.white), label: const Text('Далее', style: TextStyle(color: Colors.white)))]), body: QuestionCard(key: ValueKey(qs[idx].id), q: qs[idx], onSelect:(v)=>_ans(v==qs[idx].correctIndex)));
  }
}
