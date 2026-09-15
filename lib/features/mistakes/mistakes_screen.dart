import 'package:flutter/material.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/question.dart';
import '../exam/widgets/question_card.dart';

class MistakesScreen extends StatefulWidget { const MistakesScreen({super.key}); @override State<MistakesScreen> createState()=>_M(); }
class _M extends State<MistakesScreen> {
  List<Question> qs=[]; int idx=0;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async {
    final all = await StorageService.loadQuestions();
    final ids = StorageService.mistakes;
    final filtered = all.where((e)=>ids.contains(e.id)).toList();
    setState((){ qs=filtered; idx=0; });
  }
  void _removeCurrent() async {
    if(qs.isEmpty) return;
    final id=qs[idx].id;
    final m=StorageService.mistakes.toList();
    m.remove(id);
    await StorageService.box.put('mistakes', m);
    setState((){ qs.removeAt(idx); if(idx>=qs.length) idx=qs.length-1; if(qs.isEmpty) idx=0; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Удалено из ошибок')));
  }
  void _clearAll() async { await StorageService.clearMistakes(); setState((){ qs=[]; idx=0; }); }
  @override Widget build(BuildContext context){
    if(qs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибки'), actions: [IconButton(icon: const Icon(Icons.delete), onPressed: _clearAll)]),
        body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ Icon(Icons.check_circle, size:64, color: Colors.green), SizedBox(height:12), Text('Ошибок нет — ты красавчик!', style: TextStyle(fontSize:18, fontWeight: FontWeight.w700)), Text('Допускай ошибки в тренировках и они появятся здесь с разбором')]))),
      );
    }
    final q=qs[idx];
    return Scaffold(
      appBar: AppBar(title: Text('Ошибки ${idx+1}/${qs.length}'), actions: [
        IconButton(icon: const Icon(Icons.delete), onPressed: _clearAll, tooltip: 'Очистить все'),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Обновить'),
      ]),
      body: Column(children:[
        LinearProgressIndicator(value: (idx+1)/qs.length, minHeight:4),
        Expanded(child: SingleChildScrollView(child: Column(children:[
          QuestionCard(key: ValueKey(q.id), q: q, showActions: false),
          Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Card(color: Colors.green.withOpacity(0.12), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Row(children:[const Icon(Icons.check_circle, color: Colors.green, size:20), const SizedBox(width:8), Text('Правильный ответ: ${q.options[q.correctIndex]}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green))]),
            const SizedBox(height:8),
            Text('💡 ${q.hint}', style: Theme.of(context).textTheme.bodySmall),
            if(q.topic.isNotEmpty) Padding(padding: const EdgeInsets.only(top:6), child: Text('Тема: ${q.topic}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey))),
          ])))),
        ]))),
        Padding(padding: const EdgeInsets.all(12), child: Row(children:[
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: idx>0 ? ()=>setState(()=>idx--):null),
          Expanded(child: FilledButton.icon(onPressed: _removeCurrent, icon: const Icon(Icons.check), label: const Text('Выучил'))),
          const SizedBox(width:8),
          Expanded(child: OutlinedButton.icon(onPressed: ()=>setState(()=> idx<qs.length-1 ? idx++ : idx=0), icon: const Icon(Icons.skip_next), label: const Text('Далее'))),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: idx<qs.length-1 ? ()=>setState(()=>idx++):null),
        ])),
      ]),
    );
  }
}
