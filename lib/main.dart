import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/storage_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/tts/tts_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await StorageService.ensureQuest(StorageService.loadProfile());
  await NotificationService.init();
  await ttsService.init();
  final remind = await StorageService.getDailyReminder();
  if (remind) await NotificationService.scheduleDaily();
  final p = StorageService.loadProfile();
  if (p.lastVisit == null || DateTime.now().difference(p.lastVisit!).inDays >= 2) {
    await NotificationService.show('С возвращением! 🚗', 'Ты давно не тренировался. Пора освежить ПДД!');
  }
  runApp(const ProviderScope(child: DriveMindApp()));
}
