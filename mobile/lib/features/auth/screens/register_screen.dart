import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_bloc.dart';
import '../../../core/auth/models/auth_event.dart';
import '../../../core/auth/models/auth_state.dart';
import '../../../shared/widgets/afri_button.dart';
import '../../../shared/widgets/afri_text_field.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;

  const RegisterScreen({super.key, required this.onNavigateToLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
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
                    const Text(
                      'Join AfriRange AI',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Empowering African livestock & veld management'),
                    const SizedBox(height: 24),
                    AfriTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (val) => val == null || val.isEmpty ? 'Enter your full name' : null,
                    ),
                    const SizedBox(height: 16),
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
                      hint: 'Min 8 chars, 1 uppercase, 1 number',
                      validator: (val) {
                        if (val == null || val.length < 8) return 'Minimum 8 characters';
                        if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Must contain 1 uppercase letter';
                        if (!RegExp(r'[0-9]').hasMatch(val)) return 'Must contain 1 number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _acceptedTerms,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF2E7D32),
                      title: const Text(
                        'I accept the Privacy Policy and Terms of Service.',
                        style: TextStyle(fontSize: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _acceptedTerms = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AfriButton(
                      label: 'CREATE ACCOUNT',
                      isLoading: isLoading,
                      onPressed: () {
                        if (!_acceptedTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You must accept the Privacy Policy and Terms of Service to register.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        if (_formKey.currentState?.validate() ?? false) {
                          context.read<AuthBloc>().add(
                            RegisterEvent(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                              fullName: _nameController.text.trim(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainCenterAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        GestureDetector(
                          onTap: widget.onNavigateToLogin,
                          child: const Text(
                            'Log in',
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

