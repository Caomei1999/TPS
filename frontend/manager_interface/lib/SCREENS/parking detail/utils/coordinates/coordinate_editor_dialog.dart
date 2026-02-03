import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manager_interface/models/parking.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

Future<List<ParkingCoordinate>?> showCoordinateEditorDialog(
  BuildContext context, {
  required List<ParkingCoordinate> initialCoords,
}) async {
  return showDialog<List<ParkingCoordinate>>(
    context: context,
    builder: (context) => _CoordinateEditorDialog(initialCoords: initialCoords),
  );
}

class _CoordinateEditorDialog extends StatefulWidget {
  final List<ParkingCoordinate> initialCoords;

  const _CoordinateEditorDialog({required this.initialCoords});

  @override
  State<_CoordinateEditorDialog> createState() => _CoordinateEditorDialogState();
}

class _CoordinateEditorDialogState extends State<_CoordinateEditorDialog> {
  late List<ParkingCoordinate> coords;
  late List<_CoordControllers> coordControllers;
  GoogleMapController? _mapController;
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  BitmapDescriptor? _parkingIcon;
  
  double? centerLat;
  double? centerLng;
  final centerLatController = TextEditingController();
  final centerLngController = TextEditingController();

  // Map style JSON
  static const String _mapStyle = '''
[
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
]
''';

  @override
  void initState() {
    super.initState();
    coords = List.from(widget.initialCoords);
    coordControllers = coords.map((c) => _CoordControllers(
      latController: TextEditingController(text: c.lat.toStringAsFixed(6)),
      lngController: TextEditingController(text: c.lng.toStringAsFixed(6)),
    )).toList();
    _calculateCenter();
    _loadCustomParkingIcon();
  }

  @override
  void dispose() {
    centerLatController.dispose();
    centerLngController.dispose();
    for (var controller in coordControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCustomParkingIcon() async {
    final ByteData byteData = await rootBundle.load(
      'assets/images/parking_marker.png',
    );

    final ui.Codec codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: 70,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    final ByteData? resizedByteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (!mounted || resizedByteData == null) return;

    setState(() {
      _parkingIcon = BitmapDescriptor.fromBytes(
        resizedByteData.buffer.asUint8List(),
      );
      _updateMap();
    });
  }

  void _calculateCenter() {
    if (coords.isEmpty) {
      centerLat = 41.8719;
      centerLng = 12.5674;
    } else {
      centerLat = coords.map((c) => c.lat).reduce((a, b) => a + b) / coords.length;
      centerLng = coords.map((c) => c.lng).reduce((a, b) => a + b) / coords.length;
    }
    centerLatController.text = centerLat!.toStringAsFixed(6);
    centerLngController.text = centerLng!.toStringAsFixed(6);
  }

  void _updateMap() {
    if (coords.isNotEmpty) {
      _polygons = {
        Polygon(
          polygonId: const PolygonId('preview'),
          points: coords.map((c) => LatLng(c.lat, c.lng)).toList(),
          strokeColor: const Color.fromARGB(255, 52, 12, 108),
          strokeWidth: 3,
          fillColor: const Color.fromARGB(255, 52, 12, 108).withOpacity(0.3),
        ),
      };

      _markers = {
        Marker(
          markerId: const MarkerId('center'),
          position: LatLng(centerLat!, centerLng!),
          icon: _parkingIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          consumeTapEvents: false, // Make marker non-clickable
        ),
      };

      // Calculate bounds to fit polygon
      if (coords.length > 1) {
        double minLat = coords.map((c) => c.lat).reduce((a, b) => a < b ? a : b);
        double maxLat = coords.map((c) => c.lat).reduce((a, b) => a > b ? a : b);
        double minLng = coords.map((c) => c.lng).reduce((a, b) => a < b ? a : b);
        double maxLng = coords.map((c) => c.lng).reduce((a, b) => a > b ? a : b);

        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50), // 50 pixels padding
        );
      } else {
        // Single point, use default zoom
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(centerLat!, centerLng!), 17),
        );
      }
    }
  }

  void _addPoint() {
    final latController = TextEditingController();
    final lngController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 52, 12, 108),
        title: Text('Add Point', style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(latController, 'Latitude'),
            const SizedBox(height: 10),
            _buildTextField(lngController, 'Longitude'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);

              if (lat == null || lng == null) {
                _showError('Invalid coordinate format');
                return;
              }

              if (lat < -90 || lat > 90) {
                _showError('Latitude must be between -90 and 90');
                return;
              }

              if (lng < -180 || lng > 180) {
                _showError('Longitude must be between -180 and 180');
                return;
              }

              final isDuplicate = coords.any((c) =>
                  (c.lat - lat).abs() < 0.000001 && (c.lng - lng).abs() < 0.000001);

              if (isDuplicate) {
                _showError('Point already exists');
                return;
              }

              setState(() {
                coords.add(ParkingCoordinate(lat: lat, lng: lng));
                coordControllers.add(_CoordControllers(
                  latController: TextEditingController(text: lat.toStringAsFixed(6)),
                  lngController: TextEditingController(text: lng.toStringAsFixed(6)),
                ));
                _calculateCenter();
                _updateMap();
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            child: Text('Add', style: GoogleFonts.poppins(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _updateCoordinate(int index, String field, String value) {
    final numValue = double.tryParse(value);
    if (numValue == null) return;

    setState(() {
      if (field == 'lat') {
        coords[index] = ParkingCoordinate(lat: numValue, lng: coords[index].lng);
      } else {
        coords[index] = ParkingCoordinate(lat: coords[index].lat, lng: numValue);
      }
      _calculateCenter();
      _updateMap();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.fromARGB(255, 52, 12, 108),
              Color.fromARGB(255, 2, 11, 60),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Map Preview',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Map Preview
                  Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(centerLat ?? 41.8719, centerLng ?? 12.5674),
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _mapController?.setMapStyle(_mapStyle);
                          _updateMap();
                        },
                        polygons: _polygons,
                        markers: _markers,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Right: Coordinates Editor
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Center Coordinates',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: centerLatController,
                                enabled: false,
                                style: const TextStyle(color: Colors.white70),
                                decoration: InputDecoration(
                                  labelText: 'Latitude',
                                  labelStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: centerLngController,
                                enabled: false,
                                style: const TextStyle(color: Colors.white70),
                                decoration: InputDecoration(
                                  labelText: 'Longitude',
                                  labelStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Polygon Points (${coords.length})',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addPoint,
                              icon: const Icon(Icons.add_location_alt, size: 16),
                              label: Text('Add', style: GoogleFonts.poppins(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        Expanded(
                          child: ListView.builder(
                            itemCount: coords.length,
                            itemBuilder: (context, index) {
                              final controllers = coordControllers[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${index + 1}.',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: controllers.latController,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.all(8),
                                          filled: true,
                                          fillColor: Colors.white10,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onChanged: (value) => _updateCoordinate(index, 'lat', value),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: controllers.lngController,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.all(8),
                                          filled: true,
                                          fillColor: Colors.white10,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onChanged: (value) => _updateCoordinate(index, 'lng', value),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          coords.removeAt(index);
                                          coordControllers[index].dispose();
                                          coordControllers.removeAt(index);
                                          _calculateCenter();
                                          _updateMap();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, coords),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to manage controllers for each coordinate
class _CoordControllers {
  final TextEditingController latController;
  final TextEditingController lngController;

  _CoordControllers({
    required this.latController,
    required this.lngController,
  });

  void dispose() {
    latController.dispose();
    lngController.dispose();
  }
}
