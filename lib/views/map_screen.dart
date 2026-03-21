import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../viewmodels/map_view_model.dart';
import '../models/property_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapViewModel = context.watch<MapViewModel>();
    
    const Color brandOrange = Color(0xFFDA9958);
    const Color brandDark = Color(0xFF3C2E26);
    const Color brandGrey = Color(0xFF8B7264);
    const Color brandBackground = Color(0xFFFBF3EB);

    return Scaffold(
      backgroundColor: brandBackground,
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(4.6020, -74.0650),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.uniandes.housing_app',
              ),
              MarkerLayer(
                markers: mapViewModel.properties.map((p) => Marker(
                  point: LatLng(p.latitude, p.longitude),
                  width: 45,
                  height: 45,
                  child: const Icon(
                    Icons.location_on, 
                    color: brandOrange, 
                    size: 40
                  ),
                )).toList(),
              ),
            ],
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, bottom: 15, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: brandOrange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: Text(
                  'Map View',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 20, 
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Instrument Sans'
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 130,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: brandOrange, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Market Average Rent",
                          style: TextStyle(color: brandGrey, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          mapViewModel.averageRentFormatted,
                          style: const TextStyle(
                            color: brandDark, 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6E5D4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30), 
                    topRight: Radius.circular(30)
                  ),
                ),
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: mapViewModel.properties.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: brandGrey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'Recommended for you',
                              style: TextStyle(
                                color: brandDark, 
                                fontSize: 22, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final property = mapViewModel.properties[index - 1];
                    return _buildPropertyCard(property, brandDark, brandGrey);
                  },
                ),
              );
            },
          ),

          if (mapViewModel.isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: brandOrange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property p, Color titleColor, Color detailColor) {
    final bool isSvg = p.imageUrl.toLowerCase().endsWith('.svg');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              width: 90,
              height: 90,
              child: isSvg 
                ? SvgPicture.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    placeholderBuilder: (context) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFFBF3EB),
                      child: const Icon(Icons.home_work_outlined, color: Color(0xFFDA9958)),
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  p.neighborhood,
                  style: TextStyle(color: detailColor, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${(p.monthlyRent / 1000).toStringAsFixed(0)}k /mo',
                  style: TextStyle(
                    color: titleColor, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w800
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}