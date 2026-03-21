import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'map_screen.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("CasAndes Login")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email Uniandes")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 20),
            if (authVM.errorMessage != null) Text(authVM.errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            authVM.isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    bool success = await authVM.login(emailController.text, passwordController.text);
                    if (success && context.mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MapScreen()));
                    }
                  }, 
                  child: const Text("Entrar")
                ),
          ],
        ),
      ),
    );
  }
}