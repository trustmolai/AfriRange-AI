import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_bloc.dart';
import '../../../core/auth/models/auth_event.dart';
import '../../../core/auth/models/auth_state.dart';
import '../../../shared/widgets/afri_button.dart';
import '../../../shared/widgets/afri_text_field.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onNavigateToRegister;
  final VoidCallback onNavigateToForgotPassword;

  const LoginScreen({
    super.key,
    required this.onNavigateToRegister,
    required this.onNavigateToForgotPassword,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthAuthenticating;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.eco, size: 64, color: Color(0xFF2E7D32)),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1C18)),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Log in to access your rangeland intelligence',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    AfriTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),
                    AfriTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (val) => val == null || val.length < 6 ? 'Password too short' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onNavigateToForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AfriButton(
                      label: 'LOG IN',
                      isLoading: isLoading,
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          context.read<AuthBloc>().add(
                            LoginEvent(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: widget.onNavigateToRegister,
                          child: const Text(
                            'Register',
                            style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
