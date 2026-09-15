import 'package:flutter/material.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/question.dart';
import '../exam/widgets/question_card.dart';

class SearchScreen extends StatefulWidget { const SearchScreen({super.key}); @override State<SearchScreen> createState()=>_S(); }
class _S extends State<SearchScreen> {
  List<Question> all=[]; List<Question> res=[]; final c=TextEditingController();
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async { all = await StorageService.loadQuestions(); setState((){}); }
  void _q(String t){ setState(()=> res = all.where((e)=> e.text.toLowerCase().contains(t.toLowerCase()) || e.ticket.toString()==t).toList()); }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: TextField(controller: c, onChanged: _q, decoration: const InputDecoration(hintText: 'Поиск по тексту или № билета', border: InputBorder.none), style: const TextStyle(fontSize: 16))),
      body: res.isEmpty ? const Center(child: Text('Введите запрос')) : ListView.builder(itemCount: res.length, itemBuilder: (_,i){
        final q=res[i];
        return Card(child: ListTile(
          title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('Билет ${q.ticket} • ${q.topic} • ${q.options[q.correctIndex]}'),
          trailing: q.image!=null ? Image.asset('assets/images/${q.image}', width: 56, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.help)) : null,
          onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> Scaffold(appBar: AppBar(title: Text('Вопрос ${q.id}')), body: QuestionCard(q: q)))),
        ));
      }));
  }
}
