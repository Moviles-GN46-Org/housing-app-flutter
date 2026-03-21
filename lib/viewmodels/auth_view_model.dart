import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _token;
  String? get token => _token;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    print("🔑 [AuthViewModel] Intentando login para: $email");
    final result = await _apiService.login(email, password);

    if (result['statusCode'] == 200 || result['statusCode'] == 201) {
      // --- EL ARREGLO ESTÁ AQUÍ ---
      // David manda: { "success": true, "data": { "accessToken": "...", "user": {...} } }
      final fullBody = result['data']; 
      
      if (fullBody['success'] == true) {
        _token = fullBody['data']['accessToken']; // Entramos a data -> accessToken
        
        print("✅ [AuthViewModel] TOKEN GUARDADO EXITOSAMENTE: ${_token?.substring(0, 10)}...");
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Error en el formato de respuesta de David";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } else {
      _errorMessage = "Credenciales incorrectas o servidor caído";
      print("❌ [AuthViewModel] Error en login: ${result['statusCode']}");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Método para cerrar sesión y limpiar el token
  void logout() {
    _token = null;
    notifyListeners();
  }
}