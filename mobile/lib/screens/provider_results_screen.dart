import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class ProviderResultsScreen extends StatefulWidget {
  const ProviderResultsScreen({super.key});

  @override
  State<ProviderResultsScreen> createState() => _ProviderResultsScreenState();
}

class _ProviderResultsScreenState extends State<ProviderResultsScreen> {
  String? _selectedSlot;
  String _activeFilter = "Recommended";

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final sessionState = agentProvider.sessionState;
    final isLoading = agentProvider.isLoading;

    final providers = sessionState["providers"] as List<dynamic>? ?? [];
    final topReasoning = sessionState["top_recommendation_reasoning"] as String? ?? "";
    final rawInput = agentProvider.rawInput;
    final intent = sessionState["intent"] as Map<String, dynamic>? ?? {};
    final serviceName = intent["service_name_en"] ?? "Service";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$serviceName Providers",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF39C12))),
                    SizedBox(height: 20),
                    Text("Securing your booking with Google Sheets...", style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Search Summary Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B2B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology, color: Color(0xFFF39C12), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "MATCHED FOR REQUEST",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rawInput.isNotEmpty ? rawInput : "Service requested",
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Horizontal Filter Chips (Distance, Rating, Budget)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip("Recommended", Icons.star_border),
                          const SizedBox(width: 10),
                          _buildFilterChip("Distance (< 2km)", Icons.directions_car_outlined),
                          const SizedBox(width: 10),
                          _buildFilterChip("Rating (4.5+)", Icons.grade_outlined),
                          const SizedBox(width: 10),
                          _buildFilterChip("Budget Friendly", Icons.payments_outlined),
                        ],
                      ),
                    ),
                  ),

                  // 3. E2E AI Reasoning Badge Header
                  if (topReasoning.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF39C12).withOpacity(0.12),
                              const Color(0xFF4BDDB7).withOpacity(0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF39C12).withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFFF39C12), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "Haazir AI Recommendation",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFF39C12),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              topReasoning,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 4. Providers List
                  Expanded(
                    child: providers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("🕵️‍♂️", style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                const Text(
                                  "No matching providers found nearby.",
                                  style: TextStyle(color: Colors.white54, fontSize: 15),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Go Back"),
                                )
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            itemCount: providers.length,
                            itemBuilder: (context, idx) {
                              final provider = providers[idx];
                              final isTop = idx == 0;
                              return _buildProviderCard(context, provider, isTop, agentProvider);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF39C12) : const Color(0xFF161B2B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF39C12) : Colors.white10,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF472A00) : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF472A00) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    Map<String, dynamic> provider,
    bool isTop,
    AgentProvider agentProvider,
  ) {
    final name = provider["name"] ?? "Service Provider";
    final rating = provider["rating"] ?? 4.5;
    final reviewsCount = provider["reviews_count"] ?? 0;
    final priceRange = provider["price_range"] ?? "PKR 1000-2000";
    final distance = provider["distance_km"] ?? 1.5;
    final duration = provider["duration"] ?? "5 min";
    final reasoning = provider["reasoning"] ?? "";
    final score = provider["score"] ?? 0.85;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B2B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop ? const Color(0xFFF39C12) : Colors.white10,
          width: isTop ? 1.8 : 1.0,
        ),
        boxShadow: isTop
            ? [
                BoxShadow(
                  color: const Color(0xFFF39C12).withOpacity(0.06),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Match Score Badge & Stars Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTop)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "BEST MATCH • ${(score * 100).toInt()}% SCORE",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: const Color(0xFF472A00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF39C12), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    " ($reviewsCount)",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 14),

          // Details Row: Stylized Metric Chips
          Row(
            children: [
              _buildMetricChip(Icons.location_on, "$distance km ($duration)", const Color(0xFF4BDDB7)), // Teal
              const SizedBox(width: 8),
              _buildMetricChip(Icons.payments_outlined, priceRange, const Color(0xFFF39C12)), // Amber
            ],
          ),
          const SizedBox(height: 14),

          // Provider Specific AI Reasoning Box
          if (reasoning.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF4BDDB7), size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reasoning,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Primary Glowing Solid Amber vs Outlined Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isTop ? const Color(0xFFF39C12) : Colors.transparent,
                foregroundColor: isTop ? const Color(0xFF472A00) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isTop ? BorderSide.none : const BorderSide(color: Colors.white24, width: 1.0),
                ),
                elevation: 0,
              ),
              onPressed: () {
                _showSlotSelectorBottomSheet(context, provider, agentProvider);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isTop ? "Book Now" : "View Details & Book",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: isTop ? const Color(0xFF472A00) : Colors.white70,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showSlotSelectorBottomSheet(
    BuildContext context,
    Map<String, dynamic> provider,
    AgentProvider agentProvider,
  ) {
    final name = provider["name"] ?? "Provider";
    final slots = provider["available_slots"] as List<dynamic>? ?? ["09:00 AM", "12:00 PM", "03:00 PM"];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Choose Availability Slot",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Select an option to schedule with $name",
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Slots Grid Wrap
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: slots.map((s) {
                      final slotStr = s.toString();
                      final isSelected = _selectedSlot == slotStr;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedSlot = slotStr;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF39C12) : const Color(0xFF0E1322),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFF39C12) : Colors.white10,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            slotStr,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF472A00) : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Confirm Book Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02B894), // Green Teal
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _selectedSlot == null
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              Navigator.pop(modalContext); // Close bottom sheet
                              final success = await agentProvider.runBooking(provider["id"], _selectedSlot!);
                              if (success) {
                                navigator.pushNamed('/confirmation');
                              }
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Confirm & Commit Booking",
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_outline, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
