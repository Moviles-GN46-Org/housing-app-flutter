import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// Main (home) screen with a regular feed of housing listings

// Dropdown list for budget filter

const List<String> list = <String>['One', 'Two', 'Three', 'Four'];

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
                      icon: const Icon(LucideIcons.map_pin),
                      onPressed: () {},
                    ),
                  ],
                  leading: IconButton(
                    icon: const Icon(LucideIcons.bell),
                    onPressed: () {},
                  ),
                  backgroundColor: const Color(0xFFF7E6D5),
                  toolbarHeight: 216.0,
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(0),
                    child: Row(
                      children: <Widget>[const DropdownButtonBudget()],
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

class DropdownButtonBudget extends StatefulWidget {
  const DropdownButtonBudget({super.key});

  @override
  State<DropdownButtonBudget> createState() => _DropdownButtonBudgetState();
}

class _DropdownButtonBudgetState extends State<DropdownButtonBudget> {
  String? dropdownValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: DropdownButton<String>(
        value: dropdownValue,
        hint: const Text('Budget'),
        icon: const Icon(LucideIcons.chevron_down),
        elevation: 1,
        style: const TextStyle(
          color: AppColors.dustyTaupe,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          fontFamily: AppTextStyles.fontFamily,
        ),
        dropdownColor: AppColors.white,
        borderRadius: BorderRadius.circular(10.0),
        enableFeedback: true,
        focusColor: AppColors.linen,
        iconEnabledColor: AppColors.dustyTaupe,
        iconSize: 20.0,
        underline: const SizedBox(),
        onChanged: (String? value) {
          setState(() {
            dropdownValue = value;
          });
        },
        selectedItemBuilder: (BuildContext context) {
          return <String>['', ...list].map<Widget>((String value) {
            if (value == '') {
              return const Text('Budget');
            }
            return Text(value);
          }).toList();
        },
        items: <DropdownMenuItem<String>>[
          const DropdownMenuItem<String>(value: '', child: Text('None')),
          ...list.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }),
        ],
      ),
    );
  }
}
