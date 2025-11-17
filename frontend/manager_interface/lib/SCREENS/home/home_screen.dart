import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  List<String> filteredCities = [];
  List<Parking> parkings = [];

  bool isLoading = true;

  // 地图初始位置（意大利附近）
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(41.8719, 12.5674),
    zoom: 5,
  );

  // 地图上的所有城市 marker
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadCitiesAndMarkers();
  }

  /// 一次性加载所有城市，并为每个城市生成一个 marker
  Future<void> _loadCitiesAndMarkers() async {
    try {
      final cityList = await ParkingService.getCities();
      final markers = <Marker>{};

      Parking? firstParkingWithCoords;

      for (final city in cityList) {
        try {
          final parkingList = await ParkingService.getParkingsByCity(city);

          Parking? firstWithCoords;
          for (final p in parkingList) {
            if (p.latitude != null && p.longitude != null) {
              firstWithCoords = p;
              break;
            }
          }

          if (firstWithCoords != null) {
            final pos =
                LatLng(firstWithCoords.latitude!, firstWithCoords.longitude!);

            markers.add(
              Marker(
                markerId: MarkerId('city_$city'),
                position: pos,
                infoWindow: InfoWindow(
                  title: city,
                  snippet: firstWithCoords.address,
                ),
                // ✅ 点击 pin = 打开该城市
                onTap: () {
                  _openCity(city);
                },
              ),
            );

            firstParkingWithCoords ??= firstWithCoords;
          }
        } catch (e) {
          debugPrint('Error loading parkings for city $city: $e');
        }
      }

      setState(() {
        cities = cityList;
        filteredCities = cityList;
        _markers = markers;
        isLoading = false;

        if (firstParkingWithCoords != null) {
          _initialCameraPosition = CameraPosition(
            target: LatLng(
              firstParkingWithCoords.latitude!,
              firstParkingWithCoords.longitude!,
            ),
            zoom: 6.5,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading cities: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 只负责获取某个城市的停车场列表
  Future<List<Parking>> _fetchParkingsForCity(String city) async {
    try {
      return await ParkingService.getParkingsByCity(city);
    } catch (e) {
      debugPrint('Error fetching parkings for $city: $e');
      return [];
    }
  }

  /// 列表点击 / 地图 pin 点击都会调用这个函数
  Future<void> _openCity(String city) async {
    final list = await _fetchParkingsForCity(city);
    if (!mounted) return;

    setState(() {
      selectedCity = city;
      parkings = list;
    });

    _navigateToCityScreen(city);
  }

  void _navigateToCityScreen(String selectedCity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CityParkingScreen(
          city: selectedCity,
          parkings: parkings,
          onParkingTap: (Parking p1) {},
          cities: cities,
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

    final results =
        cities.where((city) => city.toLowerCase().contains(query)).toList();

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
                                  'Parking "${newParking.name}" added!',
                                ),
                              ),
                            );
                            // 重新加载城市和 marker
                            setState(() {
                              isLoading = true;
                            });
                            await _loadCitiesAndMarkers();
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white12,
                          minimumSize: const Size(double.infinity, 60),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
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

                      // ✅ 地图卡片
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 260,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: GoogleMap(
                            initialCameraPosition: _initialCameraPosition,
                            markers: _markers,
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

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

                      // 城市列表
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
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  // ✅ 列表点击 = 地图 pin 点击
                                  onTap: () => _openCity(city),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
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
