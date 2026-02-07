import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:user_interface/MAIN%20UTILS/app_theme.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/support_page.dart';
import 'package:user_interface/SCREENS/payment/choose_payment_method_screen.dart';
import 'package:user_interface/STATE/payment_state.dart';
import 'package:user_interface/SERVICES/violation_service.dart'; // Importa il service creato sopra

enum PaymentConfirmAction { cancel, changeMethod, confirm }

class ViolationsScreen extends ConsumerStatefulWidget {
  const ViolationsScreen({super.key});

  @override
  ConsumerState<ViolationsScreen> createState() => _ViolationsScreenState();
}

class _ViolationsScreenState extends ConsumerState<ViolationsScreen> {
  final ViolationService _violationService = ViolationService();
  bool _isLoading = true;
  List<dynamic> _fines = [];

  @override
  void initState() {
    super.initState();
    _loadFines();
  }

  Future<void> _loadFines() async {
    setState(() => _isLoading = true);
    final fines = await _violationService.fetchMyFines();
    if (mounted) {
      setState(() {
        _fines = fines;
        _isLoading = false;
      });
    }
  }

  // --- LOGICA DI PAGAMENTO COPIATA E ADATTATA DA StartSessionScreen ---
  Future<void> _handlePayFine(Map<String, dynamic> fine) async {
    final double amount = double.parse(fine['amount'].toString());
    final String fineIdStr = "#${fine['id']}";
    final String plate = fine['vehicle_plate'];

    // 1. Check Default Method
    final payState = ref.read(paymentProvider);
    if (!payState.hasDefaultMethod) {
      final chosen = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const ChoosePaymentMethodScreen()),
      );
      if (chosen != true) return;
    }

    // 2. Confirm Dialog Loop
    while (true) {
      final payLabel = ref.read(paymentProvider).defaultMethodLabel;

      final action = await showDialog<PaymentConfirmAction>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF020B3C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Confirm Fine Payment',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaymentSummary(fineIdStr, plate, amount),
                const SizedBox(height: 12),
                Text(
                  'Payment method',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          payLabel,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                      const Icon(Icons.payment, color: Colors.white54, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      PaymentConfirmAction.changeMethod,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: Text(
                      'Change method',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Paying this fine will reduce your violation count by 1.',
                  style: GoogleFonts.poppins(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, PaymentConfirmAction.cancel),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, PaymentConfirmAction.confirm),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                  ),
                  child: Text(
                    'Pay Now',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (action == null || action == PaymentConfirmAction.cancel) return;

      if (action == PaymentConfirmAction.changeMethod) {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const ChoosePaymentMethodScreen()),
        );
        if (changed == true) continue;
        continue;
      }
      break; // Confirm
    }

    // 3. Process Payment
    setState(() => _isLoading = true);
    
    // Simulate Payment Provider Charge
    await ref.read(paymentProvider.notifier).charge(amount, reason: 'Fine Payment $fineIdStr');

    final success = await _violationService.payFine(fine['id']);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fine paid! Violation count decreased."),
            backgroundColor: Colors.green,
          ),
        );
        _loadFines(); // Ricarica la lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPaymentSummary(String fineId, String plate, double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Fine ID", style: GoogleFonts.poppins(color: Colors.white70)),
              Text(fineId, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Vehicle", style: GoogleFonts.poppins(color: Colors.white70)),
              Text(plate, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white24, height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Amount", style: GoogleFonts.poppins(color: Colors.white70)),
              Text(
                "€${amount.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Manage Violations',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _fines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(IconlyLight.shield_done, color: Colors.greenAccent, size: 60),
                          const SizedBox(height: 20),
                          Text(
                            "No Violations Found",
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "You are a good driver!",
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _fines.length,
                      itemBuilder: (ctx, index) {
                        final fine = _fines[index];
                        return _buildFineCard(fine);
                      },
                    ),
        ),
      ),
    );
  }

  Future<void> _handleContestDialog(Map<String, dynamic> fine) async {
    final TextEditingController reasonController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF020B3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Contest Violation",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Please explain why you believe this fine is incorrect:",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter your reason here...",
                  hintStyle: GoogleFonts.poppins(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              
              // LINK ALLA SUPPORT PAGE
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx); // Chiude il dialog
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const SupportPage())
                  );
                },
                child: Row(
                  children: [
                    const Icon(IconlyBold.info_circle, color: Colors.blueAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Need help? Go to Support",
                      style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              Navigator.pop(ctx); // Chiude Dialog
              setState(() => _isLoading = true);

              final success = await _violationService.contestFine(fine['id'], reason);

              if (mounted) {
                setState(() => _isLoading = false);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contestation submitted successfully.")),
                  );
                  _loadFines(); // Ricarica
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to submit. Try again."), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text("Submit", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFineCard(Map<String, dynamic> fine) {
    final status = fine['status']; // 'paid', 'unpaid', 'disputed', 'cancelled'
    final contestationReason = fine['contestation_reason']; // Se esiste, l'utente ha provato a contestare
    
    // Logica Stati
    bool isPaid = status == 'paid';
    bool isCancelled = status == 'cancelled'; // Accettata dall'admin
    bool isDisputed = status == 'disputed';   // In attesa
    
    // Se è 'unpaid' MA c'è una 'contestation_reason', significa che l'admin l'ha rifiutata
    // e l'ha rimessa come 'unpaid'.
    bool isRejected = (status == 'unpaid' && contestationReason != null && contestationReason.toString().isNotEmpty);

    final date = DateTime.parse(fine['issued_at']);
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

    // Colore bordo
    Color borderColor = Colors.redAccent.withOpacity(0.5);
    if (isPaid) borderColor = Colors.greenAccent.withOpacity(0.3);
    if (isCancelled) borderColor = Colors.blueAccent.withOpacity(0.5);
    if (isDisputed) borderColor = Colors.amber.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fine['reason'] ?? "Violation",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildStatusBadge(status, isRejected),
            ],
          ),
          
          const SizedBox(height: 10),
          Text("Plate: ${fine['vehicle_plate']}", style: GoogleFonts.poppins(color: Colors.white70)),
          Text("Date: $formattedDate", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          
          // Se c'è una contestazione (in attesa o rifiutata) mostriamo la nota dell'utente
          if (contestationReason != null && contestationReason.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Your Contestation:", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
                  Text(
                    contestationReason,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 15),
          
          // Footer Row: Prezzo e Bottoni
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "€${fine['amount']}",
                style: GoogleFonts.poppins(
                  color: isCancelled ? Colors.white38 : Colors.white, // Se cancellata, sfuma il prezzo
                  fontSize: 20,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // LOGICA BOTTONI
              if (status == 'unpaid') ...[
                 Row(
                   children: [
                     // Tasto Contestare (Giallo)
                     InkWell(
                       onTap: () => _handleContestDialog(fine),
                       child: Container(
                         padding: const EdgeInsets.all(10),
                         decoration: BoxDecoration(
                           color: Colors.amber.withOpacity(0.2),
                           borderRadius: BorderRadius.circular(10),
                           border: Border.all(color: Colors.amber)
                         ),
                         child: const Icon(Icons.gavel_outlined, color: Colors.amber, size: 20),
                       ),
                     ),
                     const SizedBox(width: 10),
                     // Tasto Paga (Rosso)
                     ElevatedButton(
                        onPressed: () => _handlePayFine(fine),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("PAY NOW"),
                      ),
                   ],
                 )
              ] else if (isDisputed) ...[
                 Text(
                   "Review Pending...",
                   style: GoogleFonts.poppins(color: Colors.amber, fontStyle: FontStyle.italic),
                 )
              ] else if (isCancelled) ...[
                 Text(
                   "Fine Revoked",
                   style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                 )
              ]
            ],
          ),
          
          // Messaggio specifico per Rejected (torna unpaid ma con avviso)
          if (isRejected)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Contestation Rejected. Please pay the fine.",
                style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isRejected) {
    String text = status.toUpperCase();
    Color color = Colors.grey;

    if (status == 'paid') {
      color = Colors.greenAccent;
    } else if (status == 'disputed') {
      text = "PENDING";
      color = Colors.amber;
    } else if (status == 'cancelled') {
      text = "ACCEPTED";
      color = Colors.blueAccent;
    } else if (isRejected) {
      text = "REJECTED";
      color = Colors.red;
    } else {
      text = "UNPAID";
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}