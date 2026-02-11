import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

class HomeSearchBar extends StatelessWidget {
  final double searchBarHeight;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final bool isLoading; // New parameter

  const HomeSearchBar({
    super.key,
    required this.searchBarHeight,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.isLoading, // Require it in constructor
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: searchBarHeight,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          final bool hasText = value.text.isNotEmpty;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading, 
              style: GoogleFonts.poppins(color: Colors.indigoAccent, fontSize: 20),
              cursorColor: Colors.indigoAccent,
              decoration: InputDecoration(
                hintText: isLoading 
                    ? 'Loading parking infos...' 
                    : 'Search Parkings in Your Area...',
                hintStyle: GoogleFonts.poppins(color: Colors.indigoAccent),

                prefixIcon: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.indigoAccent,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : const Icon(IconlyLight.search, color: Colors.indigoAccent),
                
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                
                suffixIcon: hasText && !isLoading
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.indigoAccent),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: onChanged,
            ),
          );
        },
      ),
    );
  }
}