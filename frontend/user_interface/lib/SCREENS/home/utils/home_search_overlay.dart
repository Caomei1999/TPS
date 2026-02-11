import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_interface/MODELS/parking.dart';
import 'package:user_interface/SCREENS/home/utils/home_search_bar.dart';
import 'package:user_interface/SCREENS/home/utils/home_search_result_list.dart';

class HomeSearchOverlay extends StatelessWidget {
  final double searchBarHeight;
  final double maxListHeight;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearchExpanded;
  final String searchQuery;
  final List<Parking> filteredParkingLots;
  final LatLng userPosition;
  final ValueChanged<String> onChanged;
  final Function(Parking) onParkingLotTap;
  final bool isLoading; 

  const HomeSearchOverlay({
    super.key,
    required this.searchBarHeight,
    required this.maxListHeight,
    required this.controller,
    required this.focusNode,
    required this.isSearchExpanded,
    required this.searchQuery,
    required this.filteredParkingLots,
    required this.userPosition,
    required this.onChanged,
    required this.onParkingLotTap,
    required this.isLoading, 
  });

  @override
  Widget build(BuildContext context) {
    const searchBarColor = Color.fromARGB(255, 6, 20, 43);

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(30),
              color: searchBarColor,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeSearchBar(
                    searchBarHeight: searchBarHeight,
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    isLoading: isLoading, 
                  ),
                  if (isSearchExpanded && !isLoading)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxListHeight > 0 ? maxListHeight : 0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: HomeSearchResultsList(
                          searchQuery: searchQuery,
                          filteredParkingLots: filteredParkingLots,
                          userPosition: userPosition,
                          onParkingLotTap: onParkingLotTap,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}