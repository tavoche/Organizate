import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({Key? key, required this.task}) : super(key: key);

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late DateTime _dueDate;
  late String _selectedCategory;
  late String _selectedPriority;
  TimeOfDay? _dueTime;
  bool _hasTime = false;
  int _notificationMinutes = 60; // Por defecto 1 hora antes
  
  final List<String> _categories = ['Personal', 'Trabajo', 'Estudio', 'Salud', 'Otro'];
  final List<String> _priorities = ['Baja', 'Media', 'Alta'];
  final List<Map<String, dynamic>> _notificationOptions = [
    {'label': '15 minutos antes', 'value': 15},
    {'label': '30 minutos antes', 'value': 30},
    {'label': '1 hora antes', 'value': 60},
    {'label': '2 horas antes', 'value': 120},
    {'label': '1 día antes', 'value': 1440},
    {'label': '2 días antes', 'value': 2880},
  ];

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.titulo;
    _descriptionController.text = widget.task.descripcion;
    _dueDate = widget.task.fechaVencimiento;
    _selectedCategory = widget.task.categoria;
    _selectedPriority = widget.task.prioridad;
    
    // Inicializar los nuevos campos
    _dueTime = widget.task.horaVencimiento;
    _hasTime = widget.task.horaVencimiento != null;
    _notificationMinutes = widget.task.minutosAnticipacion;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Tarea'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ingresa el título de la tarea',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Describe la tarea (opcional)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Fecha y hora de vencimiento
                Text(
                  'Fecha y hora de vencimiento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Fecha de vencimiento
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, dd MMMM, yyyy').format(_dueDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Opción para incluir hora
                SwitchListTile(
                  title: const Text('Incluir hora específica'),
                  subtitle: const Text('Activa para establecer una hora de vencimiento'),
                  value: _hasTime,
                  onChanged: (value) {
                    setState(() {
                      _hasTime = value;
                      if (value && _dueTime == null) {
                        _dueTime = TimeOfDay.now();
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                // Hora de vencimiento (solo si _hasTime es true)
                if (_hasTime) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 12),
                          Text(
                            _dueTime != null 
                                ? _dueTime!.format(context) 
                                : 'Seleccionar hora',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Tiempo de notificación anticipada
                  const SizedBox(height: 24),
                  Text(
                    'Notificar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<int>(
                      value: _notificationMinutes,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.notifications_active),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      iconSize: 24,
                      elevation: 16,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _notificationMinutes = newValue;
                          });
                        }
                      },
                      items: _notificationOptions.map<DropdownMenuItem<int>>((option) {
                        return DropdownMenuItem<int>(
                          value: option['value'],
                          child: Text(option['label']),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Categoría
                Text(
                  'Categoría',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.category),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconSize: 24,
                    elevation: 16,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                    items: _categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Prioridad
                Text(
                  'Prioridad',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _priorities.map((priority) {
                    return Expanded(
                      child: RadioListTile<String>(
                        title: Text(priority),
                        value: priority,
                        groupValue: _selectedPriority,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedPriority = value;
                            });
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                
                // Botón de guardar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final updatedTask = Task(
                          id: widget.task.id,
                          titulo: _titleController.text,
                          descripcion: _descriptionController.text,
                          fechaVencimiento: _dueDate,
                          horaVencimiento: _hasTime ? _dueTime : null,
                          categoria: _selectedCategory,
                          prioridad: _selectedPriority,
                          completada: widget.task.completada,
                          minutosAnticipacion: _hasTime ? _notificationMinutes : 60,
                        );
                        
                        await _firebaseService.updateTask(updatedTask);
                        Navigator.pop(context, updatedTask);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Guardar Cambios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

