import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/property_model.dart';
import '../utils/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key, required this.property});

  final Property property;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> _buildAmenityChips(Property p) {
    const chipStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.dustyTaupe,
      letterSpacing: 0.5,
    );

    Widget chip(IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E0CA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.dustyTaupe),
          const SizedBox(width: 5),
          Text(label.toUpperCase(), style: chipStyle),
        ],
      ),
    );

    final chips = <Widget>[];
    if (p.hasWifi) chips.add(chip(LucideIcons.wifi, 'Wi-Fi'));
    if (p.hasParking) chips.add(chip(LucideIcons.car, 'Parking'));
    if (p.hasLaundry) chips.add(chip(LucideIcons.droplets, 'Laundry'));
    if (p.furnished) chips.add(chip(LucideIcons.armchair, 'Furnished'));
    if (p.includesUtilities) chips.add(chip(LucideIcons.zap, 'Utilities'));
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;

    return Scaffold(
      backgroundColor: AppColors.linen,
      body: CustomScrollView(
        slivers: [
          // ── App bar that collapses into the photo carousel ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.lightBronze,
            foregroundColor: AppColors.white,
            scrolledUnderElevation: 0,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Property Details',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  LucideIcons.share_2,
                  color: AppColors.white,
                  size: 22,
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Photo carousel ──
                  PageView.builder(
                    controller: _pageController,
                    itemCount: property.imageUrls.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) => CachedNetworkImage(
                      imageUrl: property.imageUrls[index],
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        color: const Color(0xFFD9CEC8),
                        child: const Center(
                          child: Icon(
                            LucideIcons.house,
                            size: 48,
                            color: AppColors.dustyTaupe,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── Gradient so the AppBar text stays legible ──
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment(0, 0.4),
                        colors: [Color(0x88000000), Colors.transparent],
                      ),
                    ),
                  ),
                  // ── VERIFIED LISTING badge ──
                  if (property.isVerified)
                    Positioned(
                      top: 90,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.small,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.badge_check,
                              size: 15,
                              color: AppColors.lightBronze,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'VERIFIED LISTING',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepMocha,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // ── Dots indicator ──
                  if (property.imageUrls.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(property.imageUrls.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPage == i ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? AppColors.white
                                  : AppColors.white.withAlpha(140),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Body content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title + address + favorite ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.title,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepMocha,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.map_pin,
                                  size: 15,
                                  color: AppColors.dustyTaupe,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    property.address.isNotEmpty
                                        ? property.address
                                        : property.neighborhood,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                      color: AppColors.dustyTaupe,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Consumer<HomeViewModel>(
                        builder: (ctx, homeVM, _) {
                          final isFav = homeVM.isFavorite(property.id);
                          final loading = homeVM.isFavoriteActionInFlight(
                            property.id,
                          );
                          return GestureDetector(
                            onTap: loading
                                ? null
                                : () => homeVM.toggleFavorite(property.id),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.card,
                                border: Border.all(
                                  color: const Color(0xFFE9DDD3),
                                ),
                              ),
                              child: Center(
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.lightBronze,
                                        ),
                                      )
                                    : Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: AppColors.lightBronze,
                                        size: 22,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Info cards ──
                  Row(
                    children: [
                      _InfoCard(
                        label: 'MONTHLY',
                        value:
                            '\$${NumberFormat('#,###').format(property.monthlyRent.toInt())}',
                        valueColor: AppColors.lightBronze,
                      ),
                      const SizedBox(width: 12),
                      _InfoCard(
                        label: 'BEDROOMS',
                        value: '${property.bedrooms}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoCard(
                        label: 'BATHROOMS',
                        value: '${property.bathrooms}',
                      ),
                      const SizedBox(width: 12),
                      _InfoCard(
                        label: 'RATING',
                        value: property.averageRating != null
                            ? property.averageRating!.toStringAsFixed(1)
                            : '—',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── About ──
                  const Text(
                    'About this property',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepMocha,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    property.description?.isNotEmpty == true
                        ? property.description!
                        : 'No description available.',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      color: AppColors.dustyTaupe,
                      height: 1.6,
                    ),
                  ),

                  // ── Amenity chips ──
                  Builder(
                    builder: (context) {
                      final chips = _buildAmenityChips(property);
                      if (chips.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Wrap(spacing: 8, runSpacing: 8, children: chips),
                        ],
                      );
                    },
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

// ── Info card widget ──────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.dustyTaupe,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.deepMocha,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
