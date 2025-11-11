import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MAIN%20UTILS/bottom_navigation_bar.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_screen.dart';
import 'package:user_interface/SCREENS/home/home_screen.dart';
import 'package:user_interface/SCREENS/profile/profile_screen.dart';
import 'package:user_interface/SCREENS/sessions/sessions_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    SessionsScreen(),
    DashboardScreen(),
    ProfileScreen(),
  ];

  final List<IconData> _icons = const [
    IconlyLight.home,
    IconlyLight.ticket,
    IconlyLight.chart,
    IconlyLight.profile,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: _pages,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentIndex: _currentIndex,
              onItemSelected: _onItemSelected,
              icons: _icons,
            ),
          ),
        ],
      ),
    );
  }
}