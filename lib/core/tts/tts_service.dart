import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService {
  final _tts = FlutterTts();
  String lang = 'ru-RU';
  double rate = 0.5;
  double pitch = 1.0;
  String? voice;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    lang = p.getString('tts_lang') ?? 'ru-RU';
    rate = p.getDouble('tts_rate') ?? 0.5;
    pitch = p.getDouble('tts_pitch') ?? 1.0;
    voice = p.getString('tts_voice');
    await _apply();
  }
  Future<void> _apply() async {
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    if (voice != null) { try { await _tts.setVoice({'name': voice!, 'locale': lang}); } catch (_) {} }
  }
  Future<void> setLang(String v) async { lang = v; final p = await SharedPreferences.getInstance(); await p.setString('tts_lang', v); await _apply(); }
  Future<void> setRate(double v) async { rate = v; final p = await SharedPreferences.getInstance(); await p.setDouble('tts_rate', v); await _apply(); }
  Future<void> setPitch(double v) async { pitch = v; final p = await SharedPreferences.getInstance(); await p.setDouble('tts_pitch', v); await _apply(); }
  Future<void> setVoice(String? v) async { voice = v; final p = await SharedPreferences.getInstance(); if (v!=null) await p.setString('tts_voice', v); else await p.remove('tts_voice'); await _apply(); }

  Future<List<dynamic>> voices() async { try { return await _tts.getVoices; } catch (_) { return []; } }
  Future<List<String>> languages() async { try { return List<String>.from(await _tts.getLanguages); } catch (_) { return ['ru-RU','en-US']; } }

  Future<void> speak(String t) async { await _tts.speak(t); }
  Future<void> stop() => _tts.stop();
}
final ttsService = TtsService();
