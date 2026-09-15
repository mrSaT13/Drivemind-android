import 'package:flutter/material.dart';
import 'trainer_screen.dart';

class TrainerOptions extends StatelessWidget {
  const TrainerOptions({super.key});
  @override Widget build(BuildContext context)=> Scaffold(
    appBar: AppBar(title: const Text('Тренажёр')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      _Tile('Все вопросы', Icons.all_inclusive, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>const TrainerScreen()))),
      _Tile('Только с картинкой', Icons.image, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>const TrainerScreen(onlyImage: true)))),
      _Tile('Без картинки', Icons.text_fields, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>const TrainerScreen(noImage: true)))),
    ]),
  );
}
class _Tile extends StatelessWidget {
  final String t; final IconData i; final VoidCallback on;
  const _Tile(this.t, this.i, this.on);
  @override Widget build(BuildContext context)=> Card(child: ListTile(leading: Icon(i), title: Text(t), trailing: const Icon(Icons.chevron_right), onTap: on));
}
