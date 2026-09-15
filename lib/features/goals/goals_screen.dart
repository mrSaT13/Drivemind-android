import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/storage/profile_provider.dart';
import '../../core/llm/llm_service.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final p = ref.watch(profileProvider);
    final n = ref.read(profileProvider.notifier);
    final days = p.goalDate==null ? 0 : p.goalDate!.difference(DateTime.now()).inDays;
    final total = p.goalDaily * 14;
    final prog = total==0 ? 0.0 : (p.totalAnswered/total).clamp(0,1).toDouble();
    return Scaffold(appBar: AppBar(title: const Text('Цель')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text('План подготовки', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if(p.goalDate!=null) ...[
            Text('Сдать к ${DateFormat('d MMM y').format(p.goalDate!)}', style: Theme.of(context).textTheme.titleSmall),
            Text('Осталось дней: ${days<0?0:days}'),
            Text('Ежедневно: ${p.goalDaily} вопр.'),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: prog, minHeight: 8, borderRadius: BorderRadius.circular(8)),
            Text('Решено: ${p.totalAnswered} из $total'),
          ] else const Text('Цель не задана — нажми кнопку ниже'),
        ]))),
        const SizedBox(height: 12),
        FilledButton(onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days:14)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days:365)));
          if(d!=null) n.setGoal(d, 20);
        }, child: const Text('Поставить цель: сдать через 14 дней')),
        const SizedBox(height:8),
        FilledButton.icon(icon: const Icon(Icons.smart_toy), label: const Text('Подобрать цель с ИИ'), onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ИИ подбирает цель...')));
          final p2=ref.read(profileProvider);
          final res=await LlmService.suggestGoals(p2.mistakesByTheme);
          // try parse
          try{
            final m=RegExp(r'"days"\s*:\s*(\d+)').firstMatch(res);
            final d2=RegExp(r'"daily"\s*:\s*(\d+)').firstMatch(res);
            if(m!=null && d2!=null){
              final days=int.parse(m.group(1)!);
              final daily=int.parse(d2.group(1)!);
              final date=DateTime.now().add(Duration(days: days));
              await n.setGoal(date, daily);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ИИ: $daily вопр/день, сдать через $days дней\n${res.substring(0, (res.length>200?200:res.length))}')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res), duration: const Duration(seconds:5)));
            }
          } catch(_){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
          }
        }),
        TextButton(onPressed: ()=> n.setGoal(null, 20), child: const Text('Сбросить цель')),
        const SizedBox(height:8),
        OutlinedButton.icon(icon: const Icon(Icons.chat), label: const Text('Чат с ИИ-инструктором'), onPressed: ()=> Navigator.pushNamed(context, '/instructor')),
      ]),
    );
  }
}
