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
    return Scaffold(
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay tareas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
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
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final Function(Task) onEdit;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  Color _getPriorityColor() {
    switch (task.prioridad.toLowerCase()) {
      case 'alta':
        return Colors.red[400]!;
      case 'media':
        return Colors.orange[400]!;
      case 'baja':
        return Colors.green[400]!;
      default:
        return Colors.blue[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(task: task),
            ),
          );
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
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.categoria,
                      style: TextStyle(
                        color: Colors.blue[700],
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
                      color: _getPriorityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Prioridad ${task.prioridad}',
                      style: TextStyle(
                        color: _getPriorityColor(),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Menú de opciones
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
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
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar'),
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
                        color: task.completada ? Colors.grey : Colors.black87,
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
                      color: Colors.grey[600],
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
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM, yyyy').format(task.fechaVencimiento),
                      style: TextStyle(
                        color: Colors.grey[600],
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
    );
  }
}

