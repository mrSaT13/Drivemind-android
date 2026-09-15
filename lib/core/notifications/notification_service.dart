import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r){},
      onDidReceiveBackgroundNotificationResponse: _bgHandler,
    );
    await _requestPermissions();
  }
  static Future<void> _requestPermissions() async {
    // POST_NOTIFICATIONS
    if(await Permission.notification.isDenied){
      await Permission.notification.request();
    }
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
    // Camera/gallery handled elsewhere
  }
  @pragma('vm:entry-point')
  static void _bgHandler(NotificationResponse r){}
  static Future<void> scheduleDaily({int hour = 19, int minute = 0}) async {
    await _plugin.cancel(0);
    await _plugin.zonedSchedule(
      0,
      'DriveMind 🧠',
      'Пора потренироваться! 10 минут сегодня = +1 к экзамену',
      _next(hour, minute),
      const NotificationDetails(android: AndroidNotificationDetails('daily', 'Ежедневные напоминания', importance: Importance.high)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  static tz.TZDateTime _next(int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    return d;
  }
  static Future<void> cancel() => _plugin.cancel(0);
  static Future<void> showStreak(int n) => _plugin.show(1, '🔥 Стрик $n дней!', 'Ты на огне! Не пропускай', const NotificationDetails(android: AndroidNotificationDetails('streak', 'Streak')));
  static Future<void> show(String title, String body) => _plugin.show(2, title, body, const NotificationDetails(android: AndroidNotificationDetails('smart', 'Умные напоминания', importance: Importance.high)));
}
