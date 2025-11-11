import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/SCREENS/login/login_screen.dart';
import 'package:user_interface/SERVICES/parking_service.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';
import 'package:user_interface/SERVICES/user_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final ParkingApiService _parkingService = ParkingApiService();
   
  String _firstName = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  Future<void> _loadAllUserData() async {
    final userDataFuture = _userService.fetchUserProfile();
    final vehicleDataFuture = _parkingService.fetchUserVehicles();
    final sessionDataFuture = _parkingService.fetchActiveSessions();

    final results = await Future.wait([userDataFuture, vehicleDataFuture, sessionDataFuture]);
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      
      final userData = results[0] as Map<String, dynamic>?;

      if (userData != null) {
        _firstName = userData['first_name'];
      }

      if (userData == null && !_isLoading) {
          _handleLogout(context);
      }
    });
  }

  void _handleLogout(BuildContext context) async {
    final storageService = SecureStorageService();
    await storageService.deleteTokens();
    Navigator.of(context).pushReplacement(slideRoute(const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color.fromARGB(255, 52, 12, 108),
                        Color.fromARGB(255, 2, 11, 60),
                      ],
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 10, bottom: 20),
                      child: Text(
                        'Welcome, $_firstName!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Find a parking spot...',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
          
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: TextField(
                          style: GoogleFonts.poppins(color: Colors.white),
                          cursorColor: Colors.white70,
                          decoration: InputDecoration(
                            hintText: 'Search nearby parkings...',
                            hintStyle: GoogleFonts.poppins(color: Colors.white70),
                            prefixIcon: const Icon(IconlyLight.search, color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (query) {

                          },
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

