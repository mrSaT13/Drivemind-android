import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';
import '../../data/models/question.dart';
import '../exam/widgets/question_card.dart';

class FavoritesScreen extends ConsumerStatefulWidget { const FavoritesScreen({super.key}); @override ConsumerState<FavoritesScreen> createState()=>_F(); }
class _F extends ConsumerState<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _t;
  List<Question> all = []; int idx=0;
  @override void initState(){ super.initState(); _t = TabController(length:2, vsync:this); _t.addListener(()=>setState(()=>idx=0)); _load(); }
  Future<void> _load() async { all = await StorageService.loadQuestions(); setState((){}); }
  @override Widget build(BuildContext context){
    final p = ref.watch(profileProvider);
    final ids = _t.index==0 ? p.favorites : p.hardQuestions;
    final list = all.where((e)=>ids.contains(e.id)).toList();
    if(list.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Избранное'), bottom: TabBar(controller: _t, tabs: const [Tab(text:'Избранное ⭐'), Tab(text:'Сложное 🔥')])),
        body: const Center(child: Text('Пусто. Отметьте вопрос в карточке.')),
      );
    }
    if(idx>=list.length) idx=0;
    final q=list[idx];
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное'), bottom: TabBar(controller: _t, tabs: const [Tab(text:'Избранное ⭐'), Tab(text:'Сложное 🔥')])),
      body: Column(children:[
        Padding(padding: const EdgeInsets.all(12), child: Row(children:[ Text('${_t.index==0?"Избранное":"Сложное"} ${idx+1}/${list.length}', style: Theme.of(context).textTheme.titleSmall), const Spacer(), IconButton(icon: const Icon(Icons.chevron_left), onPressed: idx>0 ? ()=>setState(()=>idx--):null), IconButton(icon: const Icon(Icons.chevron_right), onPressed: idx<list.length-1 ? ()=>setState(()=>idx++):null)])),
        LinearProgressIndicator(value: (idx+1)/list.length),
        Expanded(child: QuestionCard(key: ValueKey(q.id), q: q)),
      ]),
    );
  }
}
