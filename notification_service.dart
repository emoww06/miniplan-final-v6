import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<void> scheduleDailyNotifications() async {
    // Morning notification at 8:00 AM
    await _scheduleNotification(
      id: 1,
      title: 'Günaydın! 🌅',
      body: 'Bugün için 3 hedefinizi belirleyin ve güne başlayın!',
      hour: 8,
      minute: 0,
    );

    // Noon notification at 12:00 PM
    await _scheduleNotification(
      id: 2,
      title: 'Öğle Kontrolü! ☀️',
      body: 'Hedeflerinizi kontrol edin ve motivasyonunuzu koruyun!',
      hour: 12,
      minute: 0,
    );

    // Evening notification at 8:00 PM
    await _scheduleNotification(
      id: 3,
      title: 'Günü Kapatma Zamanı! 🌙',
      body: 'Hedeflerinizi değerlendirin ve AI geri bildiriminizi alın!',
      hour: 20,
      minute: 0,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_goals',
          'Günlük Hedefler',
          channelDescription: 'Günlük hedef hatırlatmaları',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant',
          'Anlık Bildirimler',
          channelDescription: 'Anlık bildirimler',
          importance: Importance.default,
          priority: Priority.default,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
} 