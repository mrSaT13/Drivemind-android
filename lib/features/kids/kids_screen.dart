// ignore_for_file: unused_field, prefer_interpolation_to_compose_strings, deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/storage/storage_service.dart';
import '../../core/tts/tts_service.dart';
import '../../core/llm/llm_service.dart';
import '../../data/models/question.dart';

class KidsScreen extends StatefulWidget {
  const KidsScreen({super.key});
  @override
  State<KidsScreen> createState() => _KidsState();
}

class _KidsState extends State<KidsScreen> {
  List<Question> qs = [];
  int idx = 0;
  int score = 0;
  bool showExplanation = false;
  bool? lastCorrect;
  String kidsHint = '';
  bool isExplaining = false;
  bool autoSpeak = true;

  // Универсальная палитра — не розовая, подходит всем детям
  static const _bg = Color(0xFFF2F7F5); // мягкий мятно-кремовый
  static const _appBar = Color(0xFF0F766E); // тёплый тил
  static const _cardBg = Colors.white;
  static const _questionBg = Color(0xFFE6F0EE); // светлый тил для вопроса

  @override
  void initState() {
    super.initState();
    _load();
    ttsService.init();
  }

  Future<void> _load() async {
    var loaded = await StorageService.loadQuestions(kids: true);
    if (loaded.isEmpty) loaded = await StorageService.loadQuestions();
    qs = loaded.take(100).toList();
    setState(() {});
    if (qs.isNotEmpty && autoSpeak) _speakQuestion();
  }

  Future<void> _speakQuestion() async {
    if (qs.isEmpty || idx < 0 || idx >= qs.length) return;
    final q = qs[idx];
    await ttsService.stop();
    // Озвучиваем вопрос + варианты
    final text = q.text + ". Варианты: " + q.options.join(". ");
    await ttsService.speak(text);
  }

  Future<void> _speakHint() async {
    final hint = kidsHint.isNotEmpty ? kidsHint : (qs[idx].hint.isNotEmpty ? qs[idx].hint : 'Молодец!');
    await ttsService.stop();
    await ttsService.speak(hint);
  }

  String _simplifyLocally(String hint) {
    // Локальное упрощение если LLM недоступен: первое предложение без пунктов ПДД
    var s = hint.split(RegExp(r'[.!?]\s')).first.trim();
    s = s.replaceAll(RegExp(r'\(п\.?\s*\d+.*?\)'), '').replaceAll(RegExp(r'п\.?\s*\d+\.\d+'), '').trim();
    // Убираем слишком длинные юридические фразы
    if (s.length > 160) s = s.substring(0, 157).trim() + '…';
    if (s.isEmpty) s = 'Так правильно, потому что это безопаснее для всех на дороге';
    return s;
  }

  Future<void> _answer(int choice) async {
    final q = qs[idx];
    final ok = choice == q.correctIndex;
    if (ok) score++;

    // Готовим детское объяснение
    setState(() {
      showExplanation = true;
      lastCorrect = ok;
      kidsHint = ''; // покажем индикатор загрузки
      isExplaining = true;
    });

    // Пытаемся получить детское объяснение через LLM, fallback — локально
    String hintToShow;
    try {
      // Быстрый локальный вариант сразу, затем уточняем через LLM если настроен
      final local = _simplifyLocally(q.hint);
      hintToShow = local;
      // Асинхронно пробуем улучшить через LLM (не блокируем UI)
      LlmService.explainForKids(q.text, q.hint).then((kids) {
        if (mounted && showExplanation && idx < qs.length && qs[idx].id == q.id) {
          setState(() => kidsHint = kids);
          if (autoSpeak) _speakHint();
        }
      });
    } catch (_) {
      hintToShow = _simplifyLocally(q.hint);
    }

    setState(() {
      kidsHint = hintToShow;
      isExplaining = false;
    });

    if (autoSpeak) {
      // Даём время прочитать вопрос, затем озвучиваем результат
      await Future.delayed(const Duration(milliseconds: 300));
      _speakHint();
    }
  }

  void _next() async {
    await ttsService.stop();
    if (idx < qs.length - 1) {
      setState(() {
        idx++;
        showExplanation = false;
        lastCorrect = null;
        kidsHint = '';
      });
      if (autoSpeak) {
        await Future.delayed(const Duration(milliseconds: 400));
        _speakQuestion();
      }
    } else {
      setState(() => idx = -1);
    }
  }

  @override
  void dispose() {
    ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme.copyWith(
              titleMedium: GoogleFonts.nunito(fontSize: 19, fontWeight: FontWeight.w800),
              bodyMedium: GoogleFonts.nunito(fontSize: 16),
            )),
        scaffoldBackgroundColor: _bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: _appBar,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: _cardBg,
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            qs.isEmpty ? '🚦 Детский режим' : '🚦 Детский режим  ${idx >= 0 ? "${idx + 1}/${qs.length}" : ""}  •  ⭐ $score',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: autoSpeak ? 'Озвучка вкл' : 'Озвучка выкл',
              icon: Icon(autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded),
              onPressed: () async {
                setState(() => autoSpeak = !autoSpeak);
                if (!autoSpeak) await ttsService.stop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(autoSpeak ? 'Озвучка включена' : 'Озвучка выключена'), duration: const Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
        body: Builder(builder: (_) {
          if (qs.isEmpty) return const Center(child: CircularProgressIndicator(color: _appBar));
          if (idx == -1) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🏆', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 12),
                  Text('Молодец! $score из ${qs.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Ты большой умница! Повторим ещё?', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _appBar, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                    onPressed: () => setState(() { idx = 0; score = 0; showExplanation = false; }),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Ещё раз'),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('На главную')),
                ]),
              ),
            );
          }
          final q = qs[idx];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (q.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/${q.image}',
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: const Color(0xFFE0F2F1),
                      child: const Center(child: Text('🚦', style: TextStyle(fontSize: 56))),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              // Вопрос — с кнопкой озвучки
              Card(
                color: _questionBg,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _appBar.withOpacity(0.12))),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          q.text,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.35, color: Color(0xFF1A2E2A)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Озвучить вопрос',
                        icon: const Icon(Icons.volume_up_rounded, color: _appBar),
                        onPressed: _speakQuestion,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Варианты — без фиксированной высоты, переносятся
              ...List.generate(q.options.length, (i) {
                final isCorrect = showExplanation && i == q.correctIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Material(
                    color: isCorrect ? const Color(0xFFE8F5E9) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isCorrect ? Colors.green.shade300 : Colors.black.withOpacity(0.06), width: isCorrect ? 1.6 : 1),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: showExplanation ? null : () => _answer(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCorrect ? Colors.green : _appBar.withOpacity(0.10),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(String.fromCharCode(65 + i), style: TextStyle(fontWeight: FontWeight.w800, color: isCorrect ? Colors.white : _appBar)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                q.options[i],
                                style: TextStyle(fontSize: 15.5, height: 1.35, fontWeight: FontWeight.w600, color: isCorrect ? Colors.green.shade900 : Colors.black87),
                              ),
                            ),
                            if (isCorrect) const Icon(Icons.check_circle_rounded, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              // Объяснение — остаётся на экране, не исчезает, с озвучкой по кнопке
              if (showExplanation)
                Card(
                  color: lastCorrect == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: lastCorrect == true ? Colors.green : Colors.orange, shape: BoxShape.circle),
                          child: Icon(lastCorrect == true ? Icons.check_rounded : Icons.lightbulb_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lastCorrect == true ? 'Правильно! 🎉' : 'Давай разберёмся 🤔',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: lastCorrect == true ? Colors.green.shade800 : Colors.orange.shade900),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Озвучить объяснение',
                          icon: const Icon(Icons.volume_up_rounded, color: _appBar),
                          onPressed: _speakHint,
                        ),
                      ]),
                      const SizedBox(height: 8),
                      if (isExplaining && kidsHint.isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                      else
                        Text(kidsHint.isNotEmpty ? kidsHint : _simplifyLocally(q.hint), style: const TextStyle(fontSize: 15.5, height: 1.4, color: Color(0xFF2A3835))),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: _appBar, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(idx == qs.length - 1 ? 'Завершить' : 'Далее →'),
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: (idx + 1) / qs.length, minHeight: 8, backgroundColor: Colors.black12, color: _appBar),
              ),
              const SizedBox(height: 6),
              Center(child: Text('${idx + 1} из ${qs.length}  •  Нажми на ответ и послушай объяснение', style: TextStyle(fontSize: 12, color: Colors.black54.withOpacity(0.7)))),
            ],
          );
        }),
      ),
    );
  }
}