import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- REGLA DE NEGOCIO ---
  bool _isValidUniandesEmail(String email) {
    return email.trim().toLowerCase().endsWith('@uniandes.edu.co');
  }

  Future<bool> signUp(String email, String password) async {
    if (!_isValidUniandesEmail(email)) {
      _errorMessage = "Por seguridad, debes usar tu correo institucional (@uniandes.edu.co)";
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      _errorMessage = null; 
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "Ocurrió un error al registrarse.";
      _setLoading(false);
      return false;
    }
  }

  // --- FUNCIÓN DE LOGIN ---
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password
      );
      _errorMessage = null; // Limpiar errores si tuvo éxito
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      // Manejar error de Firebase (ej. usuario no existe o mala contraseña)
      _errorMessage = "Credenciales incorrectas. Intenta de nuevo.";
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}