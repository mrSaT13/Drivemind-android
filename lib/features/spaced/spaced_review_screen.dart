import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';
import '../../data/models/question.dart';
import '../exam/widgets/question_card.dart';

class SpacedReviewScreen extends ConsumerStatefulWidget { const SpacedReviewScreen({super.key}); @override ConsumerState<SpacedReviewScreen> createState()=>_S(); }
class _S extends ConsumerState<SpacedReviewScreen> {
  List<Question> due=[]; int idx=0;
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    final p = ref.read(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final all = await StorageService.loadQuestions();
    final ids = {...p.mistakesByTheme.keys, ...p.hardQuestions};
    due = all.where((e)=> ids.contains(e.id) && notifier.isSpacedDue(e.id)).toList();
    setState((){});
  }
  void _answered(bool ok){ final q=due[idx]; final id=q.id; ref.read(profileProvider.notifier).answerQuestion(q.topic, ok); ref.read(profileProvider.notifier).scheduleSpaced(id, correct: ok); ref.read(profileProvider.notifier).quest(1); if(idx<due.length-1) setState(()=>idx++); else { setState(()=>idx=-1); } }
  @override Widget build(BuildContext context){
    if(due.isEmpty && idx!=-1) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if(idx==-1 || due.isEmpty) return Scaffold(appBar: AppBar(title: const Text('Повторения')), body: const Center(child: Text('🎉 Всё повторено! Приходи позже')));
    final q=due[idx];
    return Scaffold(appBar: AppBar(title: Text('Повторение ${idx+1}/${due.length}'), actions: [TextButton.icon(onPressed: (){ final qq=due.removeAt(idx); due.add(qq); if(idx>=due.length) idx=0; setState((){}); }, icon: const Icon(Icons.skip_next, color: Colors.white), label: const Text('Далее', style: TextStyle(color: Colors.white)))]), body: QuestionCard(key: ValueKey(q.id), q: q, showActions: false, onSelect: (v)=>_answered(v==q.correctIndex)));
  }
}
