import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import '../../data/models/profile.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, Profile>((ref) => ProfileNotifier());

class ProfileNotifier extends StateNotifier<Profile> {
  ProfileNotifier() : super(StorageService.loadProfile());
  Profile _c() => state = Profile.fromJson(state.toJson());
  Future<void> _save() => StorageService.saveProfile(state);

  void addCoins(int n) { _c(); state.coins += n; _save(); }
  void reload() => state = StorageService.loadProfile();
  void toggleFavorite(String id) { _c(); state.favorites.contains(id) ? state.favorites.remove(id) : state.favorites.add(id); _save(); }
  void toggleHard(String id) { _c(); state.hardQuestions.contains(id) ? state.hardQuestions.remove(id) : state.hardQuestions.add(id); _save(); }
  void answerQuestion(String topic, bool correct) {
    _c();
    state.totalAnswered++;
    if (correct) {
      state.correctAnswers++;
    } else {
      state.mistakesByTheme[topic] = (state.mistakesByTheme[topic] ?? 0) + 1;
    }
    _check();
    _save();
  }

  Future<void> record(int correct, int total) async { await StorageService.recordSession(state, correct, total); _check(); await _save(); state = StorageService.loadProfile(); }
  Future<void> quest(int n) async { await StorageService.addQuest(state, n); _check(); await _save(); state = StorageService.loadProfile(); }

  void _check(){
    void unlock(String a){ if(!state.achievements.contains(a)) state.achievements.add(a); }
    if(state.totalAnswered>=1) unlock('first_steps');
    if(state.totalAnswered>=100) unlock('hundred_club');
    if(state.streak>=7) unlock('streak_7');
    if(state.correctAnswers>=18 && state.achievements.contains('exam_master')==false && state.history.any((h)=>h.total==20 && h.correct>=18)) unlock('exam_master');
    if(state.hardQuestions.isNotEmpty) unlock('signs_expert');
    if(state.history.any((h)=>h.total>=800)) unlock('trainer_pro');
  }

  void buyTheme(String name, int cost) { if(state.coins>=cost && !state.ownedThemes.contains(name)){ _c(); state.coins-=cost; state.ownedThemes.add(name); _save(); } }
  void buyAvatar(String name, int cost) { if(state.coins>=cost && !state.ownedAvatars.contains(name)){ _c(); state.coins-=cost; state.ownedAvatars.add(name); _save(); } }
  void selectAvatar(String path) { _c(); state.avatarPath=path; _save(); }
  void setAvatarFile(String path) { _c(); state.avatarPath=path; _save(); }
  void setNote(String id, String text) { _c(); if(text.isEmpty) state.notes.remove(id); else state.notes[id]=text; _save(); }
  Future<void> setGoal(DateTime? d, int daily) async { _c(); state.goalDate=d; state.goalDaily=daily; await _save(); }
  void scheduleSpaced(String id, {bool correct = true}) {
    _c();
    final cur = state.spaced[id];
    int step = cur != null ? (int.tryParse(cur.split('|').first) ?? 0) : 0;
    if (correct) {
      step = step + 1 > 5 ? 5 : step + 1;
      final next = DateTime.now().add(Duration(days: const [1, 3, 7, 16, 30][step - 1]));
      state.spaced[id] = '$step|${next.toIso8601String()}';
    } else {
      state.spaced[id] = '0|${DateTime.now().add(const Duration(days: 1)).toIso8601String()}';
    }
    _save();
  }
  bool isSpacedDue(String id) {
    final cur = state.spaced[id];
    if (cur == null) return true;
    final iso = cur.split('|').last;
    final next = DateTime.tryParse(iso);
    return next == null || DateTime.now().isAfter(next);
  }
}
