import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:user_interface/SCREENS/home/utils/home_map_widget.dart';
import 'package:user_interface/SCREENS/home/utils/home_search_overlay.dart';
import 'package:user_interface/SCREENS/home/utils/parking_details_card.dart';
import 'package:user_interface/SCREENS/login/login_screen.dart';
import 'package:user_interface/SCREENS/start session/start_session_screen.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION HELPERS/secure_storage_service.dart';
import 'package:user_interface/SERVICES/parking_service.dart';
import 'package:user_interface/SERVICES/user_service.dart';
import 'package:user_interface/MODELS/parking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/STATE/map_style_state.dart';

import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ──────────────── CONSTANTS ────────────────
  static const double _distanceLimitKm = 10.0;
  static const double _searchBarHeight = 60.0;
  final int _mapKey = 0;

  // ──────────────── SERVICES ────────────────
  final UserService _userService = UserService();
  final ParkingApiService _parkingService = ParkingApiService();

  // ──────────────── FLAGS / STATE ────────────────
  bool _locationAccessGranted = false;
  bool _isLocationLoading = true;
  bool _isLoading = true;
  bool _areParkingsLoading = true;
  bool _isSearchExpanded = false;
  bool _isNavigating = false;

  // ──────────────── MAP ────────────────
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(0.0, 0.0);
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  BitmapDescriptor? _userLocationIcon;
  BitmapDescriptor? _parkingMarkerIcon;

  // ──────────────── PARKING DATA ────────────────
  Parking? _selectedLot;
  List<Parking> _parkingLots = [];
  List<Parking> _nearbyParkingLots = [];
  List<Parking> _filteredParkingLots = [];
  final Map<int, Parking> _parkingCache = {};

  // ──────────────── SEARCH ────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    _loadAllUserData();
    _loadParkingLots();
    _getUserLocation();
    _loadIcons();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<BitmapDescriptor?> _loadResizedIcon(String assetPath, int width) async {
  try {
    final ByteData byteData = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image largeImage = fi.image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      largeImage,
      Rect.fromLTWH(0, 0, largeImage.width.toDouble(), largeImage.height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), width.toDouble()),
      paint,
    );

    final ui.Image smallImage = await recorder.endRecording().toImage(width, width);
    final ByteData? resizedByteData = await smallImage.toByteData(format: ui.ImageByteFormat.png);

    if (resizedByteData == null) return null;
    return BitmapDescriptor.fromBytes(resizedByteData.buffer.asUint8List());
  } catch (e) {
    debugPrint("Error loading icon $assetPath: $e");
    return null;
  }
}

  void _loadIcons() async {
  final userIcon = await _loadResizedIcon('assets/images/car_location_marker.png', 200);
  final parkingIcon = await _loadResizedIcon('assets/images/parking_marker.png', 200);
  
  if (mounted) {
    setState(() {
      _userLocationIcon = userIcon;
      _parkingMarkerIcon = parkingIcon;
    });
    _filterAndDisplayParkings();
  }
}

  Future<void> _loadAllUserData() async {
    final userDataFuture = _userService.fetchUserProfile();
    final results = await Future.wait([userDataFuture]);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      final userData = results[0];
      if (userData == null && !_isLoading) {
        _handleLogout(context);
      }
    });
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLocationLoading = false;
        _locationAccessGranted = true;
      });

      _filterAndDisplayParkings();
    } catch (e) {
      debugPrint("Errore GPS: $e");
    }
  }

  void _handleLogout(BuildContext context) async {
    final storageService = SecureStorageService();
    await storageService.deleteTokens();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _filterAndDisplayParkings();
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    if (_isNavigating) return;

    if (_searchFocusNode.hasFocus) {
      setState(() {
        _isSearchExpanded = true;
      });
    }
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery;
      _filterAndDisplayParkings();
    });
  }

  void _navigateToStartSession(Parking parkingLot) async {
    setState(() {
      _isNavigating = true;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StartSessionScreen(parkingLot: parkingLot),
      ),
    );

    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _loadParkingLots() async {
    try {
      final lotsData = await _parkingService.fetchLiteParkings();
      if (!mounted) return;
      setState(() {
        _parkingLots = lotsData;
      });
      _filterAndDisplayParkings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _onParkingSelected(Parking lot) async {
    if (_parkingCache.containsKey(lot.id) && _parkingCache[lot.id]!.isDetailsLoaded) {
      setState(() {
        _selectedLot = _parkingCache[lot.id];
      });
      _animateToLot(lot);
      return;
    }
    setState(() => _selectedLot = lot);
    _animateToLot(lot);

    try {
      final fullDetails = await _parkingService.fetchParkingDetails(lot.id);
      if (mounted && _selectedLot?.id == lot.id) {
        setState(() {
          _parkingCache[lot.id] = fullDetails;
          _selectedLot = fullDetails;
        });
      }
    } catch (e) {
      debugPrint("Errore fetch dettagli: $e");
    }
  }

  void _animateToLot(Parking lot) {
    final LatLng lotPosition = LatLng(
      lot.markerLatitude ?? lot.latitude ?? 0.0,
      lot.markerLongitude ?? lot.longitude ?? 0.0,
    );
    _mapController?.animateCamera(CameraUpdate.newLatLng(lotPosition));
  }

  void _applySearchFilter(List<Parking> sourceLots) {
    if (!mounted) return;
    List<Parking> results;
    if (_searchQuery.isEmpty) {
      results = sourceLots;
    } else {
      final lowerCaseQuery = _searchQuery.toLowerCase();
      results = sourceLots.where((lot) {
        return lot.name.toLowerCase().contains(lowerCaseQuery) ||
            lot.city.toLowerCase().contains(lowerCaseQuery) ||
            lot.address.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }
    setState(() {
      _filteredParkingLots = results.map((lot) {
        return _parkingCache[lot.id] ?? lot;
      }).toList();
    });
  }

  Future<void> _prefetchVisibleParkingDetails(List<Parking> visibleLots) async {
    final lotsToFetch = visibleLots.where((lot) => 
      !_parkingCache.containsKey(lot.id) || !(_parkingCache[lot.id]?.isDetailsLoaded ?? false)
    ).toList();

    if (lotsToFetch.isEmpty) return;

    try {
      final List<Future<Parking>> detailFutures = lotsToFetch.map((lot) {
        return _parkingService.fetchParkingDetails(lot.id);
      }).toList();

      final List<Parking> fetchedDetails = await Future.wait(detailFutures);

      if (!mounted) return;

      setState(() {
        for (var fullDetail in fetchedDetails) {
          _parkingCache[fullDetail.id] = fullDetail;
        }
        _updateFilteredListWithCache();
      });
    } catch (e) {
      rethrow;
    }
  }

  void _updateFilteredListWithCache() {
    _areParkingsLoading = false;
    setState(() {
      _filteredParkingLots = _filteredParkingLots.map((lot) {
        return _parkingCache[lot.id] ?? lot;
      }).toList();
    });
  }

  void _filterAndDisplayParkings() {
    if (!mounted) return;
    final Set<Marker> newMarkers = {};
    final Set<Polygon> newPolygons = {};

    final isDarkMode = ref.read(mapStyleProvider);

    if (_locationAccessGranted) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: _userLocationIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );
    }

    _nearbyParkingLots = _parkingLots.where((lot) {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        lot.latitude ?? 0.0,
        lot.longitude ?? 0.0,
      );
      return distanceInMeters <= (_distanceLimitKm * 1000);
    }).toList();

    _applySearchFilter(_nearbyParkingLots);

    if (_filteredParkingLots.isNotEmpty) {
      _prefetchVisibleParkingDetails(_filteredParkingLots);
    }

    for (var lot in _filteredParkingLots) {
      final LatLng lotPosition = LatLng(
        lot.markerLatitude ?? lot.latitude ?? 0.0,
        lot.markerLongitude ?? lot.longitude ?? 0.0,
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId(lot.id.toString()),
          position: lotPosition,
          icon: _parkingMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _onParkingSelected(lot),
        ),
      );

      if (lot.polygonCoords.isNotEmpty) {
        final polygonPoints = lot.polygonCoords
            .map((coord) => LatLng(coord.lat, coord.lng))
            .toList();

        final strokeColor = isDarkMode ? Colors.greenAccent : Colors.indigo;
        final fillColor = isDarkMode
            ? Colors.greenAccent.withOpacity(0.2)
            : Colors.indigoAccent.withOpacity(0.15);

        newPolygons.add(
          Polygon(
            polygonId: PolygonId('polygon_${lot.id}'),
            points: polygonPoints,
            strokeColor: strokeColor,
            strokeWidth: 2,
            fillColor: fillColor,
            consumeTapEvents: true,
            onTap: () => _onParkingSelected(lot),
          ),
        );
      }
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
      _polygons.clear();
      _polygons.addAll(newPolygons);
    });

    if (_mapController != null && newMarkers.isNotEmpty) {
      LatLng targetPosition = _currentPosition;

      if (!_locationAccessGranted && _filteredParkingLots.isNotEmpty) {
        final firstLot = _filteredParkingLots.first;
        targetPosition = LatLng(
          firstLot.markerLatitude ?? firstLot.latitude ?? 0.0,
          firstLot.markerLongitude ?? firstLot.longitude ?? 0.0,
        );
      }

      Future.delayed(const Duration(milliseconds: 50), () {
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(targetPosition, 14.0),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(mapStyleProvider, (previous, next) {
      if (previous != next && mounted) {
        _filterAndDisplayParkings();
      }
    });

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final double topSpace = mediaQuery.padding.top + 20.0 + _searchBarHeight;
    final double bottomSpace = mediaQuery.padding.bottom + 20.0;
    final double maxListHeight = screenHeight - topSpace - bottomSpace;

    return Stack(
      children: [
        HomeMapWidget(
          key: ValueKey(_mapKey),
          locationAccessGranted: _locationAccessGranted,
          currentPosition: _currentPosition,
          markers: _markers,
          polygons: _polygons,
          onMapCreated: _onMapCreated,
          isLoading: _isLocationLoading,
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() {
              _isSearchExpanded = false;
              _selectedLot = null;
            });
          },
          gesturesEnabled: !_isSearchExpanded,
        ),

        ParkingDetailsCard(
          selectedLot: _selectedLot,
          onClose: () => setState(() => _selectedLot = null),
          onStartSession: _navigateToStartSession,
        ),

        HomeSearchOverlay(
          searchBarHeight: _searchBarHeight,
          maxListHeight: maxListHeight,
          controller: _searchController,
          focusNode: _searchFocusNode,
          isSearchExpanded: _isSearchExpanded,
          searchQuery: _searchQuery,
          filteredParkingLots: _filteredParkingLots,
          userPosition: _currentPosition,
          onChanged: _updateSearchQuery,
          onParkingLotTap: _navigateToStartSession,
          isLoading: _areParkingsLoading,
        ),
      ],  
    );
  }
}