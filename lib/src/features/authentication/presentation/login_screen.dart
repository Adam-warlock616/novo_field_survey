import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controllers to capture user input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Key to validate the form (check if email is empty, etc.)
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // ALWAYS dispose controllers to free up memory (Junior Dev Interview Question!)
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      // Logic comes later. For now, print to console.
      print("Logging in with ${_emailController.text}");

      // TODO: Call the AuthRepository here
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the theme we defined earlier
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Clean White/Surface color
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Logo Section (Placeholder Icon for now)
                  Icon(
                    Icons.solar_power_outlined,
                    size: 100,
                    color: theme.colorScheme.primary, // Eco Green
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Novo Field Pro",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Technician Portal",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 2. Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Employee Email",
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(), // Standard box border
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true, // Hide password
                    decoration: const InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. Login Button
                  SizedBox(
                    height: 50, // Make button tall and touch-friendly
                    child: ElevatedButton(
                      onPressed: _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.secondary, // Solar Orange
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "LOGIN",
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
      ),
    );
  }
}
