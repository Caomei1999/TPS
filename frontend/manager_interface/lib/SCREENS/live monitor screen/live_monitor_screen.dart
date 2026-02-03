import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:manager_interface/models/parking_session.dart';
import 'package:manager_interface/services/parking_service.dart';
import 'package:manager_interface/services/officer_service.dart';

class LiveMonitorScreen extends StatefulWidget {
  final int parkingId;
  final String parkingName;
  final String parkingCity;

  const LiveMonitorScreen({
    super.key,
    required this.parkingId,
    required this.parkingName,
    required this.parkingCity,
  });

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  List<ParkingSession> sessions = [];
  List<ActiveOfficer> activeOfficers = [];
  bool isLoading = true;
  bool isLoadingOfficers = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadData(isBackground: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool isBackground = false}) async {
    await Future.wait([
      _loadSessions(isBackground: isBackground),
      _loadActiveOfficers(isBackground: isBackground),
    ]);
  }

  Future<void> _loadSessions({bool isBackground = false}) async {
    if (!isBackground) setState(() => isLoading = true);
    try {
      final data = await ParkingService.getLiveSessions(widget.parkingId);
      if (mounted) {
        setState(() {
          sessions = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        if (!isBackground) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading sessions: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadActiveOfficers({bool isBackground = false}) async {
    if (!isBackground) setState(() => isLoadingOfficers = true);
    try {
      final officers = await OfficerService.getActiveOfficers(widget.parkingCity);
      if (mounted) {
        setState(() {
          activeOfficers = officers;
          isLoadingOfficers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingOfficers = false);
      }
    }
  }

  String _calculateDuration(DateTime start) {
    final diff = DateTime.now().difference(start.toLocal());
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B3C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Monitor',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
            ),
            Text(
              widget.parkingName,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Row(
          children: [
            // Left side - Sessions list
            Expanded(
              flex: 7,
              child: _buildSessionsList(),
            ),
            
            // Right side - Active officers
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  border: Border(
                    left: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: _buildOfficersPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_parking, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No active sessions',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildOfficersPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.badge, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Active Officers',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLoadingOfficers)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.parkingCity,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildOfficersList(),
        ),
      ],
    );
  }

  Widget _buildOfficersList() {
    if (isLoadingOfficers && activeOfficers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    if (activeOfficers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No active officers\nin this area',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: activeOfficers.length,
      itemBuilder: (context, index) {
        final officer = activeOfficers[index];
        return _buildOfficerCard(officer);
      },
    );
  }

  Widget _buildOfficerCard(ActiveOfficer officer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  officer.fullName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            officer.email,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'On Duty: ${officer.formattedDuration}',
              style: GoogleFonts.poppins(
                color: Colors.greenAccent,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ParkingSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    session.vehiclePlate,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                session.vehicleName,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.poppins(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _calculateDuration(session.startTime),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Since ${DateFormat('HH:mm').format(session.startTime.toLocal())}',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}