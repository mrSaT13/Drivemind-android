import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/profile_provider.dart';
class AchievementsGrid extends ConsumerWidget {
  const AchievementsGrid({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final p = ref.watch(profileProvider);
    final ach = ['first_steps','exam_master','streak_7','hundred_club','night_owl','signs_expert'];
    return GridView.builder(shrinkWrap:true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3, crossAxisSpacing:12, mainAxisSpacing:12), itemCount: ach.length, itemBuilder: (_,i){
      final key = ach[i];
      final unlocked = p.achievements.contains(key);
      return Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(alignment: Alignment.center, children:[
          Image.asset('assets/images/$key.png', height:48, errorBuilder: (_,__,___)=> const Icon(Icons.emoji_events)),
          if(!unlocked) const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.all(Radius.circular(8))))),
          if(!unlocked) const Icon(Icons.lock, color: Colors.white, size: 28),
        ]),
        const SizedBox(height:4),
        Text(key, style: const TextStyle(fontSize:10), textAlign: TextAlign.center),
        Text(unlocked ? 'Открыто' : 'Закрыто', style: TextStyle(fontSize:8, color: unlocked ? Colors.green : Colors.grey)),
      ]));
    });
  }
}
