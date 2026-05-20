import 'dart:convert';
import 'package:http/http.dart' as http;

class AgentService {
  // Use 10.0.2.2 for Android Emulator, localhost for Windows Desktop
  // For the hackathon, we will make it configurable, defaulting to localhost:8000
  static String baseUrl = 'http://localhost:8000';

  static Map<String, dynamic>? currentSessionState;

  /// Runs the multilingual NLU parsing and service provider discovery multi-agent pipeline
  static Future<Map<String, dynamic>> discoverProviders(String query) async {
    final url = Uri.parse('$baseUrl/api/agent/discover');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query}),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        currentSessionState = decoded;
        return decoded;
      } else {
        throw Exception('Server returned code: ${response.statusCode}');
      }
    } catch (e) {
      // Mock Fallback for local UI development if server is not running
      await Future.delayed(const Duration(seconds: 2));
      return _generateMockDiscoveryResponse(query);
    }
  }

  /// Commits the booking, triggers Sheets write and follow-up schedules
  static Future<Map<String, dynamic>> bookProvider(String providerId, String slot, {String? username}) async {
    final url = Uri.parse('$baseUrl/api/agent/book');
    
    if (currentSessionState == null) {
      _generateMockDiscoveryResponse("AC technician");
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'state': currentSessionState,
          'provider_id': providerId,
          'selected_slot': slot,
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        currentSessionState = decoded;
        return decoded;
      } else {
        throw Exception('Server returned code: ${response.statusCode}');
      }
    } catch (e) {
      // Mock Fallback for offline testing
      await Future.delayed(const Duration(seconds: 1));
      final mockResponse = _generateMockBookingResponse(providerId, slot);
      if (username != null && mockResponse["booking"] != null) {
        mockResponse["booking"]["username"] = username;
      }
      return mockResponse;
    }
  }

  /// Fetches real-time status of an active booking (pools API as a fail-safe fallback for Firestore)
  static Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    final url = Uri.parse('$baseUrl/api/bookings/$bookingId');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to get booking details');
      }
    } catch (e) {
      return _generateMockStatusDetails(bookingId);
    }
  }

  /// Rates a completed booking
  static Future<bool> rateBooking(String bookingId, int rating) async {
    final url = Uri.parse('$baseUrl/api/bookings/$bookingId/rate?rating=$rating');
    try {
      final response = await http.post(url);
      return response.statusCode == 200;
    } catch (e) {
      return true;
    }
  }

  /// Gets recent searches for a user
  static Future<List<String>> getUserRecentSearches(String username) async {
    final url = Uri.parse('$baseUrl/api/users/$username/searches');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> searches = decoded['searches'] ?? [];
        return searches.map((s) => s.toString()).toList();
      }
    } catch (e) {
      // offline fallback handled by caller or returned empty
    }
    return [];
  }

  /// Adds a recent search for a user
  static Future<bool> addUserRecentSearch(String username, String query) async {
    final url = Uri.parse('$baseUrl/api/users/$username/searches');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query}),
      );
      return response.statusCode == 200;
    } catch (e) {
      // offline fallback
    }
    return true;
  }

  /// Gets bookings for a user
  static Future<List<Map<String, dynamic>>> getUserRecentBookings(String username) async {
    final url = Uri.parse('$baseUrl/api/users/$username/bookings');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> bookings = decoded['bookings'] ?? [];
        return bookings.map((b) => Map<String, dynamic>.from(b)).toList();
      }
    } catch (e) {
      // offline fallback
    }
    return [];
  }

  // --- Offline UI Demo Fallback Generation ---

  static Map<String, dynamic> _generateMockDiscoveryResponse(String query) {
    bool isUrdu = query.contains('اے سی') || query.contains('پلمبر') || query.contains('چاہیے');
    String serviceType = "ac_technician";
    String serviceNameUrdu = "اے سی ٹیکنیشن";
    String serviceNameEn = "AC Technician";

    if (query.toLowerCase().contains('plumber') || query.contains('پلمبر')) {
      serviceType = "plumber";
      serviceNameEn = "Plumber";
      serviceNameUrdu = "پلمبر";
    }

    final mockState = {
      "session_id": "mock-uuid-1234",
      "raw_input": query,
      "intent": {
        "service_type": serviceType,
        "service_name_urdu": serviceNameUrdu,
        "service_name_en": serviceNameEn,
        "location_raw": "G-13",
        "location_resolved": "G-13, Islamabad, Pakistan",
        "city": "Islamabad",
        "datetime_iso": DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        "datetime_natural": "Tomorrow morning",
        "urgency": "normal",
        "detected_language": isUrdu ? "urdu" : "english",
        "lat": 33.6425,
        "lng": 72.9904,
        "confidence": 0.95
      },
      "providers": [
        {
          "id": "prov_1",
          "name": "Ali AC Services & Repair",
          "service_type": serviceType,
          "rating": 4.8,
          "reviews_count": 92,
          "price_range": "PKR 1200-2500",
          "location_name": "G-13, Islamabad",
          "lat": 33.6425,
          "lng": 72.9904,
          "available_slots": ["09:00 AM", "12:00 PM", "03:00 PM"],
          "phone": "+92 300 1234567",
          "distance_km": 0.5,
          "duration": "2 min",
          "score": 0.98,
          "reasoning": isUrdu 
              ? "یہ آپ سے صرف 0.5 کلومیٹر دور ہیں، اور ان کی ریٹنگ 4.8/5 ہے۔"
              : "Located just 0.5 km away with a premium 4.8/5 rating."
        },
        {
          "id": "prov_2",
          "name": "Kamran AC Cool Tech",
          "service_type": serviceType,
          "rating": 4.5,
          "reviews_count": 64,
          "price_range": "PKR 1000-2000",
          "location_name": "F-11, Islamabad",
          "lat": 33.6844,
          "lng": 72.9889,
          "available_slots": ["10:00 AM", "01:00 PM", "04:00 PM"],
          "phone": "+92 312 9876543",
          "distance_km": 4.8,
          "duration": "10 min",
          "score": 0.85,
          "reasoning": "Located 4.8 km away in F-11 with high availability."
        }
      ],
      "top_recommendation_reasoning": isUrdu
          ? "Ali AC Services & Repair آپ کے لیے بہترین آپشن ہیں کیونکہ یہ انتہائی قریب (0.5 کلومیٹر) ہیں اور ان کی ریٹنگ شاندار (4.8) ہے۔"
          : "Ali AC Services & Repair is your top recommendation because they are closest (0.5 km) with an excellent rating of 4.8 stars.",
      "trace": [
        {
          "step": "IntentAgent",
          "tool_called": "regex_parser_fallback",
          "input_summary": query,
          "output_summary": "Extracted $serviceType at G-13",
          "latency_ms": 150,
          "status": "fallback"
        },
        {
          "step": "DiscoveryAgent",
          "tool_called": "local_json_fallback",
          "input_summary": "Find $serviceType providers",
          "output_summary": "Ranked 2 providers near G-13",
          "latency_ms": 80,
          "status": "success"
        }
      ]
    };
    currentSessionState = mockState;
    return mockState;
  }

  static Map<String, dynamic> _generateMockBookingResponse(String providerId, String slot) {
    final today = DateTime.now();
    final bookingId = "HZR-${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}-MOCK";
    
    final intent = currentSessionState?["intent"] ?? {};
    final providers = currentSessionState?["providers"] as List? ?? [];
    
    Map<String, dynamic> chosenProvider = {
      "name": "Ali AC Services & Repair",
      "price_range": "PKR 1200-2500"
    };
    for (var p in providers) {
      if (p["id"] == providerId) {
        chosenProvider = Map<String, dynamic>.from(p);
        break;
      }
    }

    final mockBooking = {
      "booking_id": bookingId,
      "created_at": DateTime.now().toIso8601String(),
      "service_type": intent["service_type"] ?? "ac_technician",
      "provider_id": providerId,
      "provider_name": chosenProvider["name"],
      "location": intent["location_resolved"] ?? "G-13, Islamabad",
      "slot": slot,
      "slot_display": "Tomorrow, $slot",
      "price_estimate": chosenProvider["price_range"],
      "status": "confirmed",
      "sheets_row": 15
    };

    currentSessionState?["booking"] = mockBooking;
    currentSessionState?["followup"] = {
      "reminder_scheduled": true,
      "reminder_notification_payload": {
        "title": "Booking Confirmed",
        "body": "Your booking $bookingId is confirmed"
      }
    };
    
    currentSessionState?["trace"].add({
      "step": "BookingAgent",
      "tool_called": "write_firestore_booking + append_sheets_row",
      "input_summary": "provider: $providerId",
      "output_summary": "Created booking $bookingId with Sheets Row 15",
      "latency_ms": 250,
      "status": "success"
    });
    
    currentSessionState?["trace"].add({
      "step": "FollowUpAgent",
      "tool_called": "schedule_fcm_notification",
      "input_summary": "booking: $bookingId",
      "output_summary": "Scheduled reminder and status changes",
      "latency_ms": 50,
      "status": "success"
    });

    return currentSessionState!;
  }

  static Map<String, dynamic> _generateMockStatusDetails(String bookingId) {
    return {
      "booking_id": bookingId,
      "created_at": DateTime.now().toIso8601String(),
      "service_type": "ac_technician",
      "provider_id": "prov_1",
      "provider_name": "Ali AC Services & Repair",
      "location": "G-13, Islamabad",
      "slot_display": "Tomorrow, 12:00 PM",
      "price_estimate": "PKR 1200-2500",
      "status": "en_route"
    };
  }
}
