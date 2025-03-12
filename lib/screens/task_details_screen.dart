import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/share_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final ShareService _shareService = ShareService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isUserRegistered = false;
  String _errorMessage = '';

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
      await _shareService.shareTaskWithUser(widget.task, _emailController.text);
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
                        _shareService.shareTask(widget.task, context);
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
                widget.task.titulo,
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
                          widget.task.categoria,
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
                      color: _getPriorityColor(widget.task.prioridad).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: _getPriorityColor(widget.task.prioridad),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Prioridad ${widget.task.prioridad}',
                          style: TextStyle(
                            color: _getPriorityColor(widget.task.prioridad),
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
                widget.task.descripcion.isEmpty
                    ? 'Sin descripción'
                    : widget.task.descripcion,
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
                    DateFormat('EEEE, dd MMMM, yyyy').format(widget.task.fechaVencimiento),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              if (widget.task.horaVencimiento != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 8),
                    Text(
                      widget.task.horaVencimiento!.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              
              // Notificación
              if (widget.task.horaVencimiento != null) ...[
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
                      _formatNotificationTime(widget.task.minutosAnticipacion),
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
                    widget.task.completada
                        ? Icons.check_circle
                        : Icons.pending_actions,
                    color: widget.task.completada ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.task.completada ? 'Completada' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.task.completada ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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

