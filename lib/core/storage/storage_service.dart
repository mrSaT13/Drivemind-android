import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/question.dart';
import '../../data/models/profile.dart';

class StorageService {
  static late Box box;
  static Future<void> init() async {
    await Hive.initFlutter();
    box = await Hive.openBox('drivemind');
  }

  static Future<List<Question>> loadQuestions({bool kids = false}) async {
    final asset = kids ? 'assets/data/questions_kids.json' : 'assets/data/questions.json';
    try {
      final raw = await rootBundle.loadString(asset);
      final List j = jsonDecode(raw);
      return j.map((e) => Question.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Profile loadProfile() {
    final j = box.get('profile');
    if (j == null) return Profile();
    return Profile.fromJson(Map<String, dynamic>.from(j));
  }

  static Future<void> saveProfile(Profile p) async => box.put('profile', p.toJson());

  // ---- mistakes ----
  static List<String> get mistakes => List<String>.from(box.get('mistakes') ?? []);
  static Future<void> addMistake(String id) async {
    final m = mistakes;
    if (!m.contains(id)) { m.add(id); await box.put('mistakes', m); }
  }
  static Future<void> clearMistakes() => box.delete('mistakes');

  // ---- favorites / hard ----
  static Future<void> toggleFavorite(Profile p, String id) async {
    p.favorites.contains(id) ? p.favorites.remove(id) : p.favorites.add(id);
    await saveProfile(p);
  }
  static Future<void> toggleHard(Profile p, String id) async {
    p.hardQuestions.contains(id) ? p.hardQuestions.remove(id) : p.hardQuestions.add(id);
    await saveProfile(p);
  }

  static Future<void> addCoins(Profile p, int n) async { p.coins += n; await saveProfile(p); }

  static Future<void> recordSession(Profile p, int correct, int total) async {
    final today = DateTime.now();
    p.history.add(SessionResult(date: today, correct: correct, total: total));
    if (p.history.length > 90) p.history = p.history.sublist(p.history.length - 90);
    final d = today.subtract(const Duration(days: 1));
    if (p.lastVisit != null && p.lastVisit!.difference(d).inDays == 0) p.streak++;
    else if (p.lastVisit == null || today.difference(p.lastVisit!).inDays > 1) p.streak = 1;
    else p.streak = p.streak;
    p.lastVisit = today;
    await saveProfile(p);
  }

  // ---- daily quest ----
  static const int questTarget = 10;
  static Future<void> ensureQuest(Profile p) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (p.questDate != today) { p.questDate = today; p.questProgress = 0; await saveProfile(p); }
  }
  static Future<void> addQuest(Profile p, int n) async {
    await ensureQuest(p);
    p.questProgress = (p.questProgress + n).clamp(0, questTarget);
    if (p.questProgress >= questTarget && !p.achievements.contains('daily_quest')) p.achievements.add('daily_quest');
    await saveProfile(p);
  }

  // ---- export / import ----
  static String export() { final p = loadProfile(); return jsonEncode({'profile': p.toJson(), 'mistakes': mistakes}); }
  static Future<void> import(String data) async {
    final j = jsonDecode(data);
    await saveProfile(Profile.fromJson(Map<String, dynamic>.from(j['profile'])));
    await box.put('mistakes', List<String>.from(j['mistakes'] ?? []));
  }

  static Future<void> setDailyReminder(bool v) async => (await SharedPreferences.getInstance()).setBool('daily_reminder', v);
  static Future<bool> getDailyReminder() async => (await SharedPreferences.getInstance()).getBool('daily_reminder') ?? true;
  static Future<bool> getOnboarded() async => (await SharedPreferences.getInstance()).getBool('onboarded') ?? false;
  static Future<void> setOnboarded() async => (await SharedPreferences.getInstance()).setBool('onboarded', true);
}
