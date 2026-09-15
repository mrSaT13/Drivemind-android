import 'package:flutter/material.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/question.dart';
import '../exam/widgets/question_card.dart';

class ThemesScreen extends StatefulWidget { const ThemesScreen({super.key}); @override State<ThemesScreen> createState()=>_T(); }
class _T extends State<ThemesScreen> {
  Map<String, List<Question>> grouped = {};
  String? sel;
  int qIdx = 0;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async {
    final all = await StorageService.loadQuestions();
    grouped = {}; for(final q in all){ grouped.putIfAbsent(q.topic, ()=>[]).add(q); }
    setState(()=> sel = grouped.keys.first);
  }
  void _selectTopic(String k) => setState((){sel=k; qIdx=0;});
  @override Widget build(BuildContext context){
    if(grouped.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final list = grouped[sel]!;
    return Scaffold(
      appBar: AppBar(title: const Text('По темам')),
      body: Column(children: [
        SizedBox(height: 44, child: ListView(children: grouped.keys.map((k)=> Padding(padding: const EdgeInsets.symmetric(horizontal:4), child: ChoiceChip(label: Text(k), selected: sel==k, onSelected: (_)=>_selectTopic(k)))).toList(), scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:12))),
        Padding(padding: const EdgeInsets.symmetric(horizontal:16, vertical: 8), child: Row(children:[ Expanded(child: Text('${sel!} • ${qIdx+1}/${list.length}', style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis)), IconButton(icon: const Icon(Icons.chevron_left), onPressed: qIdx>0 ? ()=>setState(()=>qIdx--):null), IconButton(icon: const Icon(Icons.chevron_right), onPressed: qIdx<list.length-1 ? ()=>setState(()=>qIdx++):null)])),
        LinearProgressIndicator(value: (qIdx+1)/list.length),
        Expanded(child: QuestionCard(key: ValueKey(list[qIdx].id), q: list[qIdx])),
      ]),
    );
  }
}
