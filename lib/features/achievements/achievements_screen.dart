import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/storage/profile_provider.dart';

const defs = {
  'first_steps': ['first_steps', 'Первые шаги', 'Ответь на первый вопрос'],
  'exam_master': ['exam_master', 'Мастер экзамена', 'Сдай экзамен с 18+'],
  'streak_7': ['streak_7', 'Неделя подряд', 'Учись 7 дней подряд'],
  'hundred_club': ['hundred_club', 'Клуб 100', 'Ответь на 100 вопросов'],
  'night_owl': ['night_owl', 'Сова', 'Учись ночью'],
  'signs_expert': ['signs_expert', 'Эксперт по знакам', 'Тренажёр знаков'],
  'crossroad_king': ['crossroad_king', 'Король перекрёстков', '0 ошибок в теме'],
  'trainer_pro': ['trainer_pro', 'Про-тренер', 'Марафон 800'],
  'daily_quest': ['daily_quest', 'Ежедневный квест', 'Выполни дневной квест'],
};

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final p = ref.watch(profileProvider);
    return Scaffold(appBar: AppBar(title: const Text('Достижения')), body: GridView.builder(padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: defs.length, itemBuilder: (_, i){
      final key = defs.keys.elementAt(i);
      final d = defs[key]!;
      final unlocked = p.achievements.contains(key);
      return Card(child: InkWell(onTap: unlocked ? ()=> _celebrate(context) : null, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(alignment: Alignment.center, children: [ Image.asset('assets/images/${d[0]}.png', height: 48, errorBuilder:(_,__,___)=>const Icon(Icons.emoji_events)), if(!unlocked) const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.all(Radius.circular(8))))), if(!unlocked) const Icon(Icons.lock, color: Colors.white) ]),
        const SizedBox(height: 4),
        Text(d[1], style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
      ])));
    }));
  }
  void _celebrate(BuildContext context){
    final c = ConfettiController(duration: const Duration(seconds: 1));
    showDialog(context: context, builder: (_)=> Stack(children:[ Center(child: AlertDialog(title: const Text('🏆 Открыто!'), content: const Text('Достижение получено'), actions: [FilledButton(onPressed: ()=>Navigator.pop(context), child: const Text('Ок'))])), Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: c, blastDirectionality: BlastDirectionality.explosive))]));
    c.play();
  }
}
