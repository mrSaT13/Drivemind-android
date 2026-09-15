import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';
import '../../data/models/question.dart';
import '../exam/widgets/question_card.dart';

class TrainerScreen extends ConsumerStatefulWidget {
  final bool onlyImage;
  final bool noImage;
  const TrainerScreen({super.key, this.onlyImage = false, this.noImage = false});
  @override ConsumerState<TrainerScreen> createState()=>_Tr();
}
class _Tr extends ConsumerState<TrainerScreen> {
  List<Question> qs=[]; int idx=0, ok=0, total=0;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async {
    var a=await StorageService.loadQuestions();
    if(widget.onlyImage) a=a.where((q)=>q.image!=null).toList();
    if(widget.noImage) a=a.where((q)=>q.image==null).toList();
    a.shuffle(); qs=a; setState((){});
  }
  void _next(bool correct){ total++; final q=qs[idx]; if(correct){ ok++; ref.read(profileProvider.notifier).addCoins(1);} ref.read(profileProvider.notifier).answerQuestion(q.topic, correct); ref.read(profileProvider.notifier).quest(1); if(idx<qs.length-1) setState(()=>idx++); else { ref.read(profileProvider.notifier).record(ok, total); setState(()=>idx=-1);} }
  void _skip(){
    final q=qs.removeAt(idx);
    qs.add(q);
    if(idx>=qs.length) idx=0;
    setState((){});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вопрос перенесён в конец очереди'), duration: Duration(seconds:1)));
  }
  @override Widget build(BuildContext context){
    if(qs.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if(idx==-1) return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ CircularPercentIndicator(radius:80, percent: total==0?0:ok/total, center: Text('${total==0?0:(ok/total*100).toInt()}%'), progressColor: Colors.green), const SizedBox(height:12), const Text('Тренировка завершена'), FilledButton(onPressed: ()=>Navigator.pop(context), child: const Text('Назад'))])));
    final q=qs[idx];
    return Scaffold(appBar: AppBar(title: Text('Тренажёр ${idx+1}/${qs.length}'), bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: LinearProgressIndicator(value:(idx+1)/qs.length)), actions: [TextButton.icon(onPressed: _skip, icon: const Icon(Icons.skip_next, color: Colors.white), label: const Text('Далее', style: TextStyle(color: Colors.white)))]), body: QuestionCard(key: ValueKey(q.id), q:q, onSelect:(v)=>_next(v==q.correctIndex)));
  }
}
