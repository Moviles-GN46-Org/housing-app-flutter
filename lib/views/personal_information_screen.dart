import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../utils/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_client.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  bool _lookingForRoommate = false;
  late Box _prefsBox; // Declaramos la caja

  @override
  void initState() {
    super.initState();
    // 1. Cargamos la caja de preferencias
    _prefsBox = Hive.box('user_prefs');
    // 2. Leemos el último valor guardado (si no hay nada, por defecto es false)
    _lookingForRoommate = _prefsBox.get('isLookingForRoommate', defaultValue: false);
  }

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
        backgroundColor: const Color(0xFFF7E6D5),
        elevation: 0,
        centerTitle: true,
        title: const Text('Personal Information',
            style: TextStyle(
                color: AppColors.deepMocha,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
            icon: const Icon(LucideIcons.chevron_left,
                color: AppColors.dustyTaupe),
            onPressed: () => Navigator.of(context).pop()),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: const Text('Looking for a roommate',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                subtitle: const Text(
                    'Show your profile to others seeking roommates',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textMuted)),
                value: _lookingForRoommate, // Valor amarrado al estado actual
                activeColor: AppColors.primary,
                onChanged: (value) async {
                  // 1. Actualizamos la UI inmediatamente
                  setState(() => _lookingForRoommate = value);

                  // 2. MAGIA DE PERSISTENCIA: Guardamos la elección localmente en disco
                  await _prefsBox.put('isLookingForRoommate', value);

                  // 3. Si lo prendió, enviamos el "+1" al dashboard
                  if (value == true) {
                    try {
                      bool serviceEnabled =
                          await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        throw Exception('Servicios de ubicación desactivados');
                      }

                      LocationPermission permission =
                          await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                        if (permission == LocationPermission.denied) {
                          throw Exception('Permiso denegado');
                        }
                      }

                      Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.low);

                      final response = await ApiClient()
                          .post('/analytics/roommate-update', data: {
                        'lat': position.latitude,
                        'lng': position.longitude
                      });

                      debugPrint(
                          "¡Éxito! Analítica enviada: ${response.statusCode}");
                    } catch (e) {
                      debugPrint(
                          "Error obteniendo ubicación o enviando analítica: $e");
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