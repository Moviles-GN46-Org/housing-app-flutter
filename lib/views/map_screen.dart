import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../viewmodels/map_view_model.dart';
import '../models/property_model.dart';
import '../utils/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().initializeMap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapViewModel = context.watch<MapViewModel>();
    
    final Color primaryColor = AppColors.lightBronze;
    final Color darkColor = AppColors.dustyTaupe;
    final Color backgroundColor = AppColors.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(4.6020, -74.0650),
              initialZoom: 13.0,

              onMapReady: () {
                if (mapViewModel.userLocation != null) {
                  _mapController.move(mapViewModel.userLocation!, 14.0);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.uniandes.housing_app',
              ),
              MarkerLayer(
                markers: [

                  if (mapViewModel.userLocation != null)
                    Marker(
                      point: mapViewModel.userLocation!,
                      width: 60,
                      height: 60,
                      child: _buildUserLocationMarker(),
                    ),
                  
                  ...mapViewModel.properties.map((p) => Marker(
                    point: LatLng(p.latitude, p.longitude),
                    width: 45,
                    height: 45,
                    child: Icon(
                      LucideIcons.map_pin,
                      color: primaryColor, 
                      size: 35
                    ),
                  )),
                ],
              ),
            ],
          ),

  
          _buildHeader(primaryColor),

  
          _buildInsightCard(mapViewModel, primaryColor),


          _buildDraggableSheet(mapViewModel, darkColor),


          if (mapViewModel.isLoading)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }


  Widget _buildUserLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(LucideIcons.circle_user_round, color: Colors.blue, size: 32),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10, 
          bottom: 15, 
          left: 20, 
          right: 20
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: const Center(
          child: Text(
            'Viviendas cerca de ti',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(MapViewModel vm, Color color) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 20,
      right: 20,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white.withOpacity(0.98),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(LucideIcons.navigation, color: color, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("PROMEDIO DE RENTA (5KM)", 
                    style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(vm.averageRentFormatted,
                    style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableSheet(MapViewModel vm, Color handleColor) {
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6E5D4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: vm.properties.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildSheetHandle(handleColor, vm.properties.length);
              return _buildPropertyCard(vm.properties[index - 1]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle(Color color, int count) {
    return Column(
      children: [
        Container(width: 40, height: 5, 
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 15),
        Text('$count viviendas encontradas', 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildPropertyCard(Property p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 80, height: 80, 
              child: Image.network(p.imageUrl, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: AppColors.background, child: const Icon(LucideIcons.house)))),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1),
                Text(p.neighborhood, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('\$${(p.monthlyRent / 1000).toStringAsFixed(0)}k /mes',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black45,
      child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}