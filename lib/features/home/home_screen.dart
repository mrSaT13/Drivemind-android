import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/tts_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';
import '../tickets/tickets_screen.dart';
import '../exam/exam_screen.dart';
import '../mistakes/mistakes_screen.dart';
import '../profile/profile_screen.dart';
import '../themes/themes_screen.dart';
import '../marathon/marathon_screen.dart';
import '../kids/kids_screen.dart';
import '../trainer/trainer_options.dart';
import '../favorites/favorites_screen.dart';
import '../speed/speed_screen.dart';
import '../shop/shop_screen.dart';
import '../achievements/achievements_screen.dart';
import '../stats/stats_screen.dart';
import '../search/search_screen.dart';
import 'widgets/stat_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int idx = 0;
  final pages = const [Dashboard(), TicketsScreen(), ExamScreen(), MistakesScreen(), ProfileScreen()];
  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    return gradientBackground(
      Scaffold(
        body: pages[idx],
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (v) => setState(() => idx = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Главная'),
            NavigationDestination(icon: Icon(Icons.confirmation_number), label: 'Билеты'),
            NavigationDestination(icon: Icon(Icons.timer_rounded), label: 'Экзамен'),
            NavigationDestination(icon: Icon(Icons.error_outline), label: 'Ошибки'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Профиль'),
          ],
        ),
      ),
      context,
    );
  }
}

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          CircleAvatar(radius: 28, backgroundImage: p.avatarPath != null ? (p.avatarPath!.startsWith('asset:') ? AssetImage('assets/images/${p.avatarPath!.replaceFirst('asset:', '')}') : FileImage(File(p.avatarPath!)) as ImageProvider) : null, child: const Icon(Icons.person)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DriveMind', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text('ПДД 2025 • streak ${p.streak} 🔥', style: Theme.of(context).textTheme.bodySmall),
          ]),
          const Spacer(),
          Chip(label: Text('${p.coins} 🪙')),
          IconButton(onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.settings_rounded)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: StatCard(title: 'Отвечено', value: '${p.totalAnswered}', icon: Icons.check_circle)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(title: 'Точность', value: '${p.accuracy.toStringAsFixed(1)}%', icon: Icons.show_chart)),
        ]),
        const SizedBox(height: 12),
        LinearPercentIndicator(percent: (p.accuracy / 100).clamp(0, 1).toDouble(), lineHeight: 8, barRadius: const Radius.circular(8)),
        const SizedBox(height: 16),
        _QuestCard(),
        const SizedBox(height: 16),
        _MenuGrid(),
        const SizedBox(height: 16),
        Card(child: ListTile(leading: const Icon(Icons.lightbulb, color: Colors.amber), title: const Text('Факт дня'), subtitle: Text(_fact), trailing: IconButton(icon: const Icon(Icons.volume_up), tooltip: 'Озвучить', onPressed: () => ttsService.speak(_fact)))),
      ]),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  @override Widget build(BuildContext context, WidgetRef ref){
    final p = ref.watch(profileProvider);
    final prog = p.questProgress / StorageService.questTarget;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.flag), const SizedBox(width:8), Text('Дневной квест', style: Theme.of(context).textTheme.titleMedium), const Spacer(), Text('${p.questProgress}/${StorageService.questTarget}')]),
      const SizedBox(height: 8),
      LinearPercentIndicator(percent: prog.clamp(0,1).toDouble(), lineHeight: 8, barRadius: const Radius.circular(8), progressColor: Colors.orange),
    ])));
  }
}

class _MenuGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Билеты', Icons.list_alt, '/tickets', Colors.indigo),
      ('Экзамен ГАИ', Icons.timer, '/exam', Colors.redAccent),
      ('Экзамен A/B', Icons.shuffle, '/examAB', Colors.deepOrange),
      ('По темам', Icons.category, '/themes', Colors.teal),
      ('Марафон 800', Icons.all_inclusive, '/marathon', Colors.orange),
      ('Тренажёр', Icons.fitness_center, '/trainer', Colors.green),
      ('Speed ⚡', Icons.speed, '/speed', Colors.purple),
      ('Детский', Icons.child_care, '/kids', Colors.pink),
      ('Избранное', Icons.star, '/favorites', Colors.amber),
      ('Достижения', Icons.emoji_events, '/achievements', Colors.blue),
      ('Статистика', Icons.bar_chart, '/stats', Colors.cyan),
      ('Знаки', Icons.traffic, '/signs', Colors.red),
      ('Карта ошибок', Icons.map, '/errormap', Colors.deepPurple),
      ('Игры', Icons.sports_esports, '/games', Colors.teal),
      ('Цели', Icons.flag, '/goals', Colors.lightBlue),
      ('Повторения', Icons.repeat, '/spaced', Colors.indigo),
      ('Бэкап', Icons.cloud_download, '/backup', Colors.grey),
      ('Магазин', Icons.store, '/shop', Colors.brown),
      ('ИИ-Инструктор', Icons.smart_toy, '/instructor', Colors.deepPurple),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.95, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final (t, ic, route, c) = items[i];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pushNamed(context, route),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(backgroundColor: c.withOpacity(0.15), child: Icon(ic, color: c)),
              const SizedBox(height: 8),
              Text(t, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ),
        );
      },
    );
  }
}

// --- Факт дня: ротируется каждый день (45 фактов, повтор ~1.5 месяца) ---
const List<String> _facts = [
  'В 1920 году в Москве появился первый светофор — ручной, с двумя цветами.',
  'Первый автомобиль в России появился в 1896 году и ехал со скоростью 20 км/ч.',
  'Ремень безопасности спасает жизнь в 75% аварий — пристёгивайся всегда!',
  'Стоп-линия придумана, чтобы пешеходы были в безопасности — не заезжай за неё.',
  'Жёлтый сигнал светофора горит всего 3 секунды — это время приготовиться.',
  'Пешеходный переход «зебра» назван так из-за чёрно-белых полос, как у зебры.',
  'В Японии есть светофоры с синим вместо зелёного — из-за особенностей языка.',
  'Самый длинный тормозной путь — у грузовиков: до 40 метров на 60 км/ч!',
  'Фары ближнего света делают машину заметной даже днём — включай всегда.',
  'Знак «Уступи дорогу» — единственный перевёрнутый треугольник среди знаков.',
  'Круговое движение безопаснее перекрёстка: аварий на 75% меньше.',
  'Первые правила движения в России издал Пётр I — для извозчиков.',
  'Знак STOP — единственный восьмиугольный знак в мире.',
  'Подушка безопасности раскрывается за 0,03 секунды — быстрее моргания.',
  'Детское кресло снижает риск гибели ребёнка при ДТП на 70%.',
  'Среднее время реакции водителя — 1 секунда. На 60 км/ч это 17 метров вслепую.',
  'Первый светофор в Лондоне в 1868 году взорвался и ранил полицейского.',
  'Знак «Главная дорога» — единственный ромб среди всех знаков.',
  'На льду тормозной путь в 10 раз длиннее, чем на сухом асфальте.',
  'Мигающий зелёный — сигнал «не ускоряйся», скоро жёлтый.',
  'С 2017 года в России приоритет на круге у тех, кто уже на кругу.',
  'Первая разметка появилась в 1911 году в США — центральная линия.',
  'В Швеции до 1967 года ездили по левой стороне, затем за один день перешли на правую.',
  'Самый массовый автомобиль в России — LADA, более 30 млн выпущено.',
  'ABS сокращает тормозной путь на мокрой дороге до 15%, но не на льду.',
  'За час в городе водитель принимает до 200 решений — концентрация критична.',
  'Знак «Жилая зона» ограничивает скорость до 20 км/ч — как во дворе.',
  'В Финляндии штраф привязан к доходу — рекорд 170 000 евро за превышение.',
  'Красный цвет для запрета выбран из-за лучшей видимости в тумане и ночью.',
  'Пешеход на переходе имеет приоритет, даже если светофор сломан — уступай.',
  'Пристегнутый задний пассажир без ремня опасен так же, как передний.',
  'Дневные ходовые огни экономят ~0,2 л топлива по сравнению с ближним светом.',
  'Знак «Дети» ставят за 50-100 м в городе и 150-300 м за городом.',
  'Первый экзамен на права в России сдавали в 1900 году в Санкт-Петербурге.',
  'В Китае светофоры показывают обратный отсчёт для каждого цвета.',
  '«Кирпич» официально называется «Въезд запрещён» (знак 3.1).',
  'Форд Model T (1908) — первый массовый авто: 15 млн экземпляров.',
  'Человечек на пешеходном светофоре (Ampelmännchen) появился в ГДР в 1961 году.',
  'На автобане в Германии на части участков нет лимита, но рекомендовано 130 км/ч.',
  'Знак «Обгон запрещён» действует до перекрёстка или знака 3.21.',
  'Тормозной путь на мокром асфальте длиннее на 30-40%, чем на сухом.',
  'В 1993 году в России ввели современные ПДД, действующие с изменениями до 2025.',
  'Уступить дорогу — значит не создавать помех, а не обязательно останавливаться.',
  'Самый длинный лимузин — 30,5 метра, с бассейном и вертолётной площадкой.',
  'В Норвегии за превышение на 20 км/ч штраф может превысить 1000 евро.',
];
String get _fact {
  final day = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
  return _facts[day % _facts.length];
}
