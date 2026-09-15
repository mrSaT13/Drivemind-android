import 'package:flutter/material.dart';
import '../../../data/models/question.dart';
import '../../../core/tts/tts_service.dart';
import '../../../core/storage/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionCard extends ConsumerStatefulWidget {
  final Question q;
  final Function(int)? onSelect;
  final bool showActions;
  final void Function(bool correct)? onResult;
  const QuestionCard({super.key, required this.q, this.onSelect, this.showActions = true, this.onResult});
  @override ConsumerState<QuestionCard> createState() => _Q();
}
class _Q extends ConsumerState<QuestionCard> {
  int? sel;
  @override Widget build(BuildContext context){
    final fav = ref.watch(profileProvider).favorites.contains(widget.q.id);
    final hard = ref.watch(profileProvider).hardQuestions.contains(widget.q.id);
    final hasNote = ref.watch(profileProvider).notes.containsKey(widget.q.id);
    final noteCtrl = TextEditingController(text: ref.watch(profileProvider).notes[widget.q.id] ?? '');
    return ListView(padding: const EdgeInsets.all(16), children: [
      if(widget.q.image!=null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/${widget.q.image}', errorBuilder: (_,__,___)=> const SizedBox(), height: 180, fit: BoxFit.cover)),
      const SizedBox(height:12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: Text(widget.q.text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), IconButton(icon: const Icon(Icons.volume_up), onPressed: ()=>ttsService.speak(widget.q.text))]))),
      if(widget.showActions) Padding(padding: const EdgeInsets.only(top:8), child: Row(children: [
        IconButton(icon: Icon(fav?Icons.star:Icons.star_border, color: fav?Colors.amber:null), onPressed: ()=>ref.read(profileProvider.notifier).toggleFavorite(widget.q.id)),
        IconButton(icon: Icon(hard?Icons.local_fire_department:Icons.local_fire_department_outlined, color: hard?Colors.orange:null), onPressed: ()=>ref.read(profileProvider.notifier).toggleHard(widget.q.id)),
        IconButton(icon: Icon(hasNote?Icons.note:Icons.note_add, color: hasNote?Colors.cyan:null), onPressed: ()=> showDialog(context: context, builder: (_)=> AlertDialog(title: const Text('Заметка'), content: TextField(controller: noteCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Моя подсказка...')), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: (){ ref.read(profileProvider.notifier).setNote(widget.q.id, noteCtrl.text.trim()); Navigator.pop(context); }, child: const Text('Сохранить'))]))),
        if(hasNote) Expanded(child: Text(ref.watch(profileProvider).notes[widget.q.id]!, maxLines:2, overflow:TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.cyan))),
      ])),

      ...List.generate(widget.q.options.length, (i){
        final isCorrect = sel!=null && i==widget.q.correctIndex;
        final isWrong = sel==i && i!=widget.q.correctIndex;
        return Card(
          color: isCorrect ? Colors.green.withOpacity(0.15) : isWrong ? Colors.red.withOpacity(0.15) : null,
          child: RadioListTile<int>(value: i, groupValue: sel, title: Text(widget.q.options[i]), onChanged: sel==null ? (v){ setState(()=>sel=v); final ok = v==widget.q.correctIndex; if(widget.onResult!=null) widget.onResult!(ok); if(widget.onSelect!=null) Future.delayed(const Duration(milliseconds:600), ()=>widget.onSelect!(v!)); } : null),
        );
      }),
      if(sel!=null) Card(color: Theme.of(context).colorScheme.surfaceVariant, child: Padding(padding: const EdgeInsets.all(12), child: Text('💡 ${widget.q.hint}', style: Theme.of(context).textTheme.bodySmall))),
    ]);
  }
}
