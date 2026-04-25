import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../services/analytics_service.dart';
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
  ScrollController? _sheetScrollController;
  String? _selectedPropertyId;

  static const double _kSheetHeaderHeight = 68.0;
  static const double _kCardHeight = 116.0;
  static const double _kSheetTopPadding = 12.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final analytics = context.read<AnalyticsService>();
      await context.read<MapViewModel>().initializeMap();
      await analytics.markFeatureLoadEnd(ScreenName.mapSearch);
    });
  }

  void _crashApp() {
    throw StateError('Intentional crash from Map Search for demo');
  }

  String _formatPriceMillions(double rentInPesos) {
    final millions = rentInPesos / 1000000;
    final str = millions.toStringAsFixed(1);
    final clean = str.endsWith('.0') ? str.substring(0, str.length - 2) : str;
    return '\$${clean}M';
  }

  void _onPropertyMarkerTapped(Property p, int index) {
    setState(() => _selectedPropertyId = p.id);
    _mapController.move(
      LatLng(p.latitude, p.longitude),
      _mapController.camera.zoom,
    );

    final controller = _sheetScrollController;
    if (controller != null && controller.hasClients) {
      final targetOffset =
          _kSheetTopPadding + _kSheetHeaderHeight + (index * _kCardHeight);
      controller.animateTo(
        targetOffset.clamp(0.0, controller.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapViewModel = context.watch<MapViewModel>();
    final Color primaryColor = AppColors.lightBronze;
    final Color darkColor = AppColors.dustyTaupe;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
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
                  ...mapViewModel.properties.asMap().entries.map((entry) {
                    final index = entry.key;
                    final p = entry.value;
                    return Marker(
                      point: LatLng(p.latitude, p.longitude),
                      width: 90,
                      height: 50,
                      alignment: Alignment.bottomCenter,
                      child: _buildPriceMarker(
                        p,
                        p.id == _selectedPropertyId,
                        primaryColor,
                        () => _onPropertyMarkerTapped(p, index),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          _buildHeader(primaryColor),

          _buildInsightCard(mapViewModel, primaryColor),

          _buildDraggableSheet(mapViewModel, darkColor),

          if (mapViewModel.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withOpacity(0.6)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.deepMocha,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
          right: 20,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'Listings near you',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Crash app (demo)',
                onPressed: _crashApp,
                icon: const Icon(LucideIcons.bug, color: Colors.white),
              ),
            ),
          ],
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
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white.withOpacity(0.95),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.activity, color: color, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        "ESTADÍSTICAS DE ZONA (5KM)",
                        style: TextStyle(
                          color: AppColors.dustyTaupe,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        "Renta Promedio",
                        vm.averageRentFormatted,
                        LucideIcons.banknote,
                      ),
                      _buildStatItem(
                        "Densidad Oferta",
                        vm.supplyDensityFormatted,
                        LucideIcons.layers,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceMarker(
    Property p,
    bool isSelected,
    Color accent,
    VoidCallback onTap,
  ) {
    final Color bg = isSelected ? accent : AppColors.linen;
    final Color fg = isSelected ? AppColors.linen : AppColors.deepMocha;
    final Color borderColor = isSelected
        ? accent
        : Colors.black.withOpacity(0.08);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.25 : 0.15),
                  blurRadius: isSelected ? 10 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _formatPriceMillions(p.monthlyRent),
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(12, 7),
            painter: _MarkerTailPainter(fill: bg, stroke: borderColor),
          ),
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
        child: Icon(LucideIcons.user, color: Colors.blue, size: 32),
      ),
    );
  }

  Widget _buildDraggableSheet(MapViewModel vm, Color handleColor) {
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        _sheetScrollController = scrollController;
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
              if (index == 0)
                return _buildSheetHandle(handleColor, vm.properties.length);
              final property = vm.properties[index - 1];
              return _buildPropertyCard(
                property,
                isSelected: property.id == _selectedPropertyId,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle(Color color, int count) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          '$count listings found',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildPropertyCard(Property p, {bool isSelected = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.lightBronze : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.lightBronze.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                p.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: AppColors.background,
                  child: const Icon(LucideIcons.house),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                ),
                Text(
                  p.neighborhood,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${(p.monthlyRent / 1000000).toStringAsFixed(1)}M /mes',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
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
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _MarkerTailPainter extends CustomPainter {
  _MarkerTailPainter({required this.fill, required this.stroke});
  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black.withOpacity(0.15), 2, false);
    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    final edgePaint = Paint()
      ..color = stroke
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width / 2, size.height),
      edgePaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width / 2, size.height),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MarkerTailPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.stroke != stroke;
}
