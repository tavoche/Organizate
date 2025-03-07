import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../services/shared_preferences.dart';
import '../theme/theme_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  UserModel? _user;
  bool _isLoading = false;

  // Controladores de texto inicializados en initState
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _notificationsPreference = false;
  String _themePreference = 'light';
  
  // Lista de países
  final List<String> _countries = ['Argentina', 'Colombia', 'México', 'Perú', 'Chile', 'Uruguay', 'Brasil', 'Venezuela'];
  String _selectedCountry = 'Colombia';

  // Lista de profesiones/tipos de usuario
  final List<String> _professions = ['student', 'employee', 'other'];
  String _selectedProfession = 'student';

  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores de texto
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      print("Usuario no autenticado");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final user = await _firebaseService.getUserProfile(firebaseUser.uid);
      if (user != null) {
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _phoneController.text = user.phoneNumber;
          
          // Verificar si el país existe en la lista
          if (_countries.contains(user.location)) {
            _selectedCountry = user.location;
          }
          
          // Verificar si la profesión existe en la lista
          if (_professions.contains(user.userType)) {
            _selectedProfession = user.userType;
          }
          
          _notificationsPreference = user.notificationsPreference;
          
          // Verificar si el tema es válido
          if (['light', 'dark', 'system'].contains(user.themePreference)) {
            _themePreference = user.themePreference;
          }
        });
      } else {
        print("No se encontró el perfil del usuario en Firestore");
        // Crear un perfil de usuario predeterminado si no existe
        _createDefaultUserProfile(firebaseUser);
      }
    } catch (e) {
      print("Error al cargar el perfil: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultUserProfile(User firebaseUser) async {
    try {
      final defaultUser = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Usuario',
        email: firebaseUser.email ?? '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
        birthDate: DateTime.now(),
        notificationsPreference: true,
        themePreference: 'light',
        location: 'Colombia',
        userType: 'student',
      );
      
      await _firebaseService.createUserProfile(defaultUser);
      
      setState(() {
        _user = defaultUser;
        _nameController.text = defaultUser.name;
        _phoneController.text = defaultUser.phoneNumber;
        _selectedCountry = defaultUser.location;
        _selectedProfession = defaultUser.userType;
        _notificationsPreference = defaultUser.notificationsPreference;
        _themePreference = defaultUser.themePreference;
      });
      
    } catch (e) {
      print("Error al crear perfil predeterminado: $e");
    }
  }

  // Validación para el número de teléfono
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un número de teléfono';
    }
    // Solo aceptar números y exactamente 10 dígitos
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'El número de teléfono debe tener 10 dígitos';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // 1. Actualizar el modelo de usuario
        UserModel updatedUser = UserModel(
          id: _user!.id,
          name: _nameController.text,
          email: _user!.email,
          phoneNumber: _phoneController.text,
          birthDate: _user!.birthDate,
          notificationsPreference: _notificationsPreference,
          themePreference: _themePreference,
          location: _selectedCountry,
          userType: _selectedProfession,
        );

        // 2. Guardar en Firebase
        await _firebaseService.updateUserProfile(updatedUser);
        
        // 3. Actualizar el tema si ha cambiado
        if (_themePreference != _user!.themePreference) {
          // Actualizar el tema usando el Provider
          final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
          await themeProvider.saveTheme(_themePreference);
        }
        
        // 4. Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
          Navigator.pop(context); // Volver al Home
        }
      } catch (e) {
        print("Error al guardar el perfil: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el perfil: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(
          child: Text('No se pudo cargar el perfil. Intente nuevamente.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // App Icon o Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Nombre del usuario
                Text(
                  _nameController.text,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Edita tu perfil',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Campos de formulario
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingrese su nombre' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: _validatePhoneNumber,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  items: _countries.map((country) {
                    return DropdownMenuItem(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCountry = value;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'País',
                    prefixIcon: const Icon(Icons.public),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedProfession,
                  items: _professions.map((profession) {
                    return DropdownMenuItem(
                      value: profession,
                      child: Row(
                            children: [
                              Icon(
                                profession == 'student' 
                                  ? Icons.school 
                                  : profession == 'employee' 
                                    ? Icons.work 
                                    : Icons.person,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                profession == 'student' 
                                  ? 'Estudiante' 
                                  : profession == 'employee' 
                                    ? 'Empleado' 
                                    : 'Otro'
                              ),
                            ],
                          ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedProfession = value;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Profesión',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Preferencias
                Text(
                  'Preferencias',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Recibir notificaciones'),
                  subtitle: const Text('Mantente al día con tus tareas'),
                  value: _notificationsPreference,
                  onChanged: (value) {
                    setState(() {
                      _notificationsPreference = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _themePreference,
                  items: [
                    DropdownMenuItem(
                      value: 'light',
                      child: Row(
                        children: const [
                          Icon(Icons.light_mode, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Tema Claro'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'dark',
                      child: Row(
                        children: const [
                          Icon(Icons.dark_mode, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text('Tema Oscuro'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'system',
                      child: Row(
                        children: const [
                          Icon(Icons.settings_suggest, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Tema del Sistema'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _themePreference = value;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Tema de la aplicación',
                    prefixIcon: const Icon(Icons.color_lens_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Botón de guardar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
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

