import 'package:flutter/material.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/question.dart';
import '../exam/widgets/question_card.dart';

class TicketsScreen extends StatefulWidget { const TicketsScreen({super.key}); @override State<TicketsScreen> createState() => _S(); }
class _S extends State<TicketsScreen> {
  List<Question> qs = [];
  int ticket = 1;
  int qIdx = 0;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { qs = await StorageService.loadQuestions(); setState(() {}); }
  void _changeTicket(int t) => setState((){ ticket=t; qIdx=0; });
  @override
  Widget build(BuildContext context) {
    final filtered = qs.where((e) => e.ticket == ticket).toList();
    final hasData = filtered.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Билеты')),
      body: Column(children: [
        SizedBox(height: 48, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: 40, itemBuilder: (_, i) => Padding(padding: const EdgeInsets.all(4), child: ChoiceChip(label: Text('${i+1}'), selected: ticket==i+1, onSelected: (_)=>_changeTicket(i+1))))),
        if(hasData) Padding(padding: const EdgeInsets.symmetric(horizontal:16, vertical: 8), child: Row(children:[ Text('Вопрос ${qIdx+1}/${filtered.length}', style: Theme.of(context).textTheme.titleSmall), const Spacer(), IconButton(icon: const Icon(Icons.chevron_left), onPressed: qIdx>0 ? ()=>setState(()=>qIdx--):null), IconButton(icon: const Icon(Icons.chevron_right), onPressed: qIdx<filtered.length-1 ? ()=>setState(()=>qIdx++):null)])),
        if(hasData) LinearProgressIndicator(value: (qIdx+1)/filtered.length),
        Expanded(child: !hasData ? const Center(child: CircularProgressIndicator()) : QuestionCard(key: ValueKey(filtered[qIdx].id), q: filtered[qIdx])),
      ]),
    );
  }
}
