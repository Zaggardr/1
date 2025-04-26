import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/auth_utils.dart';
import 'role_manager.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = RoleManager.ROLE_USER;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        print('Starting registration process');
        final (user, error) = await _authService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          role: _selectedRole,
        );

        print('Registration result: user=${user?.email}, error=$error');
        setState(() => _isLoading = false);
        if (user != null) {
          final (emailSent, emailError) = await _authService
              .sendEmailVerification(user);
          if (emailSent) {
            print('Showing verification dialog');
            showDialog(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: Text('Verification Email Sent'),
                    content: Text(
                      'A verification link has been sent to your email. Please verify to continue.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
            );
          } else {
            print('Email verification failed: $emailError');
            _showErrorDialog(
              'Email Verification Failed',
              emailError ?? 'Unknown error',
            );
          }
        } else {
          print('Registration failed: $error');
          String errorMessage =
              error ?? 'Unable to register user. Please try again.';
          if (error != null && error.contains('permission-denied')) {
            errorMessage = 'Permission denied. Please check Firestore rules.';
          } else if (error != null &&
              (error.contains('network') || error.contains('timed out'))) {
            errorMessage =
                'Unable to connect to the server. Please check your internet or try again later.';
          } else if (error != null && error.contains('offline')) {
            errorMessage =
                'Operation queued offline. Please reconnect to sync data.';
          }
          _showErrorDialog('Registration Failed', errorMessage);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        print('Unexpected error in registration: $e');
        _showErrorDialog('Registration Failed', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    print('Showing error dialog: $title - $message');
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60),
                Image.asset(
                  'assets/images/image.png',
                  width: 280,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 40),
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Fill in your details to register',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: AuthValidators.validateName,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  validator: AuthValidators.validateCity,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: AuthValidators.validateEmail,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: AuthValidators.validatePassword,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator:
                      (value) => AuthValidators.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: RoleManager.ROLE_USER,
                      child: Text('Utilisateur'),
                    ),
                    DropdownMenuItem(
                      value: RoleManager.ROLE_ENTERPRISE,
                      child: Text('Entreprise'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                  validator:
                      (value) => value == null ? 'Please select a role' : null,
                ),
                SizedBox(height: 24),
                _isLoading
                    ? Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Registering, please wait... (Offline mode may be active)',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                    : ElevatedButton(
                      onPressed: _register,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text('Register', style: TextStyle(fontSize: 16)),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?"),
                    TextButton(
                      onPressed:
                          () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                      child: Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
