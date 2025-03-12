import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      debugPrint('NotificationService ya inicializado');
      return;
    }

    debugPrint('Inicializando NotificationService...');
    
    // Inicializar timezone
    tz_data.initializeTimeZones();
    debugPrint('Zonas horarias inicializadas');

    // Configurar notificaciones locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuración específica para iOS
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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notificación seleccionada: ${response.payload}');
        // Aquí puedes manejar la navegación cuando se toca una notificación
      },
    );
    debugPrint('Plugin de notificaciones locales inicializado');

    // Solicitar permisos para notificaciones
    if (Platform.isIOS) {
      debugPrint('Solicitando permisos para iOS...');
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      debugPrint('Permisos de iOS: $result');
    } else if (Platform.isAndroid) {
      debugPrint('Configurando canal de notificaciones para Android...');
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Crear canales de notificación para Android 8.0+
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_channel',
            'Task Notifications',
            description: 'Notifications for tasks',
            importance: Importance.max,
          ),
        );
        
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_reminder_channel',
            'Task Reminders',
            description: 'Reminders for tasks',
            importance: Importance.max,
          ),
        );
        
        debugPrint('Canales de notificación creados para Android');
      }
    }

    // Solicitar permisos para notificaciones push
    debugPrint('Solicitando permisos para notificaciones push...');
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Estado de autorización: ${settings.authorizationStatus}');

    // Configurar manejadores de mensajes
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    debugPrint('Manejadores de mensajes configurados');
    
    // Verificar si la app fue abierta desde una notificación
    final NotificationAppLaunchDetails? launchDetails =
        await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      debugPrint('La app fue abierta desde una notificación: ${launchDetails.notificationResponse?.payload}');
    }
    
    _initialized = true;
    debugPrint('NotificationService inicializado completamente');
    
    // Mostrar una notificación de prueba al iniciar
    if (kDebugMode) {
      await Future.delayed(const Duration(seconds: 2));
      await showTestNotification();
    }
  }

  Future<String?> getToken() async {
    final token = await _firebaseMessaging.getToken();
    debugPrint('Token FCM: $token');
    return token;
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('Mensaje recibido mientras la app está en primer plano: ${message.notification?.title}');
    _showNotification(
      message.notification?.title ?? 'Nueva notificación',
      message.notification?.body ?? '',
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Mensaje abierto desde la notificación: ${message.notification?.title}');
    // Aquí puedes navegar a una pantalla específica si es necesario
  }

  Future<void> _showNotification(String title, String body, {String? payload}) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'task_channel',
        'Task Notifications',
        channelDescription: 'Notifications for tasks',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      final id = DateTime.now().millisecond;
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
      debugPrint('Notificación mostrada con ID $id: $title - $body');
    } catch (e) {
      debugPrint('Error al mostrar notificación: $e');
    }
  }

  // Método para probar notificaciones inmediatas
  Future<void> showTestNotification() async {
    debugPrint('Mostrando notificación de prueba...');
    await _showNotification(
      'Notificación de prueba',
      'Esta es una notificación de prueba para verificar la configuración',
      payload: 'test_notification',
    );
    debugPrint('Notificación de prueba enviada');
  }

  Future<void> scheduleTaskReminder(Task task) async {
    try {
      debugPrint('Programando recordatorio para tarea: ${task.titulo}');
      
      // Si la tarea no tiene hora específica, programar para el día anterior
      if (task.horaVencimiento == null) {
        final scheduledDate = tz.TZDateTime.from(
          task.fechaVencimiento.subtract(const Duration(days: 1)),
          tz.local,
        );

        // Verificar si la fecha ya pasó
        if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
          debugPrint('La fecha de notificación ya pasó, no se programará: ${task.titulo}');
          return;
        }

        debugPrint('Programando notificación para: ${scheduledDate.toString()} - ${task.titulo}');
        
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
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'task_${task.id}',
        );
        
        debugPrint('Notificación programada exitosamente para: ${scheduledDate.toString()}');
      } else {
        // Si la tarea tiene hora específica, programar según los minutos de anticipación
        final DateTime? fechaHoraVencimiento = task.getFechaHoraVencimiento();
        
        if (fechaHoraVencimiento == null) {
          debugPrint('Error: No se pudo obtener la fecha y hora de vencimiento para: ${task.titulo}');
          return;
        }
        
        final scheduledDate = tz.TZDateTime.from(
          fechaHoraVencimiento.subtract(Duration(minutes: task.minutosAnticipacion)),
          tz.local,
        );

        // Verificar si la fecha ya pasó
        if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
          debugPrint('La fecha de notificación ya pasó, no se programará: ${task.titulo}');
          // Programar para 1 minuto después como prueba si estamos en modo debug
          if (kDebugMode) {
            final testDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
            debugPrint('MODO DEBUG: Programando notificación de prueba para 1 minuto después: ${testDate.toString()}');
            
            await _flutterLocalNotificationsPlugin.zonedSchedule(
              task.id.hashCode,
              '¡Notificación de prueba!',
              'La tarea "${task.titulo}" (prueba de notificación)',
              testDate,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'task_reminder_channel',
                  'Task Reminders',
                  channelDescription: 'Reminders for tasks',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'task_${task.id}',
            );
            
            debugPrint('Notificación de prueba programada para: ${testDate.toString()}');
          }
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

        debugPrint('Programando notificación para: ${scheduledDate.toString()} - ${task.titulo} (${tiempoAnticipacion} antes)');
        
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
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'task_${task.id}',
        );
        
        debugPrint('Notificación programada exitosamente para: ${scheduledDate.toString()}');
      }
    } catch (e) {
      debugPrint('Error al programar notificación: $e');
    }
  }

  Future<void> cancelTaskReminder(Task task) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(task.id.hashCode);
      debugPrint('Notificación cancelada para la tarea: ${task.titulo}');
    } catch (e) {
      debugPrint('Error al cancelar notificación: $e');
    }
  }
}

