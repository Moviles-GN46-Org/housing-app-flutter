import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../models/property_model.dart';
import '../utils/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// Main (home) screen with a regular feed of housing listings

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onMapTap});

  final VoidCallback? onMapTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeViewModel _homeVM;

  @override
  void initState() {
    super.initState();
    _homeVM = context.read<HomeViewModel>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeVM.fetchProperties();
      _homeVM.fetchNotifications();
      _homeVM.startNotificationsPolling();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _homeVM.fetchNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeVM.stopNotificationsPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();
    final unreadNotifications = homeVM.unreadNotifications;

    return Scaffold(
      backgroundColor: AppColors.linen,
      body: homeVM.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lightBronze),
            )
          : homeVM.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading listings',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => homeVM.retryProperties(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBronze,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Center(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text(
                    'Find your next home',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      color: AppColors.deepMocha,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: true,
                  titleSpacing: 0.0,
                  leadingWidth: 56.0,
                  scrolledUnderElevation: 0,
                  actions: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          LucideIcons.map_pin,
                          color: AppColors.dustyTaupe,
                          size: 30.0,
                        ),
                        onPressed: () {
                          widget.onMapTap?.call();
                        },
                      ),
                    ),
                  ],
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: PopupMenuButton<void>(
                      padding: EdgeInsets.zero,
                      color: Colors.transparent,
                      elevation: 0,
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<void>>[
                          PopupMenuItem<void>(
                            enabled: false,
                            padding: EdgeInsets.zero,
                            child: NotificationsDropdown(
                              notifications: unreadNotifications,
                            ),
                          ),
                        ];
                      },
                      icon: Badge.count(
                        count: unreadNotifications.length,
                        backgroundColor: AppColors.lightBronze,
                        isLabelVisible: unreadNotifications.isNotEmpty,
                        offset: const Offset(10, -6),
                        padding: const EdgeInsets.all(2.0),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                        child: const Icon(
                          LucideIcons.bell,
                          color: AppColors.dustyTaupe,
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                  backgroundColor: const Color(0xFFF7E6D5),
                  toolbarHeight: 200.0,
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SearchAnchor(
                            isFullScreen: false,
                            viewBackgroundColor: AppColors.white,
                            viewShape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16.0),
                              ),
                            ),
                            viewConstraints: const BoxConstraints(minHeight: 0),
                            builder:
                                (
                                  BuildContext context,
                                  SearchController controller,
                                ) {
                                  return DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16.0),
                                      boxShadow: AppShadows.small,
                                    ),
                                    child: SearchBar(
                                      controller: controller,
                                      elevation:
                                          const WidgetStatePropertyAll<double>(
                                            0.0,
                                          ),
                                      padding:
                                          const WidgetStatePropertyAll<
                                            EdgeInsets
                                          >(
                                            EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                            ),
                                          ),
                                      shape:
                                          const WidgetStatePropertyAll<
                                            OutlinedBorder
                                          >(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(16.0),
                                              ),
                                            ),
                                          ),
                                      onTap: () {
                                        controller.openView();
                                      },
                                      onChanged: (_) {
                                        controller.openView();
                                      },
                                      leading: const Icon(
                                        LucideIcons.search,
                                        color: AppColors.dustyTaupe,
                                        size: 20.0,
                                      ),
                                      hintText:
                                          'Search by location, amenities...',
                                      hintStyle:
                                          const WidgetStatePropertyAll<
                                            TextStyle
                                          >(
                                            TextStyle(
                                              color: Color(0xFFB9A9A0),
                                              fontWeight: FontWeight.w400,
                                              fontSize: 16,
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                            ),
                                          ),
                                      constraints: const BoxConstraints(
                                        minHeight: 56.0,
                                        maxHeight: 80.0,
                                      ),
                                      backgroundColor:
                                          const WidgetStatePropertyAll<Color?>(
                                            AppColors.white,
                                          ),
                                    ),
                                  );
                                },
                            suggestionsBuilder:
                                (
                                  BuildContext context,
                                  SearchController controller,
                                ) {
                                  return <Widget>[
                                    ListTile(title: Text('Teusaquillo')),
                                    ListTile(title: Text('Chapinero')),
                                    ListTile(title: Text('Kitchen')),
                                    ListTile(title: Text('Shared')),
                                    ListTile(title: Text('Suba')),
                                    ListTile(title: Text('Furnished')),
                                    ListTile(title: Text('Suite')),
                                  ];
                                },
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            top: 16.0,
                            bottom: 16.0,
                          ),
                          child: Row(
                            spacing: 10.0,
                            children: <Widget>[
                              const DropdownButtonBudget(),
                              const DropdownButtonAmenities(),
                              const DropdownButtonLocation(),
                              const DropdownButtonRoomType(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                body: homeVM.properties.isEmpty
                    ? const Center(
                        child: Text(
                          'No listings found',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            ...homeVM.properties.indexed.map(
                              ((int, Property) entry) => PropertyCard(
                                property: entry.$2,
                                index: entry.$1,
                                isFavorite: homeVM.isFavorite(entry.$2.id),
                                isFavoriteLoading: homeVM
                                    .isFavoriteActionInFlight(entry.$2.id),
                                onFavoriteTap: () async {
                                  final success = await homeVM.toggleFavorite(
                                    entry.$2.id,
                                  );
                                  if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Unable to update favorite right now',
                                          ),
                                        ),
                                      );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 110),
                          ],
                        ),
                      ),
              ),
            ),
    );
  }
}

class NotificationsDropdown extends StatelessWidget {
  const NotificationsDropdown({required this.notifications, super.key});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              top: 14,
              right: 16,
              bottom: 10,
            ),
            child: const Text(
              'Notifications',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepMocha,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9DDD3)),
          Flexible(
            child: notifications.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No new notifications!',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          color: AppColors.dustyTaupe,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Color(0xFFF1E8E0)),
                    itemBuilder: (BuildContext context, int index) {
                      final AppNotification item = notifications[index];
                      return ListTile(
                        dense: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.deepMocha,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'MMM d, y h:mm a',
                              ).format(item.createdAt.toLocal()),
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Dropdown list for budget filter

const List<String> budgetList = <String>[
  'Under \$600k',
  '\$600k - \$900k',
  '\$900k - \$1.2M',
  'Above \$1.2M',
];

class DropdownButtonBudget extends StatefulWidget {
  const DropdownButtonBudget({super.key});

  @override
  State<DropdownButtonBudget> createState() => _DropdownButtonBudgetState();
}

class _DropdownButtonBudgetState extends State<DropdownButtonBudget> {
  String? dropdownValue;

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = dropdownValue != null && dropdownValue != '';

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: hasSelection ? AppColors.lightBronze : AppColors.white,
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: AppShadows.small,
        ),
        child: DropdownButton<String>(
          value: dropdownValue,
          hint: const Text(
            'Budget Range',
            style: TextStyle(
              color: AppColors.dustyTaupe,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(
              LucideIcons.chevron_down,
              color: hasSelection ? AppColors.white : AppColors.dustyTaupe,
            ),
          ),
          elevation: 1,
          isDense: true,
          style: TextStyle(
            color: hasSelection ? AppColors.white : AppColors.dustyTaupe,
            fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
            fontFamily: AppTextStyles.fontFamily,
          ),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          enableFeedback: true,
          focusColor: AppColors.linen,
          iconEnabledColor: hasSelection
              ? AppColors.white
              : AppColors.dustyTaupe,
          iconSize: 20.0,
          underline: const SizedBox(),
          onChanged: (String? value) {
            setState(() {
              dropdownValue = value;
            });
          },
          selectedItemBuilder: (BuildContext context) {
            return <String>['', ...budgetList].map<Widget>((String value) {
              if (value == '') {
                return const Text('Budget Range');
              }
              return Text(
                value,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              );
            }).toList();
          },
          items: <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: '',
              child: Text(
                'Any',
                style: TextStyle(
                  color: AppColors.dustyTaupe,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ),
            ...budgetList.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppColors.dustyTaupe,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Dropdown list for roomType filter

const List<String> roomTypeList = <String>[
  'Private room',
  'Shared (2 people)',
  'Shared (3+ people)',
  'Studio apartment',
  'Entire apartment',
];

class DropdownButtonRoomType extends StatefulWidget {
  const DropdownButtonRoomType({super.key});

  @override
  State<DropdownButtonRoomType> createState() => _DropdownButtonRoomTypeState();
}

class _DropdownButtonRoomTypeState extends State<DropdownButtonRoomType> {
  String? dropdownValue;

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = dropdownValue != null && dropdownValue != '';

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: hasSelection ? AppColors.lightBronze : AppColors.white,
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: AppShadows.small,
        ),
        child: DropdownButton<String>(
          value: dropdownValue,
          hint: const Text(
            'Living Situation',
            style: TextStyle(
              color: AppColors.dustyTaupe,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(
              LucideIcons.chevron_down,
              color: hasSelection ? AppColors.white : AppColors.dustyTaupe,
            ),
          ),
          elevation: 1,
          isDense: true,
          style: TextStyle(
            color: hasSelection ? AppColors.white : AppColors.dustyTaupe,
            fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
            fontFamily: AppTextStyles.fontFamily,
          ),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          enableFeedback: true,
          focusColor: AppColors.linen,
          iconEnabledColor: hasSelection
              ? AppColors.white
              : AppColors.dustyTaupe,
          iconSize: 20.0,
          underline: const SizedBox(),
          onChanged: (String? value) {
            setState(() {
              dropdownValue = value;
            });
          },
          selectedItemBuilder: (BuildContext context) {
            return <String>['', ...roomTypeList].map<Widget>((String value) {
              if (value == '') {
                return const Text('Living Situation');
              }
              return Text(
                value,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              );
            }).toList();
          },
          items: <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: '',
              child: Text(
                'Any',
                style: TextStyle(
                  color: AppColors.dustyTaupe,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ),
            ...roomTypeList.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppColors.dustyTaupe,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Dropdown list for amenities filter

const List<String> amenitiesList = <String>[
  'Wi-Fi',
  'Furnished',
  'Kitchen',
  'Laundry',
];

class DropdownButtonAmenities extends StatefulWidget {
  const DropdownButtonAmenities({super.key});

  @override
  State<DropdownButtonAmenities> createState() =>
      _DropdownButtonAmenitiesState();
}

class _DropdownButtonAmenitiesState extends State<DropdownButtonAmenities> {
  String? dropdownValue;

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = dropdownValue != null && dropdownValue != '';

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: hasSelection ? AppColors.lightBronze : AppColors.white,
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: AppShadows.small,
        ),
        child: DropdownButton<String>(
          value: dropdownValue,
          hint: const Text(
            'Amenities',
            style: TextStyle(
              color: AppColors.dustyTaupe,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(
              LucideIcons.chevron_down,
              color: hasSelection ? AppColors.white : AppColors.dustyTaupe,
            ),
          ),
          elevation: 1,
          isDense: true,
          style: TextStyle(
            color: hasSelection ? AppColors.white : AppColors.dustyTaupe,
            fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
            fontFamily: AppTextStyles.fontFamily,
          ),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          enableFeedback: true,
          focusColor: AppColors.linen,
          iconEnabledColor: hasSelection
              ? AppColors.white
              : AppColors.dustyTaupe,
          iconSize: 20.0,
          underline: const SizedBox(),
          onChanged: (String? value) {
            setState(() {
              dropdownValue = value;
            });
          },
          selectedItemBuilder: (BuildContext context) {
            return <String>['', ...amenitiesList].map<Widget>((String value) {
              if (value == '') {
                return const Text('Amenities');
              }
              return Text(
                value,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              );
            }).toList();
          },
          items: <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: '',
              child: Text(
                'Any',
                style: TextStyle(
                  color: AppColors.dustyTaupe,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ),
            ...amenitiesList.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppColors.dustyTaupe,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Dropdown list for location filter

const List<String> locationList = <String>[
  'Usaquén',
  'Chapinero',
  'Suba',
  'Teusaquillo',
  'Fontibón',
  'Engativá',
];

class DropdownButtonLocation extends StatefulWidget {
  const DropdownButtonLocation({super.key});

  @override
  State<DropdownButtonLocation> createState() => _DropdownButtonLocationState();
}

class _DropdownButtonLocationState extends State<DropdownButtonLocation> {
  String? dropdownValue;

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = dropdownValue != null && dropdownValue != '';

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: hasSelection ? AppColors.lightBronze : AppColors.white,
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: AppShadows.small,
        ),
        child: DropdownButton<String>(
          value: dropdownValue,
          hint: const Text(
            'Location',
            style: TextStyle(
              color: AppColors.dustyTaupe,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(
              LucideIcons.chevron_down,
              color: hasSelection ? AppColors.white : AppColors.dustyTaupe,
            ),
          ),
          elevation: 1,
          isDense: true,
          style: TextStyle(
            color: hasSelection ? AppColors.white : AppColors.dustyTaupe,
            fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
            fontFamily: AppTextStyles.fontFamily,
          ),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          enableFeedback: true,
          focusColor: AppColors.linen,
          iconEnabledColor: hasSelection
              ? AppColors.white
              : AppColors.dustyTaupe,
          iconSize: 20.0,
          underline: const SizedBox(),
          onChanged: (String? value) {
            setState(() {
              dropdownValue = value;
            });
          },
          selectedItemBuilder: (BuildContext context) {
            return <String>['', ...locationList].map<Widget>((String value) {
              if (value == '') {
                return const Text('Location');
              }
              return Text(
                value,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              );
            }).toList();
          },
          items: <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: '',
              child: Text(
                'Any',
                style: TextStyle(
                  color: AppColors.dustyTaupe,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ),
            ...locationList.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppColors.dustyTaupe,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Property card widget

class PropertyCard extends StatelessWidget {
  final Property property;
  final int index;
  final bool isFavorite;
  final bool isFavoriteLoading;
  final VoidCallback onFavoriteTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.index,
    required this.isFavorite,
    required this.isFavoriteLoading,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
                child: Image.network(
                  property.imageUrl,
                  height: 164,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 164,
                    width: double.infinity,
                    color: const Color(0xFFD9CEC8),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isFavoriteLoading ? null : onFavoriteTap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isFavorite
                            ? AppColors.lightBronze
                            : const Color(0xB3FFFFFF),
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.small,
                      ),
                      child: Center(
                        child: isFavoriteLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.lightBronze,
                                ),
                              )
                            : Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? AppColors.white
                                    : AppColors.lightBronze,
                                size: 28,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        property.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepMocha,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.star,
                          color: AppColors.lightBronze,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          property.averageRating != null
                              ? property.averageRating!.toStringAsFixed(1)
                              : '-',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightBronze,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.map_pin,
                                color: AppColors.dustyTaupe,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                property.neighborhood.isNotEmpty
                                    ? property.neighborhood
                                    : property.address,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  color: AppColors.dustyTaupe,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.bed_single,
                                color: AppColors.dustyTaupe,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${property.bedrooms} Bed \u00b7 ${property.bathrooms} Bath',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  color: AppColors.dustyTaupe,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IntrinsicWidth(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightBronze,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '\$${NumberFormat('#,###').format(property.monthlyRent.toInt())}',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              const TextSpan(
                                text: ' /mo',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
