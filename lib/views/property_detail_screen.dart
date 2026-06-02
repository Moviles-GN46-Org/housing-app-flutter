import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/property_model.dart';
import '../models/review_model.dart';
import '../repositories/property_repository.dart';
import '../services/offline_queue_service.dart';
import '../utils/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import 'write_review_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key, required this.property});

  final Property property;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Review> _reviews = [];
  bool _reviewsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = context.read<PropertyRepository>();
      final reviews = await repo.getPropertyReviews(widget.property.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _reviewsLoading = false;
        });
      }
    });
  }

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
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment(0, 0.4),
                        colors: [Color(0x88000000), Colors.transparent],
                      ),
                    ),
                  ),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  const SizedBox(height: 32),

                  Builder(
                    builder: (context) {
                      final currentUserId = context
                          .read<AuthViewModel>()
                          .currentUser
                          ?.id;
                      final offlineQueue = context.watch<OfflineQueueService>();

                      final reviewedOnServer =
                          currentUserId != null &&
                          _reviews.any((r) => r.author.id == currentUserId);
                      final reviewPendingSync =
                          currentUserId != null &&
                          offlineQueue.hasPendingReviewForProperty(property.id);

                      if (reviewedOnServer || reviewPendingSync) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4E0CA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                reviewPendingSync
                                    ? LucideIcons.clock
                                    : LucideIcons.circle_check,
                                size: 16,
                                color: AppColors.dustyTaupe,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reviewPendingSync
                                    ? 'Review pending sync'
                                    : 'You have already reviewed this property',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.dustyTaupe,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final newReview = await Navigator.of(context)
                                .push<Review>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WriteReviewScreen(property: property),
                                  ),
                                );
                            if (newReview != null && mounted) {
                              setState(
                                () => _reviews = [newReview, ..._reviews],
                              );
                            }
                          },
                          icon: const Icon(LucideIcons.pencil, size: 16),
                          label: const Text(
                            'Write a review',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lightBronze,
                            side: const BorderSide(
                              color: AppColors.lightBronze,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  _ReviewsSection(
                    reviews: _reviews,
                    loading: _reviewsLoading,
                    averageRating: property.averageRating,
                    reviewCount: property.reviewCount,
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

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.reviews,
    required this.loading,
    this.averageRating,
    this.reviewCount,
  });

  final List<Review> reviews;
  final bool loading;
  final double? averageRating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.star,
              size: 17,
              color: AppColors.lightBronze,
            ),
            const SizedBox(width: 7),
            const Text(
              'Reviews',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepMocha,
              ),
            ),
            if (averageRating != null) ...[
              const SizedBox(width: 10),
              Text(
                averageRating!.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightBronze,
                ),
              ),
            ],
            const Spacer(),
            if (reviewCount != null)
              Text(
                '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  color: AppColors.dustyTaupe,
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),

        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.lightBronze,
              ),
            ),
          )
        else if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.small,
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.message_square,
                  size: 32,
                  color: AppColors.dustyTaupe.withAlpha(120),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepMocha,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Be the first to share your experience.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: AppColors.dustyTaupe,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: reviews
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewCard(review: r),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final initials =
        '${review.author.firstName.isNotEmpty ? review.author.firstName[0] : ''}${review.author.lastName.isNotEmpty ? review.author.lastName[0] : ''}'
            .toUpperCase();

    final dateLabel = DateFormat('MMM d, yyyy').format(review.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E0CA),
                  shape: BoxShape.circle,
                ),
                child:
                    review.author.profilePictureUrl != null &&
                        review.author.profilePictureUrl!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: review.author.profilePictureUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dustyTaupe,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dustyTaupe,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author.fullName,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepMocha,
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: AppColors.dustyTaupe,
                      ),
                    ),
                  ],
                ),
              ),
              _StarRating(rating: review.rating),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            review.comment,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: AppColors.ashBrown,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 15,
          color: i < rating
              ? AppColors.lightBronze
              : AppColors.dustyTaupe.withAlpha(100),
        );
      }),
    );
  }
}
