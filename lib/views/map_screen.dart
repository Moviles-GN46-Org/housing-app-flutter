import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
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
      _executeDataFetch();
    });
  }

  void _executeDataFetch() {
    final token = context.read<AuthViewModel>().token;
    if (token != null) {
      context.read<MapViewModel>().fetchProperties(token);
    }
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
          // 1. Base Map Layer
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
                    size: 40,
                  ),
                )).toList(),
              ),
            ],
          ),

          // 2. Custom Professional Header
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
                    color: Color(0xFFFDFBF9),
                    fontSize: 20,
                    fontFamily: 'Instrument Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          // 3. Search Area Button (Floating)
          Positioned(
            top: 120,
            left: 100,
            right: 100,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xEDFEFBF9),
                borderRadius: BorderRadius.circular(9999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3D3C2E26),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 18, color: brandGrey),
                  SizedBox(width: 8),
                  Text(
                    'Search this area',
                    style: TextStyle(
                      color: brandGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. BQ2: Market Insights Card (Always visible)
          Positioned(
            top: 175,
            left: 20,
            right: 20,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: brandOrange),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Market Average Rent",
                          style: TextStyle(color: brandGrey, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          mapViewModel.averageRentFormatted,
                          style: const TextStyle(color: brandDark, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Sliding Panel (Recommended for you)
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
                    topRight: Radius.circular(30),
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
                              width: 48,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0x518B7364),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Recommended for you',
                              style: TextStyle(
                                color: brandDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
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
            const Center(child: CircularProgressIndicator(color: brandOrange)),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property p, Color titleColor, Color detailColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x213C2E26), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              image: const DecorationImage(
                image: NetworkImage("https://placehold.co/150x150"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.title,
                    style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${p.neighborhood} • 1.0 miles',
                    style: TextStyle(color: detailColor, fontSize: 13),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '\$${(p.monthlyRent / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(' /mo', style: TextStyle(color: detailColor, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}