import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/profile_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../core/llm/llm_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final s = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(children: [
        const ListTile(title: Text('ТЕМЫ', style: TextStyle(fontWeight: FontWeight.w800))),
        Wrap(spacing:8, children: PresetTheme.values.map((pt){
          final preset = presets[pt]!;
          final prof = ref.watch(profileProvider);
          final unlocked = isThemeUnlocked(pt, prof.ownedThemes, prof.achievements);
          final cost = themeCosts[pt];
          final ach = themeAchievements[pt];
          return ChoiceChip(
            label: Text(preset.name + (unlocked ? '' : (cost!=null ? ' 🔒 $cost' : ' 🔒'))),
            selected: s.preset==pt,
            avatar: CircleAvatar(backgroundColor: preset.accent, radius:8, child: unlocked ? null : const Icon(Icons.lock, size:12, color: Colors.white)),
            onSelected: unlocked ? (_)=> ref.read(themeProvider.notifier).setPreset(pt) : (_){
              if(ach!=null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Требуется достижение: $ach или ${cost??""} 🪙 в магазине')));
              else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Тема заблокирована — купите за ${cost??""} 🪙 в магазине')));
            },
          );
        }).toList()),
        SwitchListTile(title: const Text('Градиентный фон'), value: s.gradient, onChanged: (v)=> ref.read(themeProvider.notifier).setGradient(v)),
        SwitchListTile(title: const Text('Динамические цвета Android 12+'), subtitle: const Text('Material You'), value: s.dynamicColor, onChanged: (v)=> ref.read(themeProvider.notifier).setDynamic(v)),
        SegmentedButton<ThemeMode>(segments: const [ButtonSegment(value: ThemeMode.light, label: Text('Светлая'), icon: Icon(Icons.wb_sunny)), ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная'), icon: Icon(Icons.dark_mode)), ButtonSegment(value: ThemeMode.system, label: Text('Авто'), icon: Icon(Icons.brightness_auto))], selected: {s.mode}, onSelectionChanged: (v)=> ref.read(themeProvider.notifier).setMode(v.first)),
        SwitchListTile(title: const Text('Авто по времени суток (07:00–19:00 светлая)'), value: s.autoTime, onChanged: (v)=> ref.read(themeProvider.notifier).setAutoTime(v)),
        const Divider(),
        const ListTile(title: Text('ОЗВУЧКА', style: TextStyle(fontWeight: FontWeight.w800))),
        _TtsSettings(),
        const Divider(),
        _ReminderTile(),
        const Divider(),
        const ListTile(title: Text('ИИ-ИНСТРУКТОР (LLM)', style: TextStyle(fontWeight: FontWeight.w800))),
        const _LlmSettings(),
        ListTile(leading: const Icon(Icons.smart_toy), title: const Text('Открыть чат с инструктором'), trailing: const Icon(Icons.chevron_right), onTap: ()=> Navigator.pushNamed(context, '/instructor')),
        const Divider(),
        ListTile(title: const Text('Сбросить прогресс'), trailing: const Icon(Icons.delete_forever, color: Colors.red), onTap: () async { await StorageService.box.clear(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Прогресс сброшен'))); }),
      ]),
    );
  }
}

class _LlmSettings extends StatefulWidget { const _LlmSettings(); @override State<_LlmSettings> createState()=>_L(); }
class _L extends State<_LlmSettings> {
  LlmConfig? cfg; List<String> models=[]; bool loading=false;
  final tokenCtrl=TextEditingController(); final baseCtrl=TextEditingController(); final modelCtrl=TextEditingController();
  LlmProvider provider=LlmProvider.ollamaCloud;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { cfg=await LlmService.loadConfig(); provider=cfg!.provider; tokenCtrl.text=cfg!.token; baseCtrl.text=cfg!.baseUrl; modelCtrl.text=cfg!.model; setState((){}); _fetch(); }
  Future<void> _save() async { final c=LlmConfig(provider:provider, baseUrl:baseCtrl.text.trim(), token:tokenCtrl.text.trim(), model:modelCtrl.text.trim()); await LlmService.saveConfig(c); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сохранено'))); setState(()=>cfg=c); }
  Future<void> _fetch() async { setState(()=>loading=true); final c=LlmConfig(provider:provider, baseUrl:baseCtrl.text.trim(), token:tokenCtrl.text.trim(), model:modelCtrl.text.trim()); models=await LlmService.fetchModels(c); setState(()=>loading=false); }
  @override Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    DropdownButton<LlmProvider>(value: provider, isExpanded:true, items: const [DropdownMenuItem(value:LlmProvider.ollamaCloud, child:Text('Ollama Cloud')), DropdownMenuItem(value:LlmProvider.lmStudio, child:Text('LM Studio (local)'))], onChanged: (v)=>setState(()=>provider=v!)),
    TextField(controller: baseCtrl, decoration: InputDecoration(labelText: provider==LlmProvider.ollamaCloud ? 'Base URL (https://api.ollama.com)' : 'Base URL (http://10.0.2.2:1234)', hintText: 'https://api.ollama.com')),
    TextField(controller: tokenCtrl, decoration: const InputDecoration(labelText: 'API Token (Ollama Cloud)', hintText: 'ollama_...'), obscureText: true),
    Row(children:[
      Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Модель', hintText: 'qwen3:8b / llama3'))),
      IconButton(icon: loading? const SizedBox(width:16,height:16, child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.refresh), onPressed: _fetch, tooltip: 'Подгрузить модели'),
    ]),
    if(models.isNotEmpty) Wrap(spacing:6, children: models.take(8).map((m)=> ChoiceChip(label: Text(m, style: const TextStyle(fontSize:11)), selected: modelCtrl.text==m, onSelected: (_)=>setState(()=>modelCtrl.text=m))).toList()),
    const SizedBox(height:8),
    Row(children:[
      FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Сохранить')),
      const SizedBox(width:8),
      OutlinedButton(onPressed: () async {
        final c=LlmConfig(provider:provider, baseUrl:baseCtrl.text.trim(), token:tokenCtrl.text.trim(), model:modelCtrl.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Проверяю...')));
        final r=await LlmService.chat(c, [{'role':'user','content':'Привет! Ты инструктор ПДД? Ответь одним словом.'}]);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r), duration: const Duration(seconds:4)));
      }, child: const Text('Тест')),
    ]),
    const SizedBox(height:8),
    const Text('Ollama Cloud: зарегистрируйтесь на ollama.com, создайте API ключ, выберите модель (qwen3:8b, llama3.1 и тд). LM Studio: запустите LM Studio → Local Server → скопируйте URL (обычно http://192.168.x.x:1234 для устройства). На эмуляторе используйте 10.0.2.2', style: TextStyle(fontSize:11, color: Colors.grey)),
  ]));
}

class _TtsSettings extends StatefulWidget {
  @override State<_TtsSettings> createState()=>_T();
}
class _T extends State<_TtsSettings> {
  List<String> langs=[]; List<dynamic> voices=[];
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async { langs = await ttsService.languages(); voices = await ttsService.voices(); setState((){}); }
  @override Widget build(BuildContext context)=> Column(children: [
    ListTile(title: const Text('Язык'), trailing: DropdownButton<String>(value: ttsService.lang, items: langs.map((l)=>DropdownMenuItem(value: l, child: Text(l))).toList(), onChanged: (v)=> ttsService.setLang(v!))),
    ListTile(title: Text('Скорость ${(ttsService.rate*100).toInt()}%'), subtitle: Slider(value: ttsService.rate, min: 0.2, max: 1.0, onChanged: (v)=> setState(()=> ttsService.setRate(v)))),
    ListTile(title: Text('Тон ${(ttsService.pitch*100).toInt()}%'), subtitle: Slider(value: ttsService.pitch, min: 0.5, max: 2.0, onChanged: (v)=> setState(()=> ttsService.setPitch(v)))),
    if(voices.isNotEmpty) ListTile(title: const Text('Голос'), trailing: DropdownButton<String>(value: ttsService.voice, items: [const DropdownMenuItem(value: null, child: Text('По умолчанию')), ...voices.map((v){ final name=(v['name']??'').toString(); return DropdownMenuItem(value: name, child: Text(name)); })], onChanged: (v)=> setState(()=> ttsService.setVoice(v)))),
    ListTile(title: const Text('Проверить'), trailing: IconButton(icon: const Icon(Icons.play_arrow), onPressed: ()=> ttsService.speak('Проверка голоса DriveMind'))),
  ]);
}

class _ReminderTile extends StatefulWidget {
  @override State<_ReminderTile> createState()=>_R();
}
class _R extends State<_ReminderTile> {
  bool v = true;
  @override void initState(){ super.initState(); StorageService.getDailyReminder().then((r)=> setState(()=>v=r)); }
  @override Widget build(BuildContext context)=> SwitchListTile(title: const Text('Ежедневные напоминания 19:00'), value: v, onChanged: (nv) async { setState(()=>v=nv); await StorageService.setDailyReminder(nv); if(nv) await NotificationService.scheduleDaily(); else await NotificationService.cancel(); });
}
