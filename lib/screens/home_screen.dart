import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:organiz4t3/services/notification_service.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import 'create_task_screen.dart';
import 'edit_task_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'task_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final Future<void> Function(Task) updateTask;
  final Future<void> Function(String) deleteTask;

  const HomeScreen({
    Key? key,
    required this.userName,
    required this.updateTask,
    required this.deleteTask,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Task> tasks = [];
  String _currentUserName = '';

  String _selectedFilter = 'Pendientes';
  final List<String> _filters = ['Todas', 'Pendientes', 'Completadas'];

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final loadedTasks = await _firebaseService.getTasks();
    setState(() {
      tasks = loadedTasks;
    });
  }

  Future<void> _refreshUserName() async {
    final updatedName = await _firebaseService.getUserName();
    setState(() {
      _currentUserName = updatedName;
    });
  }

  List<Task> get filteredTasks {
    switch (_selectedFilter) {
      case 'Pendientes':
        return tasks.where((task) => !task.completada).toList();
      case 'Completadas':
        return tasks.where((task) => task.completada).toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          // Botón para editar perfil
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userId: userId),
                  ),
                );
                // Actualizar el nombre del usuario después de editar el perfil
                _refreshUserName();
              }
            },
          ),
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Encabezado con saludo y filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $_currentUserName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aquí están tus tareas para hoy',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                NotificationService().showTestNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notificación de prueba enviada'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Probar notificaciones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Lista de tareas
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadTasks();
                await _refreshUserName();
              },
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay tareas',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return TaskCard(
                          task: task,
                          onToggleComplete: () async {
                            task.completada = !task.completada;
                            await widget.updateTask(task);
                            setState(() {});
                          },
                          onDelete: () async {
                            await widget.deleteTask(task.id);
                            setState(() {
                              tasks.removeWhere((t) => t.id == task.id);
                            });
                          },
                          onEdit: (updatedTask) async {
                            await widget.updateTask(updatedTask);
                            setState(() {
                              final index = tasks.indexWhere((t) => t.id == updatedTask.id);
                              if (index != -1) {
                                tasks[index] = updatedTask;
                              }
                            });
                          },
                          // Añadir el nuevo callback:
                          onViewDetails: (task, result) async {
                            if (result == true) {
                              // Si se eliminó la tarea
                              await widget.deleteTask(task.id);
                              setState(() {
                                tasks.removeWhere((t) => t.id == task.id);
                              });
                            } else {
                              // Recargar las tareas para obtener cualquier cambio
                              _loadTasks();
                            }
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push<Task>(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTaskScreen(),
            ),
          );

          if (newTask != null) {
            await _firebaseService.addTask(newTask);
            _loadTasks();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Modifica la clase TaskCard para que reciba una función de callback adicional
// que maneje el resultado de la pantalla de detalles

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final Function(Task) onEdit;
  final Function(Task, bool?) onViewDetails; // Nueva función de callback

  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
    required this.onViewDetails,
  }) : super(key: key);

  // Método para mostrar el diálogo de confirmación
  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
      onDelete();
    }
  }

  Color _getPriorityColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    switch (task.prioridad.toLowerCase()) {
      case 'alta':
        return isDarkMode ? Colors.red[300]! : Colors.red[400]!;
      case 'media':
        return isDarkMode ? Colors.orange[300]! : Colors.orange[400]!;
      case 'baja':
        return isDarkMode ? Colors.green[300]! : Colors.green[400]!;
      default:
        return isDarkMode ? Colors.blue[300]! : Colors.blue[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final completedTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailsScreen(task: task),
              ),
            );
            
            // Llamar a la función de callback con el resultado
            onViewDetails(task, result as bool?);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Categoría
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.categoria,
                        style: TextStyle(
                          color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Prioridad
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(context).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Prioridad ${task.prioridad}',
                        style: TextStyle(
                          color: _getPriorityColor(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Menú de opciones
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white70 : Colors.grey[700]),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTaskScreen(task: task),
                            ),
                          ).then((updatedTask) {
                            if (updatedTask != null) {
                              onEdit(updatedTask);
                            }
                          });
                        } else if (value == 'delete') {
                          // Mostrar diálogo de confirmación antes de eliminar
                          _showDeleteConfirmationDialog(context);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text('Editar', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Título y checkbox
                Row(
                  children: [
                    Checkbox(
                      value: task.completada,
                      onChanged: (_) => onToggleComplete(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        task.titulo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: task.completada
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.completada ? completedTextColor : textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Descripción
                if (task.descripcion.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      task.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // Fecha
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM, yyyy').format(task.fechaVencimiento),
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
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

