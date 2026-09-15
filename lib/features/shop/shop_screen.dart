import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/storage/profile_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final p = ref.watch(profileProvider);
    final n = ref.read(profileProvider.notifier);
    final themeNotifier = ref.read(themeProvider.notifier);
    final avatars = ['first_steps','exam_master','streak_7','hundred_club','night_owl','signs_expert','crossroad_king','trainer_pro'];
    return Scaffold(
      appBar: AppBar(title: const Text('Магазин'), actions: [Padding(padding: const EdgeInsets.all(12), child: Chip(label: Text('${p.coins} 🪙'))) ]),
      body: ListView(children: [
        const Padding(padding: EdgeInsets.all(12), child: Text('Темы (премиум)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        Wrap(spacing: 10, runSpacing: 10, children: PresetTheme.values.map((t){
          final preset = presets[t]!;
          final unlocked = isThemeUnlocked(t, p.ownedThemes, p.achievements);
          final owned = p.ownedThemes.contains(t.name) || unlocked;
          final active = ref.watch(themeProvider).preset == t;
          final cost = themeCosts[t];
          final ach = themeAchievements[t];
          Widget action;
          if(owned || unlocked){
            action = TextButton(onPressed: active?null:()=>themeNotifier.setPreset(t), child: Text(active?'Активна':'Включить'));
          } else if(ach!=null){
            action = Column(children:[ const Icon(Icons.lock, size:16), Text(ach, style: const TextStyle(fontSize:9)), FilledButton(onPressed: cost!=null && p.coins>=cost ? ()=>n.buyTheme(t.name, cost):null, child: Text('${cost??""} 🪙'))]);
          } else {
            action = FilledButton(onPressed: cost!=null && p.coins>=cost ? ()=>n.buyTheme(t.name, cost):null, child: Text('${cost??100} 🪙'));
          }
          return SizedBox(width: 150, child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
            Container(height: 40, decoration: BoxDecoration(gradient: LinearGradient(colors: [preset.accent, preset.bg]), borderRadius: BorderRadius.circular(8)), child: !unlocked && ach!=null ? const Center(child: Icon(Icons.lock, color: Colors.white70)) : null),
            const SizedBox(height: 6),
            Text(preset.name),
            action,
          ]))));
        }).toList()),
        const Padding(padding: EdgeInsets.all(12), child: Text('Аватары', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: avatars.length, itemBuilder: (_, i){
          final a = avatars[i];
          final owned = p.ownedAvatars.contains(a) || p.achievements.contains(a);
          return Card(child: InkWell(onTap: owned ? ()=>n.selectAvatar('asset:$a.png') : p.coins>=50?()=>n.buyAvatar(a, 50):null,
            child: Stack(children:[ Image.asset('assets/images/$a.png', height: 60, errorBuilder:(_,__,___)=>const Icon(Icons.person)), if(!owned) const Positioned(top:2,right:2,child:Icon(Icons.lock, size:16)) ])),
          );
        }),
      ]),
    );
  }
}
