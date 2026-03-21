import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // CAMBIA ESTO: 'localhost' para Web, '10.0.2.2' para Android
  final String baseUrl = "http://localhost:3000/api"; 

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );
      
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body)
      };
    } catch (e) {
      return {'statusCode': 500, 'error': e.toString()};
    }
  }
}