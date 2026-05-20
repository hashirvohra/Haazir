import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/agent_service.dart';

class ActiveBookingTrackerScreen extends StatefulWidget {
  const ActiveBookingTrackerScreen({super.key});

  @override
  State<ActiveBookingTrackerScreen> createState() => _ActiveBookingTrackerScreenState();
}

class _ActiveBookingTrackerScreenState extends State<ActiveBookingTrackerScreen> {
  String _currentStatus = "confirmed"; // confirmed -> assigned -> en_route -> arrived -> completed
  int _statusStep = 0;
  Timer? _statusTimer;
  int _userRating = 0;
  bool _feedbackSubmitted = false;

  final List<Map<String, String>> _statusSteps = [
    {"id": "confirmed", "title": "Booking Confirmed", "desc": "Order verified by Antigravity engine"},
    {"id": "assigned", "title": "Partner Assigned", "desc": "Ali AC Services & Repair accepted request"},
    {"id": "en_route", "title": "En Route", "desc": "Partner is traveling to your G-13 location"},
    {"id": "arrived", "title": "Arrived", "desc": "Partner has arrived at G-13, Islamabad"},
    {"id": "completed", "title": "Job Completed", "desc": "Service finished. Please provide feedback"},
  ];

  @override
  void initState() {
    super.initState();
    // Simulate real-time status progression for the demo every 8 seconds
    _statusTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_statusStep < _statusSteps.length - 1) {
        setState(() {
          _statusStep++;
          _currentStatus = _statusSteps[_statusStep]["id"]!;
        });
        
        final agentProvider = Provider.of<AgentProvider>(context, listen: false);
        final bookingId = agentProvider.booking["booking_id"] ?? "HZR-20260520-X1";
        agentProvider.updateBookingStatus(bookingId, _currentStatus);

        _showFakeNotificationBanner(
          _statusSteps[_statusStep]["title"]!,
          _statusSteps[_statusStep]["desc"]!,
        );
      } else {
        _statusTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _showFakeNotificationBanner(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161B2B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFF39C12), width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFFF39C12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FCM PUSH: $title",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _advanceStepManually() {
    if (_statusStep < _statusSteps.length - 1) {
      setState(() {
        _statusStep++;
        _currentStatus = _statusSteps[_statusStep]["id"]!;
      });
      
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final bookingId = agentProvider.booking["booking_id"] ?? "HZR-20260520-X1";
      agentProvider.updateBookingStatus(bookingId, _currentStatus);

      _showFakeNotificationBanner(
        _statusSteps[_statusStep]["title"]!,
        _statusSteps[_statusStep]["desc"]!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final booking = agentProvider.booking;
    final bookingId = booking["booking_id"] ?? "HZR-20260520-X1";
    final providerName = booking["provider_name"] ?? "Ali AC Services & Repair";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Haazir Live ETA",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_statusStep < _statusSteps.length - 1)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                icon: const Icon(Icons.fast_forward_rounded, size: 16, color: Color(0xFFF39C12)),
                label: Text(
                  "Next Stage",
                  style: GoogleFonts.outfit(color: const Color(0xFFF39C12), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _advanceStepManually,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Provider Card with green circle avatar and verified badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B2B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    // Provider Avatar
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF02B894), // Green circle avatar
                            shape: BoxShape.circle,
                          ),
                          child: const Text("👨‍🔧", style: TextStyle(fontSize: 24)),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Color(0xFF4BDDB7), // verified badge
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            providerName,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF39C12), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "4.8 Rating",
                                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "AC Expert",
                                style: GoogleFonts.outfit(color: const Color(0xFF4BDDB7), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Call Button
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk_outlined, color: Color(0xFF4BDDB7)),
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Colors.white12),
                        padding: const EdgeInsets.all(10),
                      ),
                      onPressed: () {
                        _showFakeNotificationBanner("Mock Call Dialed", "Calling provider at +92 300 1234567...");
                      },
                    )
                  ],
                ),
              ),
            ),

            // 2. Middle Map Card & custom Vertical Stepper Split
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Stylized Dark Map Card featuring a glowing teal path
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B2B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Vector style dark grid background
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.05,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                                itemCount: 100,
                                itemBuilder: (context, idx) => Container(
                                  decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 0.5)),
                                ),
                              ),
                            ),
                          ),
                          // Stylized map path custom painter
                          Center(
                            child: CustomPaint(
                              size: const Size(double.infinity, 180),
                              painter: MapPathPainter(_statusStep),
                            ),
                          ),
                          // Custom styled home and car marker overlays
                          const Positioned(
                            top: 40,
                            left: 50,
                            child: Column(
                              children: [
                                Icon(Icons.home_filled, color: Color(0xFF4BDDB7), size: 24),
                                SizedBox(height: 2),
                                Text(
                                  "G-13 Home",
                                  style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: _statusStep == 0
                                ? 20
                                : _statusStep == 1
                                    ? 40
                                    : _statusStep == 2
                                        ? 70
                                        : _statusStep == 3
                                            ? 110
                                            : 110,
                            right: _statusStep == 0
                                ? 30
                                : _statusStep == 1
                                    ? 70
                                    : _statusStep == 2
                                        ? 130
                                        : _statusStep == 3
                                            ? 250
                                            : 250,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF39C12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF472A00), size: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Ali en route",
                                  style: GoogleFonts.outfit(color: const Color(0xFFF39C12), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Custom Vertical Timeline Stepper
                    Column(
                      children: List.generate(_statusSteps.length, (idx) {
                        final step = _statusSteps[idx];
                        final isCompleted = idx < _statusStep;
                        final isActive = idx == _statusStep;
                        final isLast = idx == _statusSteps.length - 1;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Stepper Line & Dot
                              Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted
                                          ? const Color(0xFFF39C12) // Amber checkmark circle
                                          : isActive
                                              ? const Color(0xFF4BDDB7) // Solid glowing teal circle
                                              : Colors.transparent,
                                      border: Border.all(
                                        color: isCompleted
                                            ? const Color(0xFFF39C12)
                                            : isActive
                                                ? const Color(0xFF4BDDB7)
                                                : Colors.white24,
                                        width: 2,
                                      ),
                                    ),
                                    child: isCompleted
                                        ? const Icon(Icons.check, size: 14, color: Color(0xFF472A00))
                                        : isActive
                                            ? const Center(
                                                child: SizedBox(
                                                  width: 10,
                                                  height: 10,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.0,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00382B)),
                                                  ),
                                                ),
                                              )
                                            : null,
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        color: isCompleted ? const Color(0xFFF39C12) : Colors.white10,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Description
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step["title"]!,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isActive
                                              ? const Color(0xFF4BDDB7)
                                              : isCompleted
                                                  ? Colors.white
                                                  : Colors.white38,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        step["desc"]!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isActive
                                              ? Colors.white70
                                              : isCompleted
                                                  ? Colors.white54
                                                  : Colors.white24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating bottom Action bar or Feedback Form
            _currentStatus == "completed"
                ? _buildFeedbackCard(bookingId, agentProvider)
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF161B2B),
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              _showFakeNotificationBanner("Booking Cancelled", "Cancellation request sent to Antigravity.");
                              agentProvider.updateBookingStatus(bookingId, "cancelled");
                              final navigator = Navigator.of(context);
                              Future.delayed(const Duration(seconds: 1), () {
                                agentProvider.resetSearch();
                                navigator.pushNamedAndRemoveUntil('/home', (route) => false);
                              });
                            },
                            child: Text(
                              "Cancel Booking",
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4BDDB7), // Teal
                              foregroundColor: const Color(0xFF00382B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              _showFakeNotificationBanner("Mock Call Dialed", "Calling provider at +92 300 1234567...");
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "Call Provider",
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(String bookingId, AgentProvider agentProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF161B2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Share Your Experience",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            "Rate Ali AC Services & Repair to finalize the booking",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Rating Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (idx) {
              final starNum = idx + 1;
              final isLit = starNum <= _userRating;
              return IconButton(
                icon: Icon(
                  isLit ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF39C12),
                  size: 38,
                ),
                onPressed: _feedbackSubmitted
                    ? null
                    : () {
                        setState(() {
                          _userRating = starNum;
                        });
                      },
              );
            }),
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _feedbackSubmitted ? const Color(0xFF02B894).withOpacity(0.5) : const Color(0xFF02B894),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _userRating == 0 || _feedbackSubmitted
                  ? null
                  : () async {
                      setState(() {
                        _feedbackSubmitted = true;
                      });
                      
                      // Submit rating
                      await AgentService.rateBooking(bookingId, _userRating);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Thank you! Feedback recorded successfully in Firestore.")),
                        );
                        
                        agentProvider.updateBookingStatus(bookingId, "completed");

                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            agentProvider.resetSearch();
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                          }
                        });
                      }
                    },
              child: Text(
                _feedbackSubmitted ? "Rating Submitted!" : "Submit Feedback",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapPathPainter extends CustomPainter {
  final int step;
  MapPathPainter(this.step);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw glowing background path representing road structure
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadPath = Path()
      ..moveTo(size.width * 0.85, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.9,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..lineTo(size.width * 0.2, size.height * 0.3);

    canvas.drawPath(roadPath, roadPaint);

    // 2. Draw standard dotted path connecting both ends
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(roadPath, paint);

    // 3. Draw active colored glowing teal path section
    if (step > 0) {
      final activePaint = Paint()
        ..color = const Color(0xFF4BDDB7) // glowing teal path
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final activePath = Path()..moveTo(size.width * 0.85, size.height * 0.75);

      if (step == 1) {
        activePath.lineTo(size.width * 0.75, size.height * 0.8);
      } else if (step == 2) {
        activePath.quadraticBezierTo(
          size.width * 0.6,
          size.height * 0.9,
          size.width * 0.5,
          size.height * 0.5,
        );
      } else {
        activePath.quadraticBezierTo(
          size.width * 0.6,
          size.height * 0.9,
          size.width * 0.5,
          size.height * 0.5,
        );
        activePath.lineTo(size.width * 0.2, size.height * 0.3);
      }
      
      // Draw subtle glow shadow
      canvas.drawPath(
        activePath,
        Paint()
          ..color = const Color(0xFF4BDDB7).withOpacity(0.3)
          ..strokeWidth = 8.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      
      canvas.drawPath(activePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
