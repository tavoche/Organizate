// screens/editar_tarea_screen.dart
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class EditarTareaScreen extends StatefulWidget {
  final String id;
  final String titulo;
  final String descripcion;
  final bool completada;
  final String categoria;
  final String prioridad;
  final DateTime? fechaVencimiento;
  final TimeOfDay? horaVencimiento;

  const EditarTareaScreen({super.key, 
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.completada,
    required this.categoria,
    required this.prioridad,
    this.fechaVencimiento,
    this.horaVencimiento,
  });

  @override
  _EditarTareaScreenState createState() => _EditarTareaScreenState();
}

class _EditarTareaScreenState extends State<EditarTareaScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  late String titulo;
  late String descripcion;
  late bool completada;
  late String categoria;
  late String prioridad;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    titulo = widget.titulo;
    descripcion = widget.descripcion;
    completada = widget.completada;
    categoria = widget.categoria;
    prioridad = widget.prioridad;
    _selectedDate = widget.fechaVencimiento;
    _selectedTime = widget.horaVencimiento;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Tarea')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: titulo,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (val) => val!.isEmpty ? 'Ingresa el título' : null,
                onChanged: (val) => titulo = val,
              ),
              TextFormField(
                initialValue: descripcion,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (val) => val!.isEmpty ? 'Ingresa la descripción' : null,
                onChanged: (val) => descripcion = val,
              ),
              TextFormField(
                initialValue: categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                onChanged: (val) => categoria = val,
              ),
              DropdownButtonFormField<String>(
                value: prioridad,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: ['Baja', 'Media', 'Alta']
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => prioridad = val!),
              ),
              CheckboxListTile(
                title: const Text("Completada"),
                value: completada,
                onChanged: (bool? value) {
                  setState(() {
                    completada = value!;
                  });
                },
              ),
              ListTile(
                title: Text(_selectedDate == null ? 'Selecciona la fecha de vencimiento' : DateFormat.yMd().format(_selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text(_selectedTime == null ? 'Selecciona la hora de vencimiento' : _selectedTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              ElevatedButton(
                child: const Text('Actualizar'),
                onPressed: () {
                  if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
                    _firestoreService.actualizarTarea(
                      widget.id,
                      titulo,
                      descripcion,
                      categoria,
                      prioridad,
                      completada,
                      _selectedDate,
                      _selectedTime,
                    );
                    DateTime scheduledTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );
                    /*_notificationService.showNotification(
                      1,
                      'Tarea: $titulo',
                      'La tarea "$titulo" vence pronto.',
                      scheduledTime.difference(DateTime.now()).inSeconds,
                    );*/
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}