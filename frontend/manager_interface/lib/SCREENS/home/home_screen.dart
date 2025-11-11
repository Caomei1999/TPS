import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:manager_interface/MAIN%20UTILS/add_parking_dialog.dart';
import 'package:manager_interface/MAIN%20UTILS/search_bar_widget.dart';
import 'package:manager_interface/SCREENS/city%20parkings/city_parking_screen.dart';
import 'package:manager_interface/models/parking.dart';
import '../../services/parking_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCity;
  List<String> cities = [];
  List<Parking> parkings = [];
  List<String> filteredCities = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cityList = await ParkingService.getCities();
    setState(() {
      cities = cityList;
      filteredCities = cityList;
      isLoading = false;
    });
  }

  void _navigateToCityScreen(String selectedCity) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CityParkingScreen(
          city: selectedCity,
          parkings: parkings,
          onParkingTap: (Parking p1) {},
          cities: [],
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    query = query.toLowerCase();

    if (query.isEmpty) {
      setState(() => filteredCities = cities);
      return;
    }

    final results = cities
        .where((city) => city.toLowerCase().contains(query))
        .toList();

    setState(() => filteredCities = results);
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = filteredCities;

    return Scaffold(
      body: Container(
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to TPS Manager!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextButton(
                        onPressed: () async {
                          final newParking = await showAddParkingDialog(
                            context,
                            existingCities: cities,
                            knownCity: null,
                          );
                          if (newParking != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Parking "${newParking.name}" added!'),
                              ),
                            );
                            _loadCities(); // ricarica le città
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white12,
                          minimumSize: const Size(double.infinity, 60),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        child: Text(
                          'Add a New Parking...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        '...Or Select a City to Manage its Parkings...',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SearchBarWidget(
                          hintText: 'Search a City...',
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: ListView.builder(
                            itemCount: listToShow.length,
                            itemBuilder: (context, index) {
                              final city = listToShow[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white24, width: 1),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _navigateToCityScreen(city),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: Center(
                                      child: Text(
                                        city,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
