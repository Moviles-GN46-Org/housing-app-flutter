import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  String? _isLookingForRoommate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linen,
      appBar: AppBar(
        title: const Text(
          'My Profile', 
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. Header Básico (Avatar y Nombre)
            const Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    // Reemplazado AppColors.bronze por el color directo
                    backgroundColor: Color(0xFFDA9958), 
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Bryan Orjuela',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Engineering Student',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // 2. Formulario de Roommate
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDA9958), // Color directo
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Are you looking for a roommate?',
                      style: TextStyle(fontSize: 16, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 10),
                    
                    // Opción YES
                    RadioListTile<String>(
                      title: const Text('Yes'),
                      value: 'Yes',
                      groupValue: _isLookingForRoommate,
                      activeColor: const Color(0xFFDA9958), // Color directo
                      onChanged: (value) {
                        setState(() {
                          _isLookingForRoommate = value;
                        });
                      },
                    ),
                    
                    // Opción NO
                    RadioListTile<String>(
                      title: const Text('No'),
                      value: 'No',
                      groupValue: _isLookingForRoommate,
                      activeColor: const Color(0xFFDA9958), // Color directo
                      onChanged: (value) {
                        setState(() {
                          _isLookingForRoommate = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // 3. Botón de Enviar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDA9958), // Color directo
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLookingForRoommate == null 
                          ? null 
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Response saved: $_isLookingForRoommate'),
                                  backgroundColor: const Color(0xFFDA9958), // Color directo
                                ),
                              );
                            },
                        child: const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}