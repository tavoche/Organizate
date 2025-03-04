import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final CollectionReference tareasCollection = FirebaseFirestore.instance.collection('tareas');

  // Crear tarea
  // En firestore_service.dart
  Future<DocumentReference> crearTarea(String titulo, String descripcion, String categoria, String prioridad, DateTime? fechaVencimiento, TimeOfDay? horaVencimiento) async {
    return await tareasCollection.add({
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'prioridad': prioridad,
      'completada': false,
      'fechaVencimiento': fechaVencimiento,
      'horaVencimiento': horaVencimiento != null ? TimeOfDay(hour: horaVencimiento.hour, minute: horaVencimiento.minute).toString() : null, // Convertir TimeOfDay a String
    });
  }

  // Obtener tareas
  Stream<QuerySnapshot> getTareas() {
    return tareasCollection.snapshots();
  }

  // Actualizar tarea
  Future<void> actualizarTarea(String id, String titulo, String descripcion, String categoria, String prioridad, bool completada, DateTime? fechaVencimiento, TimeOfDay? horaVencimiento) async {
    return await tareasCollection.doc(id).update({
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'prioridad': prioridad,
      'completada': completada,
      'fechaVencimiento': fechaVencimiento,
      'horaVencimiento': horaVencimiento != null ? TimeOfDay(hour: horaVencimiento.hour, minute: horaVencimiento.minute).toString() : null, // Convertir TimeOfDay a String
    });
  }

  // Eliminar tarea
  Future<void> eliminarTarea(String id) async {
    return await tareasCollection.doc(id).delete();
  }
}