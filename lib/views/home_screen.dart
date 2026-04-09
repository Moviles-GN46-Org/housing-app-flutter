import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// Main (home) screen with a regular feed of housing listings

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();

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
                    onPressed: () => homeVM.fetchProperties(),
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
                  actions: <Widget>[
                    IconButton(
                      icon: const Icon(
                        LucideIcons.map_pin,
                        color: AppColors.dustyTaupe,
                        size: 30.0,
                      ),
                      onPressed: () {},
                    ),
                  ],
                  leading: IconButton(
                    icon: const Icon(
                      LucideIcons.bell,
                      color: AppColors.dustyTaupe,
                      size: 30.0,
                    ),
                    onPressed: () {},
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
                            builder:
                                (
                                  BuildContext context,
                                  SearchController controller,
                                ) {
                                  return SearchBar(
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
                                        'Search by location, name, or amenities',
                                    hintStyle:
                                        const WidgetStatePropertyAll<TextStyle>(
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
                                  );
                                },
                            suggestionsBuilder:
                                (
                                  BuildContext context,
                                  SearchController controller,
                                ) {
                                  return List<ListTile>.generate(5, (
                                    int index,
                                  ) {
                                    final String item = 'item $index';
                                    return ListTile(
                                      title: Text(item),
                                      onTap: () {
                                        setState(() {
                                          controller.closeView(item);
                                        });
                                      },
                                    );
                                  });
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
                body: const Center(
                  child: Text(
                    'Property listings will appear here',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
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
