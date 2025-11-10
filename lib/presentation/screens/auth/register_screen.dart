import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                )
                .animate()
                .fadeIn()
                .scale(),
                
                const SizedBox(height: 32),
                
                // Título
                Text(
                  'Crear Cuenta',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(delay: 200.ms),
                
                const SizedBox(height: 8),
                
                Text(
                  'Registrate para comenzar',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(delay: 300.ms),
                
                const SizedBox(height: 40),
                
                // Campo Primer Nombre
                TextFormField(
                  controller: _firstNameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Primer Nombre',
                    hintText: 'Juan',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu primer nombre';
                    }
                    if (value.length < 2) {
                      return 'Debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                )
                .animate()
                .fadeIn(delay: 400.ms)
                .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 16),
                
                // Campo Apellido
                TextFormField(
                  controller: _lastNameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    hintText: 'Perez',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu apellido';
                    }
                    if (value.length < 2) {
                      return 'Debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                )
                .animate()
                .fadeIn(delay: 450.ms)
                .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 16),
                
                // Campo Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electronico',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Ingresa un correo valido (ej: usuario@correo.com)';
                    }
                    final parts = value.split('@');
                    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
                      return 'Formato de correo invalido';
                    }
                    return null;
                  },
                )
                .animate()
                .fadeIn(delay: 500.ms)
                .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 16),
                
                // Campo Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contrasena';
                    }
                    if (value.length < 6) {
                      return 'Minimo 6 caracteres';
                    }
                    // Validación backend: mayúscula, minúscula, número o especial
                    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
                    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
                    bool hasDigitOrSpecial = value.contains(RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]'));
                    
                    if (!hasUppercase || !hasLowercase || !hasDigitOrSpecial) {
                      return 'Debe tener mayuscula, minuscula y numero/simbolo';
                    }
                    return null;
                  },
                )
                .animate()
                .fadeIn(delay: 600.ms)
                .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 8),
                
                // Requisitos de contraseña
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requisitos de contrasena:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildPasswordRequirement('Minimo 6 caracteres'),
                      _buildPasswordRequirement('Al menos una letra mayuscula'),
                      _buildPasswordRequirement('Al menos una letra minuscula'),
                      _buildPasswordRequirement('Al menos un numero o simbolo'),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 650.ms),
                
                const SizedBox(height: 16),
                
                // Campo Confirmar Contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contrasena',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contrasena';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contrasenas no coinciden';
                    }
                    return null;
                  },
                )
                .animate()
                .fadeIn(delay: 700.ms)
                .slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 24),
                
                // Mensaje de error
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _parseErrorMessage(_errorMessage!),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _errorMessage = null),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn()
                  .shake(),
                  const SizedBox(height: 16),
                ],
                
                // Botón Registrarse
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                )
                .animate()
                .fadeIn(delay: 800.ms)
                .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 24),
                
                // Ya tienes cuenta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ya tienes cuenta? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Inicia sesion',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: 900.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Combinar nombre completo para el backend
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      await authNotifier.register(
        name: fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );

      if (!mounted) return;

      final newState = ref.read(authNotifierProvider);

      if (newState.isAuthenticated) {
        // Inicializar datos post-registro
        if (mounted) {
          context.read<AppProvider>().initializeAfterLogin();
          // El GoRouter redirigirá automáticamente a /home
        }
      } else if (newState.error != null) {
        if (mounted) {
          setState(() {
            _errorMessage = newState.error;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al registrar: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildPasswordRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _parseErrorMessage(String error) {
    // Limpiar mensajes de error técnicos para el usuario
    if (error.contains('Exception:')) {
      error = error.replaceAll('Exception:', '').trim();
    }
    
    // Mensajes comunes del backend
    if (error.contains('email already exists') || error.contains('ya existe')) {
      return 'Este correo electronico ya esta registrado';
    }
    if (error.contains('password') && error.contains('weak')) {
      return 'La contrasena no cumple con los requisitos de seguridad';
    }
    if (error.contains('invalid email')) {
      return 'El formato del correo electronico es invalido';
    }
    if (error.contains('Network')) {
      return 'Error de conexion. Verifica tu internet';
    }
    
    // Si el error es muy largo, mostrar versión resumida
    if (error.length > 100) {
      return 'Error al registrar. Verifica tus datos e intenta nuevamente';
    }
    
    return error;
  }
}
