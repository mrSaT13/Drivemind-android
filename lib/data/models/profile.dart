class SessionResult {
  final DateTime date;
  final int correct;
  final int total;
  SessionResult({required this.date, required this.correct, required this.total});
  factory SessionResult.fromJson(Map<String, dynamic> j) => SessionResult(
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        correct: j['correct'] ?? 0,
        total: j['total'] ?? 0,
      );
  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'correct': correct, 'total': total};
}

class Profile {
  String? avatarPath;
  int totalAnswered;
  int correctAnswers;
  List<String> achievements;
  Map<String, int> mistakesByTheme;
  int streak;
  DateTime? lastVisit;
  int coins;
  List<String> favorites;
  List<String> hardQuestions;
  List<SessionResult> history;
  String? questDate;
  int questProgress;
  List<String> ownedThemes;
  List<String> ownedAvatars;
  Map<String, String> notes;
  DateTime? goalDate;
  int goalDaily;
  Map<String, String> spaced;

  Profile({
    this.avatarPath,
    this.totalAnswered = 0,
    this.correctAnswers = 0,
    List<String>? achievements,
    Map<String, int>? mistakesByTheme,
    this.streak = 0,
    this.lastVisit,
    this.coins = 0,
    List<String>? favorites,
    List<String>? hardQuestions,
    List<SessionResult>? history,
    this.questDate,
    this.questProgress = 0,
    List<String>? ownedThemes,
    List<String>? ownedAvatars,
    Map<String, String>? notes,
    this.goalDate,
    this.goalDaily = 20,
    Map<String, String>? spaced,
  })  : achievements = achievements ?? [],
        mistakesByTheme = mistakesByTheme ?? {},
        favorites = favorites ?? [],
        hardQuestions = hardQuestions ?? [],
        history = history ?? [],
        ownedThemes = ownedThemes ?? ['midnight','graphite','ocean'],
        ownedAvatars = ownedAvatars ?? [],
        notes = notes ?? {},
        spaced = spaced ?? {};

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        avatarPath: j['avatar'],
        totalAnswered: j['total_questions_answered'] ?? j['totalAnswered'] ?? 0,
        correctAnswers: j['correct_answers'] ?? j['correctAnswers'] ?? 0,
        achievements: List<String>.from(j['achievements'] ?? []),
        mistakesByTheme: Map<String, int>.from(j['mistakes_by_theme'] ?? j['mistakesByTheme'] ?? {}),
        streak: j['streak'] ?? 0,
        lastVisit: j['lastVisit'] != null ? DateTime.tryParse(j['lastVisit']) : null,
        coins: j['coins'] ?? 0,
        favorites: List<String>.from(j['favorites'] ?? []),
        hardQuestions: List<String>.from(j['hardQuestions'] ?? []),
        history: (j['history'] as List? ?? []).map((e) => SessionResult.fromJson(e)).toList(),
        questDate: j['questDate'],
        questProgress: j['questProgress'] ?? 0,
        ownedThemes: List<String>.from(j['ownedThemes'] ?? ['midnight','graphite','ocean']),
        ownedAvatars: List<String>.from(j['ownedAvatars'] ?? []),
        notes: Map<String, String>.from(j['notes'] ?? {}),
        goalDate: j['goalDate'] != null ? DateTime.tryParse(j['goalDate']) : null,
        goalDaily: j['goalDaily'] ?? 20,
        spaced: Map<String, String>.from(j['spaced'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'avatar': avatarPath,
        'total_questions_answered': totalAnswered,
        'correct_answers': correctAnswers,
        'achievements': achievements,
        'mistakes_by_theme': mistakesByTheme,
        'streak': streak,
        'lastVisit': lastVisit?.toIso8601String(),
        'coins': coins,
        'favorites': favorites,
        'hardQuestions': hardQuestions,
        'history': history.map((e) => e.toJson()).toList(),
        'questDate': questDate,
        'questProgress': questProgress,
        'ownedThemes': ownedThemes,
        'ownedAvatars': ownedAvatars,
        'notes': notes,
        'goalDate': goalDate?.toIso8601String(),
        'goalDaily': goalDaily,
        'spaced': spaced,
      };

  double get accuracy => totalAnswered == 0 ? 0 : correctAnswers / totalAnswered * 100;
}
