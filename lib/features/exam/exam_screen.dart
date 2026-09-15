import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';
import '../../data/models/question.dart';
import 'widgets/question_card.dart';

class ExamScreen extends ConsumerStatefulWidget {
  final bool ab;
  const ExamScreen({super.key, this.ab = false});
  @override ConsumerState<ExamScreen> createState() => _E();
}
class _E extends ConsumerState<ExamScreen> {
  List<Question> qs = [];
  int idx = 0, correct = 0, errors = 0;
  int sec = 20*60;
  Timer? t;
  bool finished = false;

  @override
  void initState(){ super.initState(); _start(); }
  Future<void> _start() async {
    final all = await StorageService.loadQuestions();
    all.shuffle(); qs = all.take(20).toList();
    if(widget.ab){ for(final q in qs){ final opts = List<String>.from(q.options); final c = q.correctIndex; opts.shuffle(); qs[qs.indexOf(q)] = Question(id: q.id, text: q.text, image: q.image, options: opts, correctIndex: opts.indexOf(q.options[c]), hint: q.hint, topic: q.topic, ticket: q.ticket); } }
    t = Timer.periodic(const Duration(seconds: 1), (_){ if(sec>0) setState(()=>sec--); else _finish(); });
    setState((){});
  }
  void _answer(int choice){
    final q = qs[idx];
    final ok = choice==q.correctIndex;
    if(ok){ correct++; ref.read(profileProvider.notifier).addCoins(5); } else { errors++; StorageService.addMistake(q.id); }
    ref.read(profileProvider.notifier).answerQuestion(q.topic, ok);
    ref.read(profileProvider.notifier).quest(1);
    if(errors>=3 || idx>=19) { _finish(); return; }
    setState(()=>idx++);
  }
  void _skip(){
    if(finished) return;
    final q=qs.removeAt(idx);
    qs.add(q);
    if(idx>=qs.length) idx=0;
    setState((){});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вопрос перенесён в конец'), duration: Duration(seconds:1)));
  }
  void _finish(){
    t?.cancel();
    ref.read(profileProvider.notifier).record(correct, 20);
    setState(()=>finished=true);
  }
  @override void dispose(){ t?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context){
    if(qs.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if(finished) return Scaffold(appBar: AppBar(title: const Text('Результат')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(correct>=18?Icons.emoji_events:Icons.close, size: 80, color: correct>=18?Colors.amber:Colors.red), Text(correct>=18?'СДАН':'НЕ СДАН', style: Theme.of(context).textTheme.headlineMedium), Text('$correct/20 за ${20*60-sec}с • ошибок $errors • +${correct*5}🪙'), const SizedBox(height:16), FilledButton(onPressed: ()=>Navigator.pop(context), child: const Text('На главную'))])));
    final q = qs[idx];
    return Scaffold(
      appBar: AppBar(title: Text('Экзамен ${idx+1}/20 • ${sec~/60}:${(sec%60).toString().padLeft(2,'0')}'), bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: LinearProgressIndicator(value: (idx+1)/20)), actions: [TextButton.icon(onPressed: _skip, icon: const Icon(Icons.skip_next, color: Colors.white), label: const Text('Далее', style: TextStyle(color: Colors.white)))]),
      body: QuestionCard(key: ValueKey(q.id), q: q, onSelect: _answer, showActions: false),
    );
  }
}
