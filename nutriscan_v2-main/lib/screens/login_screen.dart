import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/auth_utils.dart';
import 'role_manager.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            // Vérifier le rôle de l'utilisateur
            String? role = await RoleManager.getUserRole(user);
            if (role == null) {
              _showErrorDialog('Role Error', 'No role assigned to this user.');
              return;
            }
            // Rediriger selon le rôle
            switch (role) {
              case RoleManager.ROLE_ADMIN:
                Navigator.pushNamed(context, '/admin');
                break;
              case RoleManager.ROLE_ENTERPRISE:
                Navigator.pushNamed(context, '/enterprise');
                break;
              case RoleManager.ROLE_USER:
              default:
                Navigator.pushNamed(context, '/scanner');
                break;
            }
          } else {
            _showErrorDialog(
              'Email not verified',
              'Please verify your email before logging in.',
            );
          }
        } else {
          _showErrorDialog('Login Failed', 'Invalid email or password.');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog('Login Failed', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
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
                Image.asset(
                  'assets/images/image.png',
                  width: 280,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 60),
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
                SizedBox(height: 24),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _login,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text('Login', style: TextStyle(fontSize: 16)),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed:
                        () => Navigator.pushNamed(context, '/reset'),
                    child: Text('Forgot Password?'),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?"),
                    TextButton(
                      onPressed:
                          () => Navigator.pushNamed(
                            context,
                            '/register',
                          ),
                      child: Text('Register'),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
