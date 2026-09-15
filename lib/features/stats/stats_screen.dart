import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/storage/profile_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final p = ref.watch(profileProvider);
    final spots = <FlSpot>[];
    for(int i=0;i<p.history.length;i++){
      final h=p.history[i];
      spots.add(FlSpot(i.toDouble(), h.total==0?0:h.correct/h.total*100));
    }
    return Scaffold(appBar: AppBar(title: const Text('Статистика')), body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Точность по сессиям', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(height: 180, child: spots.isEmpty ? const Center(child: Text('Нет данных')) : LineChart(LineChartData(
          lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Theme.of(context).colorScheme.primary, barWidth: 3, dotData: FlDotData(show: false))],
          titlesData: FlTitlesData(show: false), gridData: FlGridData(show: false), borderData: FlBorderData(show: false),
        ))),
      ]))),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Streak карта (35 дней)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _Heatmap(history: p.history),
      ]))),
      const SizedBox(height: 16),
      Card(child: ListTile(title: Text('Всего: ${p.totalAnswered}'), subtitle: Text('Верно: ${p.correctAnswers} (${p.accuracy.toStringAsFixed(1)}%)'))),
      Card(child: Column(children: p.mistakesByTheme.entries.map((e)=>ListTile(title: Text(e.key), trailing: Text('${e.value} ош.'))).toList())),
    ]));
  }
}

class _Heatmap extends StatelessWidget {
  final List<dynamic> history;
  const _Heatmap({required this.history});
  @override Widget build(BuildContext context){
    final days = List.generate(35, (i){ final d = DateTime.now().subtract(Duration(days: 34-i)); final has = history.any((h)=> h.date.year==d.year && h.date.month==d.month && h.date.day==d.day); return has; });
    return Wrap(spacing: 4, runSpacing: 4, children: days.map((on)=> Container(width: 14, height: 14, decoration: BoxDecoration(color: on?Colors.green:Colors.white12, borderRadius: BorderRadius.circular(3)))).toList());
  }
}
