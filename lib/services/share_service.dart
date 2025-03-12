import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class ShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Compartir tarea mediante el sistema nativo de compartir
  Future<void> shareTask(Task task, BuildContext context) async {
    try {
      // Crear un mensaje para compartir
      final String shareMessage = '''
        ¡Tenemos una tarea pendiente!

        Título: ${task.titulo}
        Descripción: ${task.descripcion}
        Fecha de vencimiento: ${_formatDate(task.fechaVencimiento)}
        ${task.horaVencimiento != null ? 'Hora: ${_formatTime(task.horaVencimiento!, context)}' : ''}
        Categoría: ${task.categoria}
        Prioridad: ${task.prioridad}

        Descarga la app "Organízate" para gestionar tus tareas de forma eficiente.
        ''';

      // Usar el plugin share_plus para compartir
      await Share.share(
        shareMessage,
        subject: 'Tarea compartida: ${task.titulo}',
      );
    } catch (e) {
      debugPrint('Error al compartir tarea: $e');
      rethrow;
    }
  }

  // Compartir tarea con otro usuario de la app
  Future<void> shareTaskWithUser(Task task, String recipientEmail) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Buscar al usuario destinatario por email
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: recipientEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Usuario no encontrado');
      }

      final String recipientId = userQuery.docs.first.id;
      
      // Crear una copia de la tarea para el destinatario
      final sharedTask = Task(
        id: task.id, // Mantener el mismo ID para referencia
        titulo: task.titulo,
        descripcion: task.descripcion,
        fechaVencimiento: task.fechaVencimiento,
        horaVencimiento: task.horaVencimiento,
        categoria: task.categoria,
        prioridad: task.prioridad,
        completada: false, // Siempre iniciar como no completada
        minutosAnticipacion: task.minutosAnticipacion,
      );

      // Guardar la tarea en la colección del destinatario
      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('tasks')
          .doc(task.id)
          .set({
        ...sharedTask.toMap(),
        'sharedBy': currentUser.uid,
        'sharedByEmail': currentUser.email,
        'sharedAt': FieldValue.serverTimestamp(),
      });

      // Opcional: Guardar un registro de la tarea compartida
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('sharedTasks')
          .doc(task.id)
          .set({
        'taskId': task.id,
        'sharedWith': recipientId,
        'sharedWithEmail': recipientEmail,
        'sharedAt': FieldValue.serverTimestamp(),
      });

      // Enviar notificación al destinatario (esto requeriría una implementación adicional)
      await _sendShareNotification(recipientId, task, currentUser.email ?? 'Un usuario');
    } catch (e) {
      debugPrint('Error al compartir tarea con usuario: $e');
      rethrow;
    }
  }

  // Enviar notificación al destinatario
  Future<void> _sendShareNotification(String recipientId, Task task, String senderEmail) async {
    try {
      // Obtener token de notificación del destinatario
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(recipientId)
          .get();
      
      final String? notificationToken = userDoc.get('notificationToken');
      
      if (notificationToken != null) {
        // Aquí implementarías el envío de la notificación push
        // Esto generalmente se hace a través de Cloud Functions o un backend
        debugPrint('Enviando notificación a: $recipientId con token: $notificationToken');
        
        // Ejemplo de estructura para Cloud Functions
        await _firestore.collection('notifications').add({
          'token': notificationToken,
          'title': 'Nueva tarea compartida',
          'body': '$senderEmail ha compartido la tarea "${task.titulo}" contigo',
          'data': {
            'taskId': task.id,
            'type': 'shared_task',
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error al enviar notificación: $e');
    }
  }

  // Verificar si un email está registrado en la app
  Future<bool> isUserRegistered(String email) async {
    try {
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return userQuery.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error al verificar usuario: $e');
      return false;
    }
  }

  // Formatear fecha
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Formatear hora
  String _formatTime(TimeOfDay time, BuildContext context) {
    return time.format(context);
  }
}

