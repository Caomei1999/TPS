import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manager_interface/SCREENS/parking%20detail/utils/spot_card.dart';
import 'package:manager_interface/models/parking.dart';
import 'package:manager_interface/models/spot.dart';
import 'package:manager_interface/services/parking_service.dart';

class ParkingDetailScreen extends StatefulWidget {
  final int parkingId;

  const ParkingDetailScreen({super.key, required this.parkingId});

  @override
  State<ParkingDetailScreen> createState() => _ParkingDetailScreenState();
}

class _ParkingDetailScreenState extends State<ParkingDetailScreen> {
  Parking? parking;
  List<Spot> spots = [];
  bool isLoading = true;

  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParking();
  }

  Future<void> _loadParking() async {
    setState(() => isLoading = true);
    try {
      parking = await ParkingService.getParking(widget.parkingId);
      spots = await ParkingService.getSpots(widget.parkingId);

      _nameController.text = parking!.name;
      _cityController.text = parking!.city;
      _addressController.text = parking!.address;

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load parking: $e', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _updateParking() async {
    if (parking == null) return;

    final updatedParking = Parking(
      id: parking!.id,
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      totalSpots: parking!.totalSpots,       
      occupiedSpots: parking!.occupiedSpots,  
      ratePerHour: parking!.ratePerHour,      
    );

    final savedParking = await ParkingService.saveParking(updatedParking);

    setState(() {
      parking = savedParking;
    });

    Navigator.pop(context, savedParking);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parking updated successfully')),
    );
  }

  Future<void> _addSpot() async {
    final newSpot = await ParkingService.addSpot(parking!.id);
    setState(() => spots.add(newSpot));
  }

  Future<void> _deleteSpot(int spotId) async {
    final success = await ParkingService.deleteSpot(spotId);
    if (success) {
      setState(() => spots.removeWhere((s) => s.id == spotId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || parking == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020B3C),
      appBar: AppBar(
      title: Text(
        parking!.name,
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context); 
        },
      ),
    ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parking Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parking Info', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildTextField('Name', _nameController),
                    const SizedBox(height: 12),
                    _buildTextField('City', _cityController),
                    const SizedBox(height: 12),
                    _buildTextField('Address', _addressController),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateParking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF340C6C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('Save Changes', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
        
              // Spots Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Spots', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _addSpot,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text('Add Spot', style: GoogleFonts.poppins(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF340C6C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
        
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: spots.length,
                  itemBuilder: (context, index) {
                    final spot = spots[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SpotCard(
                        spot: spot,
                        onDelete: () => _deleteSpot(spot.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white),
      cursorColor: Colors.white70,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white70)),
      ),
    );
  }
}
