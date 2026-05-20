import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLanguage = "EN"; // "اردو" | "Roman" | "EN"
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      agentProvider.loadRecentSearches();
      agentProvider.loadRecentBookings();
    });
  }

  final List<Map<String, dynamic>> _categories = [
    {
      "id": "ac_technician",
      "en": "AC Tech",
      "ur": "اے سی ٹیکنیشن",
      "icon": Icons.ac_unit,
      "color": const Color(0xFF4BDDB7), // Ice Teal
    },
    {
      "id": "plumber",
      "en": "Plumber",
      "ur": "پلمبر",
      "icon": Icons.plumbing,
      "color": const Color(0xFFFFBE70), // Warm Gold
    },
    {
      "id": "electrician",
      "en": "Electrician",
      "ur": "الیکٹریشن",
      "icon": Icons.bolt,
      "color": const Color(0xFF02B894), // Green Teal
    },
  ];

  IconData _getIconForService(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'ac_technician':
        return Icons.ac_unit;
      case 'plumber':
        return Icons.plumbing;
      case 'electrician':
        return Icons.bolt;
      default:
        return Icons.bookmark_added_outlined;
    }
  }

  String _getServiceDisplayName(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'ac_technician':
        return 'AC Repair & Services';
      case 'plumber':
        return 'Plumbing Services';
      case 'electrician':
        return 'Electrical Services';
      default:
        return serviceType;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4BDDB7); // Teal
      case 'cancelled':
        return Colors.redAccent;
      default:
        return const Color(0xFFF39C12); // Amber
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Active Booking';
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Bar: Premium Dual-Language Toggle & Brand Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: Color(0xFFF39C12),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Haazir",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Dual Language Pill Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B2B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: ["اردو", "EN"].map((lang) {
                            final isSelected = _selectedLanguage == lang;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedLanguage = lang;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFF39C12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  lang,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF472A00) : Colors.white70,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Help Icon Button
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Colors.white60, size: 22),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Haazir matches you with the best nearby service providers instantly.")),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      // Logout Button
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 22),
                        tooltip: 'Sign Out / لاگ آؤٹ',
                        onPressed: () async {
                          await agentProvider.logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Logged out successfully / لاگ آؤٹ ہو گیا"),
                                backgroundColor: Color(0xFF161B2B),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 2. Multilingual Greeting Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "آپ کو کیا چاہیے؟",
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF39C12),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "What do you need?",
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Search Bar with Glowing Mic Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B2B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10, width: 1.0),
                ),
                padding: const EdgeInsets.only(left: 18, right: 8, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: _selectedLanguage == "اردو"
                              ? "مثال: مجھے G-13 میں اے سی ٹیکنیشن چاہیے"
                              : "e.g. Electrician needed in I-8 urgently",
                          hintStyle: const TextStyle(color: Colors.white30),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            agentProvider.runDiscovery(val);
                            Navigator.pushNamed(context, '/trace');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Glowing Amber Mic Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.text = _selectedLanguage == "اردو"
                              ? "مجھے کل صبح G-13 میں اے سی ٹیکنیشن چاہیے"
                              : "AC technician needed in G-13 tomorrow morning";
                          _selectedCategory = "ac_technician";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF39C12).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Color(0xFF472A00),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Recent Searches
              if (agentProvider.recentSearches.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  "Recent Searches / حالیہ تلاش",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: agentProvider.recentSearches.length,
                    itemBuilder: (context, index) {
                      final query = agentProvider.recentSearches[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            query,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          backgroundColor: const Color(0xFF161B2B),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.text = query;
                            });
                            agentProvider.runDiscovery(query);
                            Navigator.pushNamed(context, '/trace');
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 36),

              // 4. Large Service Grid (3 Columns)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Category",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "3 Services Available",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 3 Large Square Service Cards
              Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat["id"];
                  final catColor = cat["color"] as Color;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat["id"];
                          _searchController.text = _selectedLanguage == "اردو"
                              ? "مجھے G-13 میں ${cat['ur']} کی ضرورت ہے"
                              : "Need ${cat['en']} in G-13, Islamabad";
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B2B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFF39C12) : Colors.white10,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFF39C12).withOpacity(0.1),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Beautiful Colored Icon Container
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                cat["icon"] as IconData,
                                color: catColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Urdu text
                            Text(
                              cat["ur"]!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoNastaliqUrdu(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? const Color(0xFFF39C12) : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // English text
                            Text(
                              cat["en"]!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFFF39C12) : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // 5. Recent Booking Logs (Staged badges)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Requests",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Icon(Icons.history, color: Colors.white30, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              
              ...agentProvider.recentBookings.map((b) {
                final serviceType = b["service_type"] ?? "Service";
                final providerName = b["provider_name"] ?? "Provider";
                final status = b["status"] ?? "confirmed";
                final dateStr = "Just now";
                final isCompletedOrCancelled = status == "completed" || status == "cancelled";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      if (!isCompletedOrCancelled) {
                        agentProvider.setActiveBooking(b);
                        Navigator.pushNamed(context, '/tracker');
                      }
                    },
                    child: _buildRecentBookingCard(
                      service: _getServiceDisplayName(serviceType),
                      provider: providerName,
                      status: _getStatusText(status),
                      date: dateStr,
                      statusColor: _getStatusColor(status),
                      icon: _getIconForService(serviceType),
                    ),
                  ),
                );
              }).toList(),
              
              _buildRecentBookingCard(
                service: "AC Repair & Cleaning",
                provider: "Kamran AC Cool Tech",
                status: "Completed",
                date: "Yesterday",
                statusColor: const Color(0xFF4BDDB7), // Teal
                icon: Icons.ac_unit,
              ),
              const SizedBox(height: 12),
              _buildRecentBookingCard(
                service: "Emergency Plumbing Fix",
                provider: "Noman Emergency Plumber",
                status: "Completed",
                date: "14 May 2026",
                statusColor: const Color(0xFF4BDDB7), // Teal
                icon: Icons.plumbing,
              ),
              
              const SizedBox(height: 32),
              
              // 6. Action Button: Find Best Match (Haazir AI)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C12),
                    foregroundColor: const Color(0xFF472A00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final val = _searchController.text;
                    if (val.trim().isNotEmpty) {
                      agentProvider.runDiscovery(val);
                      Navigator.pushNamed(context, '/trace');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please type or select a service request first!")),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Find Best Match",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookingCard({
    required String service,
    required String provider,
    required String status,
    required String date,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider,
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                date,
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
              ),
            ],
          )
        ],
      ),
    );
  }
}
