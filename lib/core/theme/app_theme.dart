import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PresetTheme { midnight, graphite, ocean, nebula, forest, sunset, desert, arctic, aurora, neon, cyber, volcano }

class AppThemePreset {
  final String name;
  final Color seed;
  final Color bg;
  final Color card;
  final Color accent;
  const AppThemePreset(this.name, this.seed, this.bg, this.card, this.accent);
}

const presets = {
  PresetTheme.midnight: AppThemePreset('Midnight', Color(0xFF5E60CE), Color(0xFF0F0F1E), Color(0xFF1E1E2E), Color(0xFF747BFF)),
  PresetTheme.graphite: AppThemePreset('Graphite', Color(0xFF6C757D), Color(0xFF121212), Color(0xFF1E1E1E), Color(0xFFADB5BD)),
  PresetTheme.ocean: AppThemePreset('Ocean', Color(0xFF0096C7), Color(0xFF0A1626), Color(0xFF13233A), Color(0xFF48CAE4)),
  PresetTheme.nebula: AppThemePreset('Nebula', Color(0xFF9D4EDD), Color(0xFF1A1026), Color(0xFF2A1B3D), Color(0xFFC77DFF)),
  PresetTheme.forest: AppThemePreset('Forest', Color(0xFF2D6A4F), Color(0xFF0D1B14), Color(0xFF1B2E22), Color(0xFF52B788)),
  PresetTheme.sunset: AppThemePreset('Sunset', Color(0xFFFF6B35), Color(0xFF1E1210), Color(0xFF2E1E18), Color(0xFFFF8C61)),
  PresetTheme.desert: AppThemePreset('Desert', Color(0xFFCA8A04), Color(0xFF1F1400), Color(0xFF2E2000), Color(0xFFFACC15)),
  PresetTheme.arctic: AppThemePreset('Arctic', Color(0xFF06B6D4), Color(0xFF0A1220), Color(0xFF112233), Color(0xFF67E8F9)),
  PresetTheme.aurora: AppThemePreset('Aurora', Color(0xFF00F5A0), Color(0xFF001A12), Color(0xFF002B1F), Color(0xFF00FFB3)),
  PresetTheme.neon: AppThemePreset('Neon', Color(0xFFFF00E5), Color(0xFF1A001A), Color(0xFF2A0033), Color(0xFFFF3DF5)),
  PresetTheme.cyber: AppThemePreset('Cyber', Color(0xFF39FF14), Color(0xFF0A0F0A), Color(0xFF141E14), Color(0xFF39FF14)),
  PresetTheme.volcano: AppThemePreset('Volcano', Color(0xFFFF1B1B), Color(0xFF1A0505), Color(0xFF2E0A0A), Color(0xFFFF3B30)),
};

const themeCosts = {
  PresetTheme.nebula: 100,
  PresetTheme.forest: 150,
  PresetTheme.sunset: 150,
  PresetTheme.desert: 100,
  PresetTheme.arctic: 200,
  PresetTheme.aurora: 300,
  PresetTheme.neon: 350,
  PresetTheme.cyber: 400,
  PresetTheme.volcano: 250,
};
const themeAchievements = {
  PresetTheme.aurora: 'streak_7',
  PresetTheme.neon: 'exam_master',
  PresetTheme.cyber: 'hundred_club',
  PresetTheme.volcano: 'trainer_pro',
};

bool isThemeUnlocked(PresetTheme t, List<String> owned, List<String> achievements) {
  if (owned.contains(t.name)) return true;
  final ach = themeAchievements[t];
  if (ach != null && achievements.contains(ach)) return true;
  return themeCosts[t] == null;
}

class AppTheme {
  static ThemeData build(PresetTheme preset, bool useDynamic, ColorScheme? dynamicScheme, bool gradientBg) {
    final p = presets[preset]!;
    final seed = useDynamic && dynamicScheme != null ? dynamicScheme.primary : p.seed;
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        background: p.bg,
        surface: p.card,
        primary: p.accent,
      ),
      scaffoldBackgroundColor: p.bg,
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(backgroundColor: p.bg, elevation: 0, centerTitle: true),
      extensions: [GradientExt(enabled: gradientBg, colors: [p.accent.withOpacity(0.25), p.bg])],
    );
  }

  static ThemeData lightFrom(PresetTheme preset) {
    final p = presets[preset]!;
    final scheme = ColorScheme.fromSeed(seedColor: p.seed, brightness: Brightness.light);
    return ThemeData(useMaterial3: true, colorScheme: scheme, textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme));
  }
}

class GradientExt extends ThemeExtension<GradientExt> {
  final bool enabled;
  final List<Color> colors;
  const GradientExt({required this.enabled, required this.colors});
  @override
  GradientExt copyWith({bool? enabled, List<Color>? colors}) => GradientExt(enabled: enabled ?? this.enabled, colors: colors ?? this.colors);
  @override
  GradientExt lerp(GradientExt? other, double t) => this;
}

Widget gradientBackground(Widget child, BuildContext context) {
  final ext = Theme.of(context).extension<GradientExt>();
  if (ext == null || !ext.enabled) return child;
  return Container(
    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: ext.colors)),
    child: child,
  );
}
