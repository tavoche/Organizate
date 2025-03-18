import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/share_service.dart';
import '../services/firebase_service.dart';
import 'edit_task_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final ShareService _shareService = ShareService();
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isUserRegistered = false;
  String _errorMessage = '';
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Verificar si el usuario está registrado
  Future<void> _checkUserRegistration(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _isUserRegistered = false;
        _errorMessage = 'Ingresa un correo electrónico válido';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final bool isRegistered = await _shareService.isUserRegistered(email);
      setState(() {
        _isUserRegistered = isRegistered;
        _errorMessage = isRegistered ? '' : 'Este usuario no está registrado en la app';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al verificar el usuario: $e';
      });
    }
  }

  // Compartir tarea con otro usuario
  Future<void> _shareTaskWithUser() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa un correo electrónico';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _shareService.shareTaskWithUser(_task, _emailController.text);
      if (mounted) {
        Navigator.pop(context); // Cerrar el diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea compartida exitosamente')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al compartir la tarea: $e';
      });
    }
  }

  // Mostrar diálogo para compartir con usuario específico
  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Compartir tarea'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'Ingresa el correo del destinatario',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    _checkUserRegistration(value);
                  },
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (_isUserRegistered)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      '✓ Usuario encontrado',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _isLoading || !_isUserRegistered
                    ? null
                    : _shareTaskWithUser,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Compartir'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Editar tarea
  Future<void> _editTask() async {
    final updatedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: _task),
      ),
    );

    if (updatedTask != null) {
      setState(() {
        _task = updatedTask;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea actualizada correctamente')),
      );
    }
  }

  // Eliminar tarea
  Future<void> _deleteTask() async {
    // Mostrar diálogo de confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text('¿Estás seguro de que deseas eliminar esta tarea? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.deleteTask(_task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea eliminada correctamente')),
          );
          Navigator.pop(context, true); // Volver a la pantalla anterior con resultado de eliminación
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar la tarea: $e')),
          );
        }
      }
    }
  }

  // Marcar tarea como completada/pendiente
  Future<void> _toggleTaskCompletion() async {
    try {
      setState(() {
        _task.completada = !_task.completada;
      });
      
      await _firebaseService.updateTask(_task);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_task.completada 
              ? 'Tarea marcada como completada' 
              : 'Tarea marcada como pendiente'
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la tarea: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la tarea'),
        actions: [
          // Botón para compartir
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Compartir con cualquier persona'),
                      subtitle: const Text('Envía un mensaje con los detalles de la tarea'),
                      onTap: () {
                        Navigator.pop(context);
                        _shareService.shareTask(_task, context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: const Text('Compartir con usuario de la app'),
                      subtitle: const Text('La tarea se añadirá a su lista de tareas'),
                      onTap: () {
                        Navigator.pop(context);
                        _showShareDialog();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          // Botón para editar
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editTask,
          ),
          // Botón para eliminar
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                _task.titulo,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Etiquetas (Categoría y Prioridad)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.category, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          _task.categoria,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(_task.prioridad).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: _getPriorityColor(_task.prioridad),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Prioridad ${_task.prioridad}',
                          style: TextStyle(
                            color: _getPriorityColor(_task.prioridad),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Descripción
              const Text(
                'Descripción',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _task.descripcion.isEmpty
                    ? 'Sin descripción'
                    : _task.descripcion,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Fecha y hora
              const Text(
                'Fecha y hora de vencimiento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, dd MMMM, yyyy').format(_task.fechaVencimiento),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              if (_task.horaVencimiento != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 8),
                    Text(
                      _task.horaVencimiento!.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              
              // Notificación
              if (_task.horaVencimiento != null) ...[
                const Text(
                  'Notificación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.notifications_active),
                    const SizedBox(width: 8),
                    Text(
                      _formatNotificationTime(_task.minutosAnticipacion),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              
              // Estado
              const Text(
                'Estado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _task.completada
                        ? Icons.check_circle
                        : Icons.pending_actions,
                    color: _task.completada ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _task.completada ? 'Completada' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 16,
                      color: _task.completada ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Botón para cambiar estado
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _toggleTaskCompletion,
                  icon: Icon(_task.completada ? Icons.refresh : Icons.check),
                  label: Text(_task.completada ? 'Marcar como pendiente' : 'Marcar como completada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _task.completada ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Obtener color según la prioridad
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  // Formatear tiempo de notificación
  String _formatNotificationTime(int minutes) {
    if (minutes >= 1440) {
      return '${minutes ~/ 1440} día(s) antes';
    } else if (minutes >= 60) {
      return '${minutes ~/ 60} hora(s) antes';
    } else {
      return '$minutes minutos antes';
    }
  }
}

