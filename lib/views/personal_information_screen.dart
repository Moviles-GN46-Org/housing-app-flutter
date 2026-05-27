import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../utils/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_client.dart'; 

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  bool _lookingForRoommate = false;

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preference saved: ${_lookingForRoommate ? 'Yes' : 'No'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linen,
      appBar: AppBar(
        // ... (Tu appbar se queda igual)
        backgroundColor: const Color(0xFFF7E6D5),
        elevation: 0,
        centerTitle: true,
        title: const Text('Personal Information', style: TextStyle(color: AppColors.deepMocha, fontSize: 20, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(LucideIcons.chevron_left, color: AppColors.dustyTaupe), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: AppShadows.card,
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: const Text('Looking for a roommate', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                subtitle: const Text('Show your profile to others seeking roommates', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                value: _lookingForRoommate,
                activeColor: AppColors.primary,
                
                onChanged: (value) async {
                  setState(() => _lookingForRoommate = value);
                  
                  if (value == true) {
                    try {
                      // 1. Verificamos permisos y obtenemos la ubicación real
                      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) throw Exception('Servicios de ubicación desactivados');

                      LocationPermission permission = await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                        if (permission == LocationPermission.denied) throw Exception('Permiso denegado');
                      }

                      // Tomamos la posición actual (baja precisión es suficiente y más rápida)
                      Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.low
                      );

                      // 2. Enviamos las coordenadas reales al backend
                      final response = await ApiClient().post('/analytics/roommate-update', data: {
                        'lat': position.latitude,
                        'lng': position.longitude
                      });
                      
                      debugPrint("¡Éxito! Analítica enviada: ${response.statusCode}");
                    } catch (e) {
                      // Si el usuario no da permiso de ubicación o hay error de red, no crashea
                      debugPrint("Error obteniendo ubicación o enviando analítica: $e");
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}