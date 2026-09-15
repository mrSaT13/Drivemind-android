import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер LLM — поддерживает Ollama Cloud (OpenAI-совместимый) и локальный LM Studio / Ollama.
enum LlmProvider { ollamaCloud, lmStudio }

/// Конфигурация подключения к LLM.
class LlmConfig {
  final LlmProvider provider;
  final String baseUrl;
  final String token;
  final String model;

  const LlmConfig({
    required this.provider,
    required this.baseUrl,
    required this.token,
    required this.model,
  });

  factory LlmConfig.defaults() => const LlmConfig(
        provider: LlmProvider.ollamaCloud,
        baseUrl: 'https://api.ollama.com',
        token: '',
        model: 'qwen3:8b',
      );

  Map<String, dynamic> toJson() => {
        'provider': provider.index,
        'baseUrl': baseUrl,
        'token': token,
        'model': model,
      };

  factory LlmConfig.fromJson(Map<String, dynamic> j) => LlmConfig(
        provider: LlmProvider.values[(j['provider'] as int?) ?? 0],
        baseUrl: (j['baseUrl'] as String?) ?? 'https://api.ollama.com',
        token: (j['token'] as String?) ?? '',
        model: (j['model'] as String?) ?? 'qwen3:8b',
      );

  bool get isConfigured {
    if (provider == LlmProvider.lmStudio) return baseUrl.isNotEmpty && model.isNotEmpty;
    return token.isNotEmpty && baseUrl.isNotEmpty && model.isNotEmpty;
  }

  String get normalizedBaseUrl => baseUrl.replaceAll(RegExp(r'/+$'), '');

  LlmConfig copyWith({LlmProvider? provider, String? baseUrl, String? token, String? model}) =>
      LlmConfig(
        provider: provider ?? this.provider,
        baseUrl: baseUrl ?? this.baseUrl,
        token: token ?? this.token,
        model: model ?? this.model,
      );
}

/// Сервис для работы с LLM: хранение настроек, запрос моделей, чат и анализ ошибок.
class LlmService {
  static const _storageKey = 'llm_config';
  static const _tokenKey = 'llm_token';
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _httpTimeout = Duration(seconds: 30);

  // ---------- Config persistence ----------
  // Токен — только в EncryptedSharedPreferences (flutter_secure_storage),
  // остальное (baseUrl/model/provider) — в обычных SharedPreferences.

  static Future<LlmConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    LlmConfig cfg;
    if (raw == null) {
      cfg = LlmConfig.defaults();
    } else {
      try {
        cfg = LlmConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        cfg = LlmConfig.defaults();
      }
    }
    try {
      String? secureToken = await _secure.read(key: _tokenKey);
      if (secureToken != null && secureToken.isNotEmpty) {
        // Secure-токен приоритетнее
        if (secureToken != cfg.token) cfg = cfg.copyWith(token: secureToken);
      } else if (cfg.token.isNotEmpty) {
        // Миграция: токен лежал в plaintext-поле → переносим в secure и чистим
        await _secure.write(key: _tokenKey, value: cfg.token);
        final clean = cfg.copyWith(token: '');
        await prefs.setString(_storageKey, jsonEncode(clean.toJson()));
      }
    } catch (_) {
      // Если secure storage недоступен — работаем как раньше (plaintext fallback)
    }
    return cfg;
  }

  static Future<void> saveConfig(LlmConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (config.token.isNotEmpty) {
        await _secure.write(key: _tokenKey, value: config.token);
      } else {
        await _secure.delete(key: _tokenKey);
      }
    } catch (_) {}
    // В обычные префы пишем всё КРОМЕ токена
    final noToken = config.copyWith(token: '');
    await prefs.setString(_storageKey, jsonEncode(noToken.toJson()));
  }

  /// Полная очистка (например, при логауте/сбросе).
  static Future<void> clearToken() async {
    try {
      await _secure.delete(key: _tokenKey);
    } catch (_) {}
  }

  // ---------- Models ----------

  /// Загружает список доступных моделей. Пробует OpenAI-совместимый /v1/models, затем Ollama /api/tags.
  static Future<List<String>> fetchModels(LlmConfig c) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (c.token.isNotEmpty) headers['Authorization'] = 'Bearer ${c.token}';
    final base = c.normalizedBaseUrl;

    // OpenAI-compatible
    try {
      final url = Uri.parse('$base/v1/models');
      final resp = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        final data = j['data'] as List?;
        if (data != null && data.isNotEmpty) {
          return data.map((e) => (e['id'] ?? e['name']).toString()).toList();
        }
      }
    } catch (_) {}

    // Ollama native fallback
    try {
      final url2 = Uri.parse('$base/api/tags');
      final resp2 = await http.get(url2, headers: headers).timeout(const Duration(seconds: 10));
      if (resp2.statusCode == 200) {
        final j = jsonDecode(resp2.body);
        final models = j['models'] as List?;
        if (models != null) return models.map((e) => e['name'].toString()).toList();
      }
    } catch (_) {}

    return [];
  }

  // ---------- Chat ----------

  /// Универсальный чат: сначала пробует OpenAI-совместимый эндпоинт, затем Ollama /api/chat.
  static Future<String> chat(LlmConfig c, List<Map<String, String>> messages) async {
    if (!c.isConfigured && c.provider == LlmProvider.ollamaCloud) {
      return 'Не настроен ИИ-инструктор: укажите API-токен в Настройки → ИИ-Инструктор.';
    }

    final base = c.normalizedBaseUrl;
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (c.token.isNotEmpty) headers['Authorization'] = 'Bearer ${c.token}';

    // 1) OpenAI-compatible /v1/chat/completions
    try {
      final url = Uri.parse('$base/v1/chat/completions');
      final body = jsonEncode({'model': c.model, 'messages': messages, 'temperature': 0.7});
      final resp = await http.post(url, headers: headers, body: body).timeout(_httpTimeout);
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        final choices = j['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']?['content'] ?? choices[0]['text'];
          if (content != null && content.toString().trim().isNotEmpty) return content.toString().trim();
        }
        // Some providers return directly
        if (j['content'] != null) return j['content'].toString();
      } else if (resp.statusCode != 404) {
        // Если не 404 — вернём ошибку, иначе пробуем fallback
        return 'Ошибка LLM (${resp.statusCode}): ${_safeBody(resp.body)}';
      }
    } on TimeoutException {
      return 'Тайм-аут соединения с LLM. Проверьте адрес сервера.';
    } catch (e) {
      // продолжаем к fallback
      if (e is TimeoutException) return 'Тайм-аут соединения с LLM.';
    }

    // 2) Ollama native /api/chat
    try {
      final url2 = Uri.parse('$base/api/chat');
      final body2 = jsonEncode({'model': c.model, 'messages': messages, 'stream': false});
      final resp2 = await http.post(url2, headers: headers, body: body2).timeout(_httpTimeout);
      if (resp2.statusCode == 200) {
        final j = jsonDecode(resp2.body);
        final content = j['message']?['content'] ?? j['response'];
        if (content != null) return content.toString().trim();
        return resp2.body;
      }
      return 'Ошибка LLM (${resp2.statusCode}): ${_safeBody(resp2.body)}';
    } on TimeoutException {
      return 'Тайм-аут соединения с LLM. Проверьте адрес сервера.';
    } catch (e) {
      return 'Ошибка сети: $e';
    }
  }

  static String _safeBody(String body) => body.length > 500 ? '${body.substring(0, 500)}…' : body;

  // ---------- High-level helpers ----------

  /// Анализ ошибок ученика — возвращает структурированный разбор.
  static Future<String> analyzeErrors(
    Map<String, int> mistakesByTheme,
    int total,
    int correct,
    String goal,
  ) async {
    final c = await loadConfig();
    if (!c.isConfigured && c.provider == LlmProvider.ollamaCloud) {
      return 'Укажите API-токен Ollama Cloud в Настройках → ИИ-Инструктор. Без токена анализ недоступен.';
    }
    final mistakes = mistakesByTheme.isEmpty
        ? 'Ошибок пока нет — отличный старт!'
        : mistakesByTheme.entries.map((e) => '• ${e.key}: ${e.value} ош.').join('\n');
    final accuracy = total == 0 ? 0 : correct / total * 100;

    final prompt = '''Ты — опытный автоинструктор DriveMind (ПДД РФ 2025, категории A/B).
Проанализируй статистику ученика и дай краткий, но содержательный разбор.

Статистика: всего отвечено $total, верно $correct, точность ${accuracy.toStringAsFixed(1)}%.
Ошибки по темам:
$mistakes
Цель ученика: $goal

Верни ответ в формате:
1) Топ-3 слабые темы (с объяснением почему они важны)
2) Что конкретно повторить (пункты ПДД, знаки, манёвры)
3) План на 7 дней (сколько вопросов/тем в день, интервальное повторение)
4) Короткая мотивация (1-2 предложения)

Требования: пиши по-русски, дружелюбно, с эмодзи, списками. Без воды, только конкретика.''';

    return chat(c, [
      {'role': 'system', 'content': 'Ты — инструктор ПДД с 10+ годами опыта, отвечаешь кратко, по делу, мотивирующе.'},
      {'role': 'user', 'content': prompt},
    ]);
  }

  /// Подбор цели подготовки — возвращает JSON с полями days/daily/reason.
  static Future<String> suggestGoals(Map<String, int> mistakesByTheme) async {
    final c = await loadConfig();
    final mistakes = mistakesByTheme.isEmpty ? 'нет ошибок' : mistakesByTheme.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    final prompt = 'На основе ошибок по темам ПДД: $mistakes. '
        'Предложи реалистичную цель подготовки к экзамену ПДД РФ (категории A/B). '
        'Верни ТОЛЬКО JSON вида {"days":14,"daily":20,"reason":"краткое объяснение почему"} '
        'где days — через сколько дней сдавать (7-30), daily — вопросов в день (10-40).';

    final res = await chat(c, [
      {'role': 'system', 'content': 'Ты помощник по планированию подготовки к ПДД. Отвечай только JSON.'},
      {'role': 'user', 'content': prompt},
    ]);
    return res;
  }

  /// Упрощает объяснение для детей (6-10 лет): короткие фразы, аналогии, без терминов.
  static Future<String> explainForKids(String question, String hint) async {
    final c = await loadConfig();
    // Если LLM не настроен — вернём упрощённый hint локально
    if (!c.isConfigured) return _simplifyHintLocally(hint);

    final prompt = '''Объясни ребёнку 7 лет простым языком (как для детского сада) почему правильный ответ именно такой.
Вопрос: "$question"
Правильное объяснение для взрослых: "$hint"
Сделай 2-3 коротких предложения, без сложных терминов, с аналогией из жизни ребёнка. Начни с "Представь..." или "Запомни:" и добавь эмодзи.''';

    final res = await chat(c, [
      {'role': 'system', 'content': 'Ты — добрый детский инструктор ПДД, объясняешь очень просто.'},
      {'role': 'user', 'content': prompt},
    ]);
    // Если LLM вернул ошибку — fallback к локальному упрощению
    if (res.startsWith('Ошибка') || res.startsWith('Не настроен') || res.startsWith('Тайм-аут')) {
      return _simplifyHintLocally(hint);
    }
    return res;
  }

  static String _simplifyHintLocally(String hint) {
    // Берём первое предложение, убираем ссылки на пункты ПДД
    var s = hint.split(RegExp(r'[.!?]\s')).first;
    s = s.replaceAll(RegExp(r'\(п\.?\s*\d+.*?\)'), '').replaceAll(RegExp(r'п\.?\s*\d+\.\d+'), '').trim();
    if (s.length > 180) s = '${s.substring(0, 177)}…';
    return 'Запомни: $s 🚦 Будь внимательным на дороге!';
  }
}