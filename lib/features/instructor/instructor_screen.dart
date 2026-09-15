import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/llm/llm_service.dart';
import '../../core/storage/profile_provider.dart';

class InstructorScreen extends ConsumerStatefulWidget {
  const InstructorScreen({super.key});
  @override
  ConsumerState<InstructorScreen> createState() => _IState();
}

class _IState extends ConsumerState<InstructorScreen> {
  String analysis = '';
  bool loading = false;
  final chatCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  List<Map<String, String>> chat = [
    {'role': 'system', 'content': 'Ты — инструктор ПДД DriveMind, отвечаешь кратко, дружелюбно, по-русски.'}
  ];

  // LLM настройки (показываем статус)
  LlmConfig? llmConfig;
  List<String> availableModels = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final c = await LlmService.loadConfig();
    final models = c.isConfigured ? await LlmService.fetchModels(c) : <String>[];
    if (mounted) setState(() { llmConfig = c; availableModels = models; });
  }

  Future<void> _analyze() async {
    setState(() => loading = true);
    final p = ref.read(profileProvider);
    final goal = p.goalDate != null ? 'сдать к ${DateFormat('d MMM y', 'ru').format(p.goalDate!)}' : 'без цели';
    final res = await LlmService.analyzeErrors(p.mistakesByTheme, p.totalAnswered, p.correctAnswers, goal);
    if (!mounted) return;
    setState(() { analysis = res; loading = false; });
  }

  Future<void> _suggestGoal() async {
    setState(() => loading = true);
    final p = ref.read(profileProvider);
    final res = await LlmService.suggestGoals(p.mistakesByTheme);
    if (!mounted) return;
    setState(() => loading = false);

    // Парсим JSON из ответа
    try {
      final m = RegExp(r'\{[^}]+\}').firstMatch(res);
      if (m != null) {
        final jsonStr = m.group(0)!;
        final days = int.tryParse(RegExp(r'"days"\s*:\s*(\d+)').firstMatch(jsonStr)?.group(1) ?? '');
        final daily = int.tryParse(RegExp(r'"daily"\s*:\s*(\d+)').firstMatch(jsonStr)?.group(1) ?? '');
        if (days != null && daily != null) {
          final date = DateTime.now().add(Duration(days: days));
          await ref.read(profileProvider.notifier).setGoal(date, daily);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Цель поставлена: $daily вопр/день, сдать через $days дней'), backgroundColor: Colors.green.shade700),
          );
        }
      }
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res, maxLines: 4, overflow: TextOverflow.ellipsis), duration: const Duration(seconds: 4)));
  }

  Future<void> _send() async {
    final t = chatCtrl.text.trim();
    if (t.isEmpty || loading) return;
    chat.add({'role': 'user', 'content': t});
    chatCtrl.clear();
    setState(() => loading = true);
    // Скролл вниз
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
    final cfg = await LlmService.loadConfig();
    final ans = await LlmService.chat(cfg, chat);
    if (!mounted) return;
    setState(() { chat.add({'role': 'assistant', 'content': ans}); loading = false; });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _openSettings() async {
    final c = await LlmService.loadConfig();
    final baseCtrl = TextEditingController(text: c.baseUrl);
    final tokenCtrl = TextEditingController(text: c.token);
    final modelCtrl = TextEditingController(text: c.model);
    LlmProvider provider = c.provider;
    bool saving = false;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Text('Настройка ИИ-инструктора', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Ollama Cloud (api.ollama.com) или локальный LM Studio / Ollama (http://localhost:1234)', style: TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 16),
              SegmentedButton<LlmProvider>(
                segments: const [
                  ButtonSegment(value: LlmProvider.ollamaCloud, label: Text('Ollama Cloud'), icon: Icon(Icons.cloud)),
                  ButtonSegment(value: LlmProvider.lmStudio, label: Text('LM Studio'), icon: Icon(Icons.computer)),
                ],
                selected: {provider},
                onSelectionChanged: (s) => setM(() => provider = s.first),
              ),
              const SizedBox(height: 12),
              TextField(controller: baseCtrl, decoration: InputDecoration(labelText: 'Base URL', hintText: provider == LlmProvider.ollamaCloud ? 'https://api.ollama.com' : 'http://localhost:1234', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.link))),
              const SizedBox(height: 12),
              TextField(controller: tokenCtrl, obscureText: true, decoration: InputDecoration(labelText: provider == LlmProvider.ollamaCloud ? 'API токен (обязательно)' : 'Токен (если нужен)', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.key))),
              const SizedBox(height: 12),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Модель', hintText: 'qwen3:8b, llama3.1:8b ...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.smart_toy))),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving ? null : () async {
                  setM(() => saving = true);
                  final cfg = LlmConfig(provider: provider, baseUrl: baseCtrl.text.trim(), token: tokenCtrl.text.trim(), model: modelCtrl.text.trim());
                  await LlmService.saveConfig(cfg);
                  final models = await LlmService.fetchModels(cfg);
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadConfig();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(models.isEmpty ? 'Настройки сохранены (модели не найдены — проверьте URL/токен)' : 'Сохранено. Найдено моделей: ${models.length}'), backgroundColor: models.isEmpty ? Colors.orange.shade700 : Colors.green.shade700));
                },
                icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
                label: const Text('Сохранить'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final cfg = LlmConfig(provider: provider, baseUrl: baseCtrl.text.trim(), token: tokenCtrl.text.trim(), model: modelCtrl.text.trim());
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Проверяем подключение...')));
                  final models = await LlmService.fetchModels(cfg);
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(models.isEmpty ? 'Не удалось получить модели — проверьте URL/токен' : 'Доступно моделей: ${models.take(3).join(", ")}${models.length > 3 ? "…" : ""}')));
                },
                icon: const Icon(Icons.wifi_find_rounded),
                label: const Text('Проверить подключение'),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final isConfigured = llmConfig?.isConfigured ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ИИ-Инструктор', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Stack(alignment: Alignment.center, children: [
            IconButton(icon: const Icon(Icons.settings_rounded), tooltip: 'Настройки LLM', onPressed: _openSettings),
            if (!isConfigured)
              Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle))),
          ]),
        ],
      ),
      body: ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(16),
        children: [
          // Статус LLM
          Card(
            color: isConfigured ? Colors.green.withOpacity(0.08) : Colors.orange.withOpacity(0.10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isConfigured ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.25))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(isConfigured ? Icons.check_circle_rounded : Icons.warning_rounded, color: isConfigured ? Colors.green : Colors.orange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isConfigured ? 'ИИ-инструктор настроен' : 'Требуется настройка', style: TextStyle(fontWeight: FontWeight.w700, color: isConfigured ? Colors.green.shade800 : Colors.orange.shade900, fontSize: 13)),
                    Text(isConfigured ? '${llmConfig!.model} • ${llmConfig!.baseUrl}' : 'Нажмите ⚙️ чтобы указать токен и модель', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ]),
                ),
                TextButton(onPressed: _openSettings, child: Text(isConfigured ? 'Изменить' : 'Настроить')),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // Статистика + действия
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.school_rounded, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Твой прогресс', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Всего ${p.totalAnswered} • Верно ${p.correctAnswers} • Точность ${p.accuracy.toStringAsFixed(1)}% • Тем с ошибками: ${p.mistakesByTheme.length}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ])),
                ]),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.icon(onPressed: loading ? null : _analyze, icon: const Icon(Icons.analytics_rounded, size: 18), label: const Text('Анализ ошибок')),
                  OutlinedButton.icon(onPressed: loading ? null : _suggestGoal, icon: const Icon(Icons.flag_rounded, size: 18), label: const Text('Подобрать цель')),
                  if (analysis.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () { Clipboard.setData(ClipboardData(text: analysis)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скопировано'))); },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Копировать'),
                    ),
                ]),
                if (loading) const Padding(padding: EdgeInsets.only(top: 14), child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))),
                if (analysis.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                    child: SelectableText(analysis, style: const TextStyle(height: 1.45, fontSize: 14)),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // Чат
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Text('Чат с инструктором', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (chat.length > 1) TextButton.icon(onPressed: () => setState(() => chat = [chat.first]), icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Очистить')),
                ]),
                const SizedBox(height: 4),
                const Text('Спроси про любой вопрос, знак или ситуацию на дороге', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 12),
                ...chat.where((m) => m['role'] != 'system').map((m) {
                  final isUser = m['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14).copyWith(
                          bottomRight: isUser ? const Radius.circular(4) : null,
                          bottomLeft: !isUser ? const Radius.circular(4) : null,
                        ),
                      ),
                      child: SelectableText(m['content']!, style: TextStyle(color: isUser ? Colors.white : null, fontSize: 14, height: 1.35)),
                    ),
                  );
                }),
                if (chat.length == 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Wrap(spacing: 8, children: [
                      ActionChip(label: const Text('Разбери мои ошибки'), onPressed: () { chatCtrl.text = 'Разбери мои последние ошибки и скажи что подучить'; _send(); }),
                      ActionChip(label: const Text('Знак "Уступи"'), onPressed: () { chatCtrl.text = 'Объясни знак Уступи дорогу простыми словами'; _send(); }),
                      ActionChip(label: const Text('Перекрёстки'), onPressed: () { chatCtrl.text = 'Как правильно проезжать перекрёстки?'; _send(); }),
                    ]),
                  ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: chatCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Задай вопрос, например: почему ошибаюсь на круговом?',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: loading ? null : _send,
                    style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(14)),
                    child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18),
                  ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('На базе ${llmConfig?.model ?? "—"} • http 1.2.2', style: const TextStyle(fontSize: 11, color: Colors.black38))),
        ],
      ),
    );
  }
}