import 'package:flutter/material.dart';
import '../common/custom_text_field.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'SignUp.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _forgotEmailFocusNode = FocusNode();

  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 30).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _forgotEmailFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? mail) {
    if (mail == null || mail.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[a-zA-Z]{2,7}$');
    if (!emailRegex.hasMatch(mail)) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Please enter your password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final authService = AuthService();
        final result = await authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        await StorageService.saveToken(result['token']);
        await StorageService.saveUserProfile(result['profile']);
        Provider.of<UserProfileProvider>(context, listen: false)
            .setUserProfile(result['profile']);
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_forgotFormKey.currentState?.validate() ?? false) {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': _forgotEmailController.text.trim()}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String tempPassword = data['temp_password'];

          // Show dialog with temporary password for 1 minute
          showDialog(
            context: context,
            barrierDismissible: false, // Prevent closing by tapping outside
            builder: (context) => AlertDialog(
              title: const Text('Temporary Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(
                    'Your temporary password is: $tempPassword',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text('This dialog will close in 1 minute. Select and copy the password.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close Now'),
                ),
              ],
            ),
          ).then((_) {
            // Do nothing after dialog is closed
          });

          // Automatically close the dialog after 1 minute
          Future.delayed(const Duration(minutes: 1), () {
            if (mounted) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          });
        } else {
          throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to send password reset email');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: Form(
          key: _forgotFormKey,
          child: TextFormField(
            controller: _forgotEmailController,
            focusNode: _forgotEmailFocusNode,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _forgotPassword,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LangBuddy'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned(top: _animation.value, left: _animation.value, child: _buildFadedLetter('A')),
              Positioned(top: 100 + _animation.value, right: 20 + _animation.value, child: _buildFadedLetter('あ')),
              Positioned(bottom: 100 - _animation.value, left: 20 + _animation.value, child: _buildFadedLetter('ب')),
              Positioned(bottom: 50 + _animation.value, right: 50 - _animation.value, child: _buildFadedLetter('文')),
              Positioned(top: 30 + _animation.value, right: 100 - _animation.value, child: _buildFadedLetter('अ')),
              Positioned(top: 200 - _animation.value, left: 80 + _animation.value, child: _buildFadedLetter('অ')),
              Positioned(bottom: 200 + _animation.value, right: 70 - _animation.value, child: _buildFadedLetter('ñ')),
              Positioned(top: 250 + _animation.value, left: 50 - _animation.value, child: _buildFadedLetter('é')),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, size: 80, color: Colors.blueAccent),
                        const SizedBox(height: 20),
                        Text(
                          'Login',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                        ),
                        const SizedBox(height: 30),
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          focusNode: _emailFocusNode,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          obscureText: _obscureText,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                          validator: _validatePassword,
                          focusNode: _passwordFocusNode,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _login,
                            child: const Text('Login', style: TextStyle(fontSize: 20, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                          child: const Text(
                            "Don't have an account? Sign Up",
                            style: TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFadedLetter(String letter) {
    return Opacity(
      opacity: 0.05,
      child: Text(letter, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }
}