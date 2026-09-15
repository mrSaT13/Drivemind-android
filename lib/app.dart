import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/theme/theme_provider.dart';
import 'core/storage/storage_service.dart';
import 'features/home/home_screen.dart';
import 'features/profile/settings_screen.dart';
import 'features/tickets/tickets_screen.dart';
import 'features/exam/exam_screen.dart';
import 'features/themes/themes_screen.dart';
import 'features/marathon/marathon_screen.dart';
import 'features/kids/kids_screen.dart';
import 'features/trainer/trainer_options.dart';
import 'features/profile/profile_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/speed/speed_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/achievements/achievements_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/search/search_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/signs/signs_trainer_screen.dart';
import 'features/mistakes/error_map_screen.dart';
import 'features/games/games_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/spaced/spaced_review_screen.dart';
import 'features/backup/backup_screen.dart';
import 'features/instructor/instructor_screen.dart';

class DriveMindApp extends ConsumerWidget {
  const DriveMindApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    return FutureBuilder<bool>(
      future: StorageService.getOnboarded(),
      builder: (context, snap) {
        return DynamicColorBuilder(builder: (lightDyn, darkDyn) {
          final dyn = Theme.of(context).brightness == Brightness.dark ? darkDyn : lightDyn;
          return MaterialApp(
            title: 'DriveMind',
            theme: buildTheme(themeState, dyn),
            darkTheme: buildTheme(themeState.copyWith(mode: ThemeMode.dark), darkDyn),
            themeMode: effectiveMode(themeState),
            routes: {
              '/': (_) => const HomeScreen(),
              '/splash': (_) => const SplashScreen(),
              '/onboarding': (_) => const OnboardingScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/tickets': (_) => const TicketsScreen(),
              '/exam': (_) => const ExamScreen(),
              '/examAB': (_) => const ExamScreen(ab: true),
              '/themes': (_) => const ThemesScreen(),
              '/marathon': (_) => const MarathonScreen(),
              '/kids': (_) => const KidsScreen(),
              '/trainer': (_) => const TrainerOptions(),
              '/profile': (_) => const ProfileScreen(),
              '/favorites': (_) => const FavoritesScreen(),
              '/speed': (_) => const SpeedScreen(),
              '/shop': (_) => const ShopScreen(),
              '/achievements': (_) => const AchievementsScreen(),
              '/stats': (_) => const StatsScreen(),
              '/search': (_) => const SearchScreen(),
              '/signs': (_) => const SignsTrainer(),
              '/errormap': (_) => const ErrorMapScreen(),
              '/games': (_) => const GamesScreen(),
              '/goals': (_) => const GoalsScreen(),
              '/spaced': (_) => const SpacedReviewScreen(),
              '/backup': (_) => const BackupScreen(),
              '/instructor': (_) => const InstructorScreen(),
            },
            initialRoute: '/splash',
            debugShowCheckedModeBanner: false,
          );
        });
      },
    );
  }
}
