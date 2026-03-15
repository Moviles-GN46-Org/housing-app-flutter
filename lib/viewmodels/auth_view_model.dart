import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // Importa esto

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Instancia de Analytics para el Pipeline de la Wiki
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

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
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(), 
        password: password
      );

      await _analytics.logSignUp(signUpMethod: 'email');
      await _analytics.logEvent(
        name: 'registration_complete',
        parameters: {'domain': 'uniandes.edu.co'},
      );
      
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

      // --- EVENTO DE ANALYTICS ---
      // Registramos el login para medir retención de usuarios
      await _analytics.logLogin(loginMethod: 'email');

      _errorMessage = null; 
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
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