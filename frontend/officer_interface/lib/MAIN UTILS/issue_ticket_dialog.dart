import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Classe di supporto per restituire i dati al padre
class TicketData {
  final String reason;
  final String notes;
  final File? image;

  TicketData({required this.reason, required this.notes, this.image});
}

class IssueTicketDialog extends StatefulWidget {
  final String plate;
  final int? sessionId;

  const IssueTicketDialog({
    super.key,
    required this.plate,
    this.sessionId,
  });

  @override
  State<IssueTicketDialog> createState() => _IssueTicketDialogState();
}

class _IssueTicketDialogState extends State<IssueTicketDialog> {
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  // Mappa delle violazioni e dei costi
  final Map<String, double> _violationTypes = {
    'No Active Session': 50.00,
    'Obstructing Parking': 85.00,
    'Handicapped Zone Violation': 150.00,
  };

  late String _selectedReason;

  @override
  void initState() {
    super.initState();
    _selectedReason = _violationTypes.keys.first; // Default
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 50
    );
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double currentPrice = _violationTypes[_selectedReason]!;

    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 2, 11, 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Issue Violation Ticket",
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dati Immutabili (senza icone, testo più grande)
            _buildReadOnlyField("License Plate", widget.plate, isBig: true),
            const SizedBox(height: 10),
            _buildReadOnlyField("Session ID", widget.sessionId != null ? "#${widget.sessionId}" : "N/A", isBig: true),
            
            const Divider(color: Colors.white24, height: 25),

            // Selezione Violazione
            Text("Violation Type", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  dropdownColor: const Color.fromARGB(255, 10, 20, 50),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  style: GoogleFonts.poppins(color: Colors.white),
                  items: _violationTypes.keys.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Prezzo Dinamico
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Fine Amount: ",
                  style: GoogleFonts.poppins(color: Colors.white54),
                ),
                Text(
                  "€ ${currentPrice.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 18
                  ),
                ),
              ],
            ),

            const Divider(color: Colors.white24, height: 25),

            // Foto Prove
            Text("Evidence Photo", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.white54, size: 30),
                          const SizedBox(height: 5),
                          Text("Tap to take photo", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            // Note
            Text("Officer Notes", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 5),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add specific details...",
                hintStyle: GoogleFonts.poppins(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            // Ritorna l'oggetto completo
            Navigator.pop(context, TicketData(
              reason: _selectedReason,
              notes: _notesController.text.trim(),
              image: _selectedImage
            ));
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: Text("ISSUE TICKET", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  // Modificato: niente icona, testo più grande se isBig=true
  Widget _buildReadOnlyField(String label, String value, {bool isBig = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: isBig ? 22 : 16,
            letterSpacing: isBig ? 1.2 : 0,
          ),
        ),
      ],
    );
  }
}