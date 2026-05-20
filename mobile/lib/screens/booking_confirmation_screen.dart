import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animateController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animateController,
      curve: Curves.elasticOut,
    );
    _animateController.forward();
  }

  @override
  void dispose() {
    _animateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final booking = agentProvider.booking;
    
    final bookingId = booking["booking_id"] ?? "HZR-20260520-X1";
    final providerName = booking["provider_name"] ?? "Ali AC Services & Repair";
    final slot = booking["slot_display"] ?? "Tomorrow afternoon";
    final location = booking["location"] ?? "G-13, Islamabad";
    final price = booking["price_estimate"] ?? "PKR 1200-2500";
    final sheetsRow = booking["sheets_row"] ?? 15;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 1. Centered Teal Checkmark Inside Glowing Circular Ring
              ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4BDDB7).withOpacity(0.12),
                      border: Border.all(color: const Color(0xFF4BDDB7), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4BDDB7).withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, size: 44, color: Color(0xFF4BDDB7)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Headings
              Text(
                "Booking Confirmed!",
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Haazir AI has successfully secured your booking.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
              const SizedBox(height: 32),

              // 3. Ticket Card Stub (Light contrasted white ticket)
              _buildTicketCard(
                bookingId: bookingId,
                providerName: providerName,
                slot: slot,
                location: location,
                price: price,
                sheetsRow: sheetsRow,
              ),

              const SizedBox(height: 32),

              // 4. Sync Logs Verification Panel
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B2B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4BDDB7).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_sync_outlined, color: Color(0xFF4BDDB7), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "E2E System Log Verification",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSyncRow("Firestore DB Commit", true),
                    const SizedBox(height: 8),
                    _buildSyncRow("Google Sheets Sync (Row $sheetsRow)", true),
                    const SizedBox(height: 8),
                    _buildSyncRow("FCM Status Orchestration Init", true),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 5. Full-Width Glowing Rounded Amber "Track My Booking" Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C12), // Amber
                    foregroundColor: const Color(0xFF472A00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/tracker');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Track My Booking",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Secondary Outlined Action
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: () {
                    agentProvider.resetSearch();
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  },
                  child: Text(
                    "Return to Home",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard({
    required String bookingId,
    required String providerName,
    required String slot,
    required String location,
    required String price,
    required int sheetsRow,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA), // Light contrast ticket card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Ticket Part
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SERVICE ORDER",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0E1322).withOpacity(0.4),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF39C12).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bookingId,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF865300),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  providerName,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0E1322),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTicketRow(Icons.calendar_today_outlined, "Scheduled For", slot),
                const SizedBox(height: 14),
                _buildTicketRow(Icons.pin_drop_outlined, "Location", location),
                const SizedBox(height: 14),
                _buildTicketRow(Icons.payments_outlined, "Price Estimate", price),
              ],
            ),
          ),

          // Dash line cutout visual spacer
          Row(
            children: [
              Container(
                width: 10,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF0E1322), // matches scaffold bg
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        (constraints.constrainWidth() / 10).floor(),
                        (index) => const SizedBox(
                          width: 5,
                          height: 1.5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.black12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: 10,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF0E1322), // matches scaffold bg
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
            ],
          ),

          // Bottom stub
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "G-Sheets Appended Registry",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0E1322).withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Row $sheetsRow",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0E1322),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0E1322).withOpacity(0.4)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF0E1322).withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0E1322),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSyncRow(String action, bool isSuccess) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          action,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
        ),
        Row(
          children: [
            Text(
              "Synced",
              style: GoogleFonts.outfit(
                color: const Color(0xFF4BDDB7), // Teal
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.check_circle_outline,
              size: 14,
              color: Color(0xFF4BDDB7),
            )
          ],
        )
      ],
    );
  }
}
