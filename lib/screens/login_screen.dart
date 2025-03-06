import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:organiz4t3/screens/forgot_password_screen.dart';
import 'package:organiz4t3/screens/register_screen.dart';
import 'package:organiz4t3/services/firebase_service.dart';
import 'package:organiz4t3/widgets/social_login_button.dart';
import '../services/auth_service.dart'; // Importa la pantalla de registro
import 'home_screen.dart'; // Importa la pantalla de registro
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();

}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = await _firebaseService.signIn(
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (user != null) {
            // Obtener el nombre de usuario del perfil de Firebase
            String userName = await _firebaseService.getUserName();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  userName: userName,
                  updateTask: _firebaseService.updateTask,
                  deleteTask: _firebaseService.deleteTask,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al iniciar sesión. Verifica tus credenciales.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _loginWithGoogle() async {
    UserCredential? userCredential = await _auth.signInWithGoogle();
    User? user = userCredential?.user; // Extrae el usuario de UserCredential
    if (user != null) {
    // Obtener el nombre de usuario del perfil de Firebase
      String userName = await _firebaseService.getUserName();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen(
                userName: userName,
                updateTask: _firebaseService.updateTask,
                deleteTask: _firebaseService.deleteTask,
              ),
        ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar sesión. Verifica tus credenciales.')),
      );
    }
  }

  void _loginWithFacebook() async {
    UserCredential? userCredential = await _auth.signInWithFacebook();
    User? user = userCredential?.user; // Extrae el usuario de UserCredential
    if (user != null) {
    // Obtener el nombre de usuario del perfil de Firebase
      String userName = await _firebaseService.getUserName();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen(
                userName: userName,
                updateTask: _firebaseService.updateTask,
                deleteTask: _firebaseService.deleteTask,
              ),
        ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar sesión. Verifica tus credenciales.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  // esto es para ver que hace
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Bienvenido',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold,),
                  ),
                  const SizedBox(height: 40),

                  // es para ver que se muestra                  
                  Text(
                    'Inicia sesión para continuar',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Email Field
                  _buildEmailField(),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildPasswordField(),
                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                      },
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Login Button
                  _buildLoginButton(),
                  const SizedBox(height: 16),

                  // Register Button
                  _buildRegisterButton(),
                  const SizedBox(height: 32),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Por favor ingresa tu correo';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Correo inválido';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
        if (value.length < 6) return 'Debe tener al menos 6 caracteres';
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        child: _isLoading? const CircularProgressIndicator(color: Colors.white): const Text('Iniciar Sesión'),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()),);
        },
        child: const Text('Registrarse'),
      ),
    );
  }
}

