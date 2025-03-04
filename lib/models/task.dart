class Task {
  String id;
  String titulo;
  String descripcion;
  DateTime fechaVencimiento;
  String categoria;
  String prioridad;
  bool completada;

  Task({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaVencimiento,
    required this.categoria,
    required this.prioridad,
    this.completada = false,
  });

  // Factory constructor para crear una tarea desde un mapa (útil para JSON)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      titulo: map['titulo'],
      descripcion: map['descripcion'],
      fechaVencimiento: DateTime.parse(map['fechaVencimiento']),
      categoria: map['categoria'],
      prioridad: map['prioridad'],
      completada: map['completada'] ?? false,
    );
  }

  // Método para convertir la tarea a un mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaVencimiento': fechaVencimiento.toIso8601String(),
      'categoria': categoria,
      'prioridad': prioridad,
      'completada': completada,
    };
  }
}
