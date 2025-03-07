import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Inicializar timezone
    tz_data.initializeTimeZones();

    // Configurar notificaciones locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Solicitar permisos para notificaciones push
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar manejadores de mensajes
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  void _handleMessage(RemoteMessage message) {
    print('Mensaje recibido mientras la app está en primer plano: ${message.notification?.title}');
    _showNotification(
      message.notification?.title ?? 'Nueva notificación',
      message.notification?.body ?? '',
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Mensaje abierto desde la notificación: ${message.notification?.title}');
    // Aquí puedes navegar a una pantalla específica si es necesario
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Notifications for tasks',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleTaskReminder(Task task) async {
    // Si la tarea no tiene hora específica, programar para el día anterior
    if (task.horaVencimiento == null) {
      final scheduledDate = tz.TZDateTime.from(
        task.fechaVencimiento.subtract(const Duration(days: 1)),
        tz.local,
      );

      // Verificar si la fecha ya pasó
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        task.id.hashCode,
        '¡Tarea próxima a vencer!',
        'La tarea "${task.titulo}" vence mañana.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminder_channel',
            'Task Reminders',
            channelDescription: 'Reminders for tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      // Si la tarea tiene hora específica, programar según los minutos de anticipación
      final DateTime? fechaHoraVencimiento = task.getFechaHoraVencimiento();
      
      if (fechaHoraVencimiento == null) return;
      
      final scheduledDate = tz.TZDateTime.from(
        fechaHoraVencimiento.subtract(Duration(minutes: task.minutosAnticipacion)),
        tz.local,
      );

      // Verificar si la fecha ya pasó
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      String tiempoAnticipacion = '';
      if (task.minutosAnticipacion >= 1440) {
        tiempoAnticipacion = '${task.minutosAnticipacion ~/ 1440} día(s)';
      } else if (task.minutosAnticipacion >= 60) {
        tiempoAnticipacion = '${task.minutosAnticipacion ~/ 60} hora(s)';
      } else {
        tiempoAnticipacion = '${task.minutosAnticipacion} minutos';
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        task.id.hashCode,
        '¡Tarea próxima a vencer!',
        'La tarea "${task.titulo}" vence en $tiempoAnticipacion.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminder_channel',
            'Task Reminders',
            channelDescription: 'Reminders for tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelTaskReminder(Task task) async {
    await _flutterLocalNotificationsPlugin.cancel(task.id.hashCode);
  }
}

