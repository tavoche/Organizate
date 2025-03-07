import 'package:flutter/material.dart';

class Task {
  String id;
  String titulo;
  String descripcion;
  DateTime fechaVencimiento;
  TimeOfDay? horaVencimiento;
  String categoria;
  String prioridad;
  bool completada;
  int minutosAnticipacion; // Tiempo en minutos para notificar antes del vencimiento

  Task({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaVencimiento,
    this.horaVencimiento,
    required this.categoria,
    required this.prioridad,
    this.completada = false,
    this.minutosAnticipacion = 60, // Por defecto 1 hora antes
  });

  // Factory constructor para crear una tarea desde un mapa (útil para JSON)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      titulo: map['titulo'],
      descripcion: map['descripcion'],
      fechaVencimiento: DateTime.parse(map['fechaVencimiento']),
      horaVencimiento: map['horaVencimiento'] != null 
          ? TimeOfDay(
              hour: map['horaVencimiento']['hour'], 
              minute: map['horaVencimiento']['minute']
            ) 
          : null,
      categoria: map['categoria'],
      prioridad: map['prioridad'],
      completada: map['completada'] ?? false,
      minutosAnticipacion: map['minutosAnticipacion'] ?? 60,
    );
  }

  // Método para convertir la tarea a un mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaVencimiento': fechaVencimiento.toIso8601String(),
      'horaVencimiento': horaVencimiento != null 
          ? {
              'hour': horaVencimiento!.hour,
              'minute': horaVencimiento!.minute
            } 
          : null,
      'categoria': categoria,
      'prioridad': prioridad,
      'completada': completada,
      'minutosAnticipacion': minutosAnticipacion,
    };
  }

  // Método para obtener la fecha y hora completa de vencimiento
  DateTime? getFechaHoraVencimiento() {
    if (horaVencimiento == null) return fechaVencimiento;
    
    return DateTime(
      fechaVencimiento.year,
      fechaVencimiento.month,
      fechaVencimiento.day,
      horaVencimiento!.hour,
      horaVencimiento!.minute,
    );
  }
}

