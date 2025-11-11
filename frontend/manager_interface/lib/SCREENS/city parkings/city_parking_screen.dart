import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import 'package:manager_interface/MAIN%20UTILS/page_transition.dart';
import 'package:manager_interface/MAIN%20UTILS/search_bar_widget.dart';
import 'package:manager_interface/SCREENS/HOME/home_screen.dart';
import 'package:manager_interface/MAIN%20UTILS/add_parking_dialog.dart';
import 'package:manager_interface/SCREENS/parking%20detail/parking_detail_screen.dart';
import 'package:manager_interface/models/parking.dart';
import 'package:manager_interface/SCREENS/home/utils/parking_card.dart';
import 'package:manager_interface/services/parking_service.dart';

class CityParkingScreen extends StatefulWidget {
  final String city;
  final List<String> cities;
  final List<Parking> parkings;
  final void Function(Parking) onParkingTap;
  final void Function(Parking)? onParkingAdded;
  final void Function(Parking)? onParkingDeleted;

  const CityParkingScreen({
    super.key,
    required this.city,
    required this.parkings,
    required this.onParkingTap,
    this.onParkingAdded,
    this.onParkingDeleted,
    required this.cities,
  });

  @override
  State<CityParkingScreen> createState() => _CityParkingScreenState();
}

class _CityParkingScreenState extends State<CityParkingScreen> {
  List<Parking> parkings = [];
  List<Parking> filteredParkings = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParkings(widget.city);
  }
  Future<void> _loadParkings(String city) async {
    setState(() => isLoading = true);

    try {
      final List<Parking> parkingList = await ParkingService.getParkingsByCity(city);
      setState(() {
        parkings = parkingList;
        filteredParkings = parkingList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load parkings: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onSearchChanged(String query) {
    query = query.toLowerCase();
    if (query.isEmpty) {
      setState(() => filteredParkings = parkings);
      return;
    }

    final results = parkings
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();

    setState(() => filteredParkings = results);
  }

  /// 🔹 Aggiunge un nuovo parcheggio e aggiorna la lista
  void _onAddParking(Parking newParking) {
    setState(() {
      parkings.add(newParking);
      filteredParkings = parkings;
    });
    widget.onParkingAdded?.call(newParking);
  }

  /// 🔹 Elimina un parcheggio e aggiorna la lista
  Future<void> _onDeleteParking(Parking parkingToDelete) async {
    setState(() => isLoading = true);

    try {
      await ParkingService.deleteParking(parkingToDelete.id);

      setState(() {
        parkings.removeWhere((p) => p.id == parkingToDelete.id);
        filteredParkings = parkings;
        isLoading = false;
      });

      widget.onParkingDeleted?.call(parkingToDelete);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parking "${parkingToDelete.name}" deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      final errorMsg = e.toString().contains('IntegrityError') ||
              e.toString().contains('Cannot delete')
          ? 'Cannot delete: Parking has associated spots or sessions. Remove them first.'
          : 'Error: Could not delete parking.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  /// 🔹 Apre la schermata di dettaglio del parcheggio
  void _navigateToParkingDetail(Parking parking) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParkingDetailScreen(parkingId: parking.id),
      ),
    );

    // Ricarica la lista dopo eventuali modifiche
    _loadParkings(widget.city);
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = filteredParkings;

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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Find parkings in ${widget.city}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        slideRoute(const HomeScreen()),
                      );
                    },
                    icon: const Icon(IconlyLight.location, color: Colors.white),
                    label: Text(
                      'Change area',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 🔹 Barra di ricerca
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SearchBarWidget(
                  onChanged: _onSearchChanged,
                  hintText: 'Search parkings...',
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Titolo + pulsante "Add"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search results',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final newParking = await showAddParkingDialog(
                        context,
                        existingCities: widget.cities,
                        knownCity: widget.city,
                      );
                      if (newParking != null) {
                        _onAddParking(newParking);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    child: Text(
                      'Add Parking',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 🔹 Lista parcheggi
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : listToShow.isEmpty
                          ? Center(
                              child: Text(
                                'No parkings found',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: listToShow.length,
                              itemBuilder: (context, index) {
                                final parking = listToShow[index];
                                return ParkingCard(
                                  parking: parking,
                                  onTap: () => _navigateToParkingDetail(parking),
                                  onDelete: _onDeleteParking,
                                  allParkings: parkings,
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
