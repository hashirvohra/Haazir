import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'services/agent_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/agent_trace_screen.dart';
import 'screens/provider_results_screen.dart';
import 'screens/booking_confirmation_screen.dart';
import 'screens/active_booking_tracker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AgentProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haazir - AI Service Orchestrator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1322),
        primaryColor: const Color(0xFFF39C12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFBE70),
          primaryContainer: Color(0xFFF39C12),
          secondary: Color(0xFF4BDDB7),
          secondaryContainer: Color(0xFF02B894),
          surface: Color(0xFF161B2B),
          background: Color(0xFF0E1322),
          onPrimary: Color(0xFF472A00),
          onSecondary: Color(0xFF00382B),
          onSurface: Color(0xFFDEE1F7),
          onSurfaceVariant: Color(0xFFD8C3AD),
          outline: Color(0xFFA18D7A),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme.copyWith(
            headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFFDEE1F7)),
            headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFDEE1F7)),
            titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFFDEE1F7)),
            bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFFDEE1F7)),
            bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFFDEE1F7)),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161B2B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF39C12),
            foregroundColor: const Color(0xFF472A00),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF161B2B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white10, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF39C12), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Colors.white30),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/trace': (context) => const AgentTraceScreen(),
        '/results': (context) => const ProviderResultsScreen(),
        '/confirmation': (context) => const BookingConfirmationScreen(),
        '/tracker': (context) => const ActiveBookingTrackerScreen(),
      },
    );
  }
}

class AgentProvider extends ChangeNotifier {
  String _rawInput = "";
  bool _isLoading = false;
  Map<String, dynamic> _sessionState = {};
  Map<String, dynamic> _booking = {};
  List<dynamic> _trace = [];
  String _activeBookingId = "";
  final List<Map<String, dynamic>> _recentBookings = [];
  
  String? _currentUser;
  List<String> _recentSearches = [];

  // Getters
  String get rawInput => _rawInput;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get sessionState => _sessionState;
  Map<String, dynamic> get booking => _booking;
  List<dynamic> get trace => _trace;
  String get activeBookingId => _activeBookingId;
  List<Map<String, dynamic>> get recentBookings => _recentBookings;
  
  String? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  List<String> get recentSearches => _recentSearches;

  void setRawInput(String input) {
    _rawInput = input;
    notifyListeners();
  }

  /// Initiates agentic pipeline discovery
  Future<void> runDiscovery(String query) async {
    _rawInput = query;
    _isLoading = true;
    _sessionState = {};
    _trace = [];
    notifyListeners();

    try {
      // Step 1: Trigger API
      final result = await AgentService.discoverProviders(query);
      _sessionState = result;
      _trace = result["trace"] ?? [];
      
      // If user is logged in, save search to backend
      if (isAuthenticated) {
        await AgentService.addUserRecentSearch(_currentUser!, query);
        await loadRecentSearches();
      }
    } catch (e) {
      debugPrint("Discovery Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Runs the booking and follow-up pipeline
  Future<bool> runBooking(String providerId, String slot) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await AgentService.bookProvider(providerId, slot, username: _currentUser);
      _sessionState = result;
      _booking = result["booking"] ?? {};
      _activeBookingId = _booking["booking_id"] ?? "";
      _trace = result["trace"] ?? [];
      
      // Save to recent bookings list
      if (_booking.isNotEmpty) {
        _recentBookings.removeWhere((b) => b["booking_id"] == _activeBookingId);
        _recentBookings.insert(0, Map<String, dynamic>.from(_booking));
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Booking Error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sets the active booking state from a recent booking card selection
  void setActiveBooking(Map<String, dynamic> b) {
    _booking = Map<String, dynamic>.from(b);
    _activeBookingId = _booking["booking_id"] ?? "";
    notifyListeners();
  }

  /// Dynamically updates the status of both active and persistent bookings
  void updateBookingStatus(String bookingId, String status) {
    if (_booking["booking_id"] == bookingId) {
      _booking["status"] = status;
    }
    for (var b in _recentBookings) {
      if (b["booking_id"] == bookingId) {
        b["status"] = status;
        break;
      }
    }
    notifyListeners();
  }

  /// Reset the provider state for a fresh search request
  void resetSearch() {
    _rawInput = "";
    _sessionState = {};
    _booking = {};
    _trace = [];
    _activeBookingId = "";
    notifyListeners();
  }

  /// Authenticate and fetch user session state
  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await AuthService.login(username, password);
      if (result['success']) {
        _currentUser = result['username'];
        await loadRecentSearches();
        await loadRecentBookings();
      }
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register and return status
  Future<Map<String, dynamic>> signUp(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await AuthService.signUp(username, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out current user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await AuthService.logout();
      _currentUser = null;
      _recentSearches = [];
      _recentBookings.clear();
      resetSearch();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user-specific search history
  Future<void> loadRecentSearches() async {
    if (_currentUser != null) {
      _recentSearches = await AgentService.getUserRecentSearches(_currentUser!);
      notifyListeners();
    }
  }

  /// Fetch user-specific booking history
  Future<void> loadRecentBookings() async {
    if (_currentUser != null) {
      final bookings = await AgentService.getUserRecentBookings(_currentUser!);
      _recentBookings.clear();
      _recentBookings.addAll(bookings);
      notifyListeners();
    }
  }
}
