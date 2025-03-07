import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:organiz4t3/main.dart';
import 'package:organiz4t3/models/user.dart';
import 'package:organiz4t3/services/shared_preferences.dart';
import 'package:organiz4t3/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

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

  // Controladores de texto inicializados en initState
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _notificationsPreference = false;
  String _themePreference = 'light';
  // Listas de países (esto es un ejemplo, puedes obtener una lista dinámica si lo deseas)
  final List<String> _countries = ['Argentina', 'Colombia', 'México', 'Perú', 'Chile', 'Uruguay', 'Brasil', 'Venezuela'];
  String _selectedCountry = 'Colombia';

  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores de texto
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserProfile();
    _loadThemePreference(); // Cargar el tema guardado
  }

  Future<void> _loadUserProfile() async {
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) {
    print("Usuario no autenticado");
    return;
  }

  final user = await _firebaseService.getUserProfile(firebaseUser.uid);
    if (user != null) {
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _phoneController.text = user.phoneNumber;
        // Aquí actualizamos el país seleccionado con el valor de la base de datos
        _selectedCountry = user.location;  // Asignamos el país cargado del perfil
        _notificationsPreference = user.notificationsPreference;
        _themePreference = user.themePreference; // Usar la preferencia guardada
      });
    } else {
      print("No se encontró el perfil del usuario en Firestore");
    }
  }

  // Cargar preferencia de tema
  Future<void> _loadThemePreference() async {
    String theme = await ThemeService().getTheme();
    setState(() {
      _themePreference = theme;
    });
  }

  // Cambiar tema
  Future<void> _toggleTheme() async {
    String newTheme = _themePreference == 'light' ? 'dark' : 'light';
    await ThemeService().saveTheme(newTheme);
    setState(() {
      _themePreference = newTheme;
    });
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
      UserModel updatedUser = UserModel(
        id: _user!.id,
        name: _nameController.text,
        email: _user!.email, // No permitimos editar el email
        phoneNumber: _phoneController.text,
        birthDate: _user!.birthDate,
        notificationsPreference: _notificationsPreference,
        themePreference: _themePreference, // Guardamos la preferencia del tema
        location: _selectedCountry, // Usamos el país seleccionado en el Dropdown
        userType: _user!.userType,
      );

      await _firebaseService.updateUserProfile(updatedUser);
      Navigator.pop(context); // Volver al Home
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Cargar preferencia de tema
  Future<void> _loadThemePreference() async {
    String theme = await ThemeService().getTheme();
    setState(() {
      _themePreference = theme;
    });
  }

  // Cambiar tema
  Future<void> _toggleTheme() async {
    String newTheme = _themePreference == 'light' ? 'dark' : 'light';
    await ThemeService().saveTheme(newTheme);  // Guardar la preferencia en SharedPreferences
    setState(() {
      _themePreference = newTheme;
    });
    // Aplicar el tema globalmente
    final themeService = ThemeService();
    ThemeData themeData = themeService.getThemeData(newTheme);
    MaterialApp(
      theme: themeData,
    );
  }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),
              // App Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/app_icon.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Title
              Text(
                _nameController.text,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold,),
              ),
              const SizedBox(height: 16),   

              Text(
                'Edita tu perfil',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Ingrese su nombre' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: _validatePhoneNumber, // 
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
                  setState(() {
                    _selectedCountry = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Ubicación (País)'),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Notificaciones'),
                value: _notificationsPreference,
                onChanged: (value) {
                  setState(() {
                    _notificationsPreference = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _themePreference,
                items: ['light', 'dark'].map((theme) {
                  return DropdownMenuItem(
                    value: theme,
                    child: Text(theme == 'light' ? 'Claro' : 'Oscuro'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _themePreference = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Tema'),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Guardar'),
                ),
              ),
              const SizedBox(height: 24),
              // Dentro de cualquier parte de la app, como el botón de cambiar tema en el perfil
ElevatedButton(
  onPressed: () async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    String newTheme = themeProvider.theme == 'light' ? 'dark' : 'light';
    await themeProvider.saveTheme(newTheme); // Guardar el nuevo tema
  },
  child: const Text('Cambiar Tema'),
) 
            ],
          ),
        ),
      ),
    );
  }
}
