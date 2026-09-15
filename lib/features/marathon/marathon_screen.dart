import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';
import '../../data/models/question.dart';
import '../exam/widgets/question_card.dart';

class MarathonScreen extends ConsumerStatefulWidget { const MarathonScreen({super.key}); @override ConsumerState<MarathonScreen> createState()=>_M(); }
class _M extends ConsumerState<MarathonScreen> {
  List<Question> qs=[]; int idx=0, done=0, correct=0; ConfettiController conf = ConfettiController(duration: const Duration(seconds:2));
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { final a=await StorageService.loadQuestions(); a.shuffle(); qs=a.take(800).toList(); setState((){}); }
  void _next(bool ok){ final q=qs[idx]; if(ok){ correct++; ref.read(profileProvider.notifier).addCoins(1); } ref.read(profileProvider.notifier).answerQuestion(q.topic, ok); ref.read(profileProvider.notifier).quest(1); if(idx>=qs.length-1){ conf.play(); ref.read(profileProvider.notifier).record(correct, qs.length); setState(()=>done=qs.length); return; } setState(()=>idx++); }
  void _skip(){ final q=qs.removeAt(idx); qs.add(q); if(idx>=qs.length) idx=0; setState((){}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('В конец очереди'), duration: Duration(seconds:1))); }
  @override Widget build(BuildContext context){
    if(qs.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if(done==qs.length) return Scaffold(body: Stack(children:[Center(child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[const Text('🏁 Марафон пройден!', style: TextStyle(fontSize:22, fontWeight:FontWeight.w800)), Text('+${correct}🪙'), FilledButton(onPressed: ()=>Navigator.pop(context), child: const Text('Готово'))])), Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: conf, blastDirectionality: BlastDirectionality.explosive))]));
    final q=qs[idx];
    return Scaffold(appBar: AppBar(title: Text('Марафон ${idx+1}/${qs.length}'), bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: LinearProgressIndicator(value:(idx+1)/qs.length)), actions: [TextButton.icon(onPressed: _skip, icon: const Icon(Icons.skip_next, color: Colors.white), label: const Text('Далее', style: TextStyle(color: Colors.white)))]), body: QuestionCard(key: ValueKey(q.id), q:q, onSelect:(v)=>_next(v==q.correctIndex), showActions: false));
  }
}
