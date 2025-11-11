import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/SERVICES/parking_service.dart';

// Importa i modelli e utility necessari per il dettaglio delle sessioni

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final ParkingApiService _parkingService = ParkingApiService();
  List<Map<String, dynamic>> _activeSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  void _fetchSessions() async {
    final sessions = await _parkingService.fetchActiveSessions(); 
    
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _activeSessions = sessions ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final background = Container(
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
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            background, 
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsets.only(left: 20, top: 10, bottom: 20),
                      child: Text(
                        'My Parking Sessions',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    _buildContent(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50.0),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_activeSessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 20, top: 50),
        child: Text(
          'You have no active sessions...',
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
      );
    }

    // Caso: Sessioni Attive Presenti
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _activeSessions.map((session) {
          return _buildSessionTile(session, context);
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------------------------
  // WIDGET PER UNA SINGOLA SESSIONE (TILE)
  // ------------------------------------------------------------------
  Widget _buildSessionTile(Map<String, dynamic> session, BuildContext context) {
    // Recupero dati (assumendo che le chiavi esistano nel JSON di risposta)
    final plate = session['vehicle_plate'] ?? 'N/A';
    final lotName = session['parking_lot_name'] ?? 'N/A';
    final spotId = session['parking_spot_identifier'] ?? 'N/A';
    final startTime = DateTime.parse(session['start_time']);
    
    // Esempio di calcolo del tempo trascorso (necessario per UX)
    final duration = DateTime.now().difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Card(
      color: Colors.white.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const Icon(Icons.time_to_leave, color: Colors.cyan, size: 30),
        title: Text(
          lotName,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Spot: $spotId | Plate: $plate\nTime: ${hours}h ${minutes}m',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // TODO: Logica per terminare la sosta
            _handleEndSession(session['id'] as int);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: const Text('END', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
  
  // Funzione per terminare la sosta (da integrare)
  void _handleEndSession(int sessionId) async {
    final result = await _parkingService.endSession(sessionId: sessionId);
    
    if (!mounted) return;
    
    if (result != null && result.containsKey('id')) {
        // Successo: Ricarica i dati per rimuovere la sessione terminata
        _fetchSessions(); 
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sosta terminata con successo!"))
        );
    } else {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Errore nel terminare la sosta."))
        );
    }
  }
}