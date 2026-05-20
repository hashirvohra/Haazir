import os
import json
import re
import datetime
from google.generativeai import GenerativeModel
import google.generativeai as genai
import googlemaps

# Define standard fallback coordinates for major Islamabad sectors
SECTOR_COORDINATES = {
    "g-13": {"lat": 33.6425, "lng": 72.9904},
    "f-11": {"lat": 33.6844, "lng": 72.9889},
    "g-11": {"lat": 33.6667, "lng": 73.0167},
    "i-8": {"lat": 33.6601, "lng": 73.0801},
    "dha": {"lat": 33.5262, "lng": 73.1492},
    "bahria": {"lat": 33.5186, "lng": 73.0906},
    "f-6": {"lat": 33.7297, "lng": 73.0747},
    "g-9": {"lat": 33.6856, "lng": 73.0479},
    "rawalpindi": {"lat": 33.5984, "lng": 73.0441}
}

class IntentAgent:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        self.maps_key = os.getenv("GOOGLE_MAPS_API_KEY")
        
        if self.api_key:
            genai.configure(api_key=self.api_key)
            
        if self.maps_key:
            self.gmaps = googlemaps.Client(key=self.maps_key)
        else:
            self.gmaps = None

    def execute(self, state: dict) -> dict:
        """
        Parses raw user input to extract service_type, location, datetime, urgency, and language.
        Appends an entry to the trace logs.
        """
        raw_input = state.get("raw_input", "")
        start_time = datetime.datetime.now()
        
        intent_data = {}
        status = "success"
        tool_called = "gemini_parse_intent"
        
        try:
            if self.api_key:
                intent_data = self._parse_with_gemini(raw_input)
            else:
                # Fallback to local regex rule-based parser
                intent_data = self._parse_with_local_rules(raw_input)
                status = "fallback"
                tool_called = "regex_parser_fallback"
        except Exception as e:
            print(f"Error in IntentAgent Gemini call: {e}")
            intent_data = self._parse_with_local_rules(raw_input)
            status = "fallback"
            tool_called = "regex_parser_fallback"

        # Step 2: Resolve Location to Coordinates using Google Geocoding API if available
        location_raw = intent_data.get("location_raw", "")
        location_resolved = intent_data.get("location_resolved", "user_location")
        lat, lng = None, None
        
        if self.gmaps and location_raw:
            try:
                geocode_result = self.gmaps.geocode(f"{location_raw}, Islamabad, Pakistan")
                if geocode_result:
                    lat = geocode_result[0]["geometry"]["location"]["lat"]
                    lng = geocode_result[0]["geometry"]["location"]["lng"]
                    location_resolved = geocode_result[0]["formatted_address"]
                    tool_called += " + google_geocoding"
            except Exception as e:
                print(f"Geocoding API failed: {e}")
        
        # Fallback coordinates mapping if API failed or wasn't called
        if lat is None or lng is None:
            # Detect sector from raw location or resolved location
            found_coord = False
            norm_loc = (location_raw + " " + location_resolved).lower()
            for sector, coords in SECTOR_COORDINATES.items():
                if sector in norm_loc:
                    lat, lng = coords["lat"], coords["lng"]
                    location_resolved = f"{sector.upper()}, Islamabad, Pakistan"
                    found_coord = True
                    break
            if not found_coord:
                # Absolute fallback (Islamabad center)
                lat, lng = 33.6844, 73.0479
                location_resolved = location_resolved or "Islamabad, Pakistan"

        intent_data["lat"] = lat
        intent_data["lng"] = lng
        intent_data["location_resolved"] = location_resolved
        
        # Merge results into session state
        state["intent"] = intent_data
        
        # Calculate latency
        latency_ms = int((datetime.datetime.now() - start_time).total_seconds() * 1000)
        
        # Append to trace log
        state["trace"].append({
            "step": "IntentAgent",
            "tool_called": tool_called,
            "input_summary": raw_input,
            "output_summary": json.dumps(intent_data),
            "latency_ms": latency_ms,
            "status": status
        })
        
        return state

    def _parse_with_gemini(self, raw_input: str) -> dict:
        prompt = f"""
You are IntentAgent, part of the Haazir service orchestration system.
Your ONLY job:
Parse a service request in ANY language (Urdu script, Roman Urdu, English) and output
a structured JSON intent object. Nothing else. Do NOT output markdown ticks or code block wrapper.

Output format (strict JSON, no markdown, no explanation):
{{
  "service_type": "ac_technician | plumber | electrician | tutor | beautician | carpenter | other",
  "service_name_urdu": "UrduNameHere",
  "service_name_en": "English Name Here",
  "location_raw": "exact location string from input",
  "location_resolved": "standardized area name",
  "city": "Islamabad | Karachi | Lahore | Rawalpindi | other",
  "datetime_iso": "ISO datetime string (e.g. 2025-01-16T10:00:00+05:00)",
  "datetime_natural": "Tomorrow morning",
  "urgency": "urgent | normal | flexible",
  "detected_language": "urdu | roman_urdu | english | mixed",
  "confidence": 0.95
}}

Rules:
- "kal subah" or "tomorrow morning" = 09:00 AM local time tomorrow
- "abhi", "urgently", "fauran", "emergency" = urgency: urgent
- If location is missing, set location_resolved to "user_location"
- If service is ambiguous, pick the closest match and set confidence below 0.7
- NEVER return anything except the JSON object. Do not wrap in ```json or ```.

Examples:
Input:  "Mujhe kal subah G-13 mein AC technician chahiye"
Output: {{ "service_type": "ac_technician", "service_name_urdu": "اے سی ٹیکنیشن", "service_name_en": "AC Technician", "location_raw": "G-13", "location_resolved": "G-13, Islamabad", "city": "Islamabad", "datetime_iso": "{datetime.date.today() + datetime.timedelta(days=1)}T09:00:00+05:00", "datetime_natural": "Tomorrow morning", "urgency": "normal", "detected_language": "roman_urdu", "confidence": 0.98 }}

Input: {raw_input}
"""
        model = GenerativeModel("gemini-2.0-flash")
        response = model.generate_content(prompt)
        text = response.text.strip()
        
        # Clean any accidental markdown code blocks
        if text.startswith("```"):
            text = re.sub(r"^```(json)?\n", "", text)
            text = re.sub(r"\n```$", "", text)
            text = text.strip()
            
        return json.loads(text)

    def _parse_with_local_rules(self, raw_input: str) -> dict:
        """
        Sophisticated keyword matching fallback for Urdu / Roman Urdu / English.
        """
        text = raw_input.lower()
        
        # Determine service_type
        service_type = "other"
        service_name_en = "Other Service"
        service_name_urdu = "دیگر"
        
        if any(w in text for w in ["ac", "cool", "air conditioner", "اے سی", "تھنڈا"]):
            service_type = "ac_technician"
            service_name_en = "AC Technician"
            service_name_urdu = "اے سی ٹیکنیشن"
        elif any(w in text for w in ["plumber", "pipe", "leak", "water", "nal", "toti", "پلمبر", "پانی", "نل"]):
            service_type = "plumber"
            service_name_en = "Plumber"
            service_name_urdu = "پلمبر"
        elif any(w in text for w in ["electric", "light", "fan", "wire", "bijli", "tarp", "بجلی", "پنکھا", "تار"]):
            service_type = "electrician"
            service_name_en = "Electrician"
            service_name_urdu = "الیکٹریشن"
        elif any(w in text for w in ["tutor", "teacher", "math", "study", "parhna", "ustad", "استاد", "ٹیوٹر", "پڑھائی"]):
            service_type = "tutor"
            service_name_en = "Home Tutor"
            service_name_urdu = "ٹیوٹر"
        elif any(w in text for w in ["beauty", "parlor", "makeup", "hair", "shadi", "makeup", "پارلر", "میک اپ", "دلہن"]):
            service_type = "beautician"
            service_name_en = "Beautician"
            service_name_urdu = "بیوٹیشن"
        elif any(w in text for w in ["carpenter", "wood", "door", "sofa", "lakri", "kera", "کارپینٹر", "لکڑی", "صوفہ"]):
            service_type = "carpenter"
            service_name_en = "Carpenter"
            service_name_urdu = "کارپینٹر"

        # Determine location
        location_raw = "user_location"
        city = "Islamabad"
        for sector in SECTOR_COORDINATES.keys():
            if sector in text or sector.replace("-", "") in text:
                location_raw = sector.upper()
                break
                
        # Determine urgency
        urgency = "normal"
        if any(w in text for w in ["urgent", "emergency", "abhi", "fauran", "jaldi", "فوراً", "جلدی"]):
            urgency = "urgent"

        # Determine language
        detected_language = "english"
        # Simple character analysis
        urdu_chars = re.findall(r'[\u0600-\u06FF]', raw_input)
        if len(urdu_chars) > len(raw_input) * 0.2:
            detected_language = "urdu"
        elif any(w in text for w in ["chahiye", "hai", "mujhe", "kal", "subah", "mein", "fauran"]):
            detected_language = "roman_urdu"

        # DateTime parsing
        tomorrow = datetime.date.today() + datetime.timedelta(days=1)
        datetime_iso = f"{tomorrow}T10:00:00+05:00"
        datetime_natural = "Tomorrow morning"
        if "abhi" in text or "urgent" in text:
            now = datetime.datetime.now()
            datetime_iso = now.isoformat()
            datetime_natural = "Right now"
        
        return {
            "service_type": service_type,
            "service_name_urdu": service_name_urdu,
            "service_name_en": service_name_en,
            "location_raw": location_raw,
            "location_resolved": f"{location_raw}, Islamabad, Pakistan",
            "city": city,
            "datetime_iso": datetime_iso,
            "datetime_natural": datetime_natural,
            "urgency": urgency,
            "detected_language": detected_language,
            "confidence": 0.85
        }
