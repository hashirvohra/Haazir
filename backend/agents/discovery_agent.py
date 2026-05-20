import os
import json
import math
import datetime
import googlemaps
from google.cloud import firestore

class DiscoveryAgent:
    def __init__(self):
        self.maps_key = os.getenv("GOOGLE_MAPS_API_KEY")
        self.db = None
        
        # Initialize Firestore if credentials are provided
        if os.getenv("GOOGLE_APPLICATION_CREDENTIALS") and os.path.exists(os.getenv("GOOGLE_APPLICATION_CREDENTIALS")):
            try:
                self.db = firestore.Client()
            except Exception as e:
                print(f"Firestore failed to initialize, using JSON fallback: {e}")
                self.db = None

        if self.maps_key:
            self.gmaps = googlemaps.Client(key=self.maps_key)
        else:
            self.gmaps = None

    def execute(self, state: dict) -> dict:
        """
        Finds nearby service providers and ranks them using multi-factor scoring:
        Score = Distance(40%) + Rating(35%) + Availability(25%)
        """
        start_time = datetime.datetime.now()
        intent = state.get("intent", {})
        service_type = intent.get("service_type", "")
        detected_language = intent.get("detected_language", "english")
        
        user_lat = intent.get("lat")
        user_lng = intent.get("lng")
        
        providers = []
        data_source = "mock_firestore"
        fallback_used = False
        tool_called = "query_firestore_providers"

        # Step 1: Discover Providers (Firestore with local JSON fallback)
        if self.db:
            try:
                prov_ref = self.db.collection("providers")
                query = prov_ref.where("service_type", "==", service_type).stream()
                providers = [doc.to_dict() for doc in query]
            except Exception as e:
                print(f"Firestore query failed: {e}. Falling back to local JSON.")
                providers = self._get_local_mock_providers(service_type)
                fallback_used = True
                data_source = "local_json_fallback"
                tool_called = "local_json_fallback"
        else:
            providers = self._get_local_mock_providers(service_type)
            data_source = "local_json_fallback"
            tool_called = "local_json_fallback"

        # If no providers found at all, use ALL mock providers in file matching type
        if not providers:
            providers = self._get_local_mock_providers(service_type)

        # Step 2: Distance Calculation (Google Distance Matrix with Haversine fallback)
        distances_km = {}
        driving_durations = {}
        
        provider_ids = [p["id"] for p in providers]
        
        if self.gmaps and user_lat and user_lng and provider_ids:
            try:
                origins = (user_lat, user_lng)
                destinations = [(p["lat"], p["lng"]) for p in providers]
                
                matrix = self.gmaps.distance_matrix(
                    origins=origins,
                    destinations=destinations,
                    mode="driving"
                )
                
                if matrix["status"] == "OK":
                    elements = matrix["rows"][0]["elements"]
                    for idx, element in enumerate(elements):
                        if element["status"] == "OK":
                            dist_meters = element["distance"]["value"]
                            dur_secs = element["duration"]["value"]
                            p_id = providers[idx]["id"]
                            distances_km[p_id] = dist_meters / 1000.0
                            driving_durations[p_id] = f"{int(dur_secs / 60)} min"
                    tool_called += " + distance_matrix"
            except Exception as e:
                print(f"Distance Matrix API failed: {e}")
                
        # Haversine calculation for any missing distances
        for p in providers:
            p_id = p["id"]
            if p_id not in distances_km:
                dist_h = self._haversine(user_lat, user_lng, p["lat"], p["lng"])
                distances_km[p_id] = dist_h
                # Assume average speed of 30 km/h for ETA
                driving_durations[p_id] = f"{int(dist_h / 30 * 60) + 5} min"

        # Step 3: Multi-factor Scoring
        ranked_list = []
        for p in providers:
            p_id = p["id"]
            dist_km = distances_km[p_id]
            
            # 1. Distance Score (decay function, 0 to 1)
            # 0 km = 1.0, 5 km = 0.5, 15 km = 0.1
            dist_score = math.exp(-dist_km / 5.0)
            
            # 2. Rating Score (0 to 1)
            rating_score = p["rating"] / 5.0
            
            # 3. Availability Score (1.0 if slots exist)
            avail_score = 1.0 if len(p.get("available_slots", [])) > 0 else 0.3
            
            # Final Score calculation (40% distance, 35% rating, 25% availability)
            final_score = (dist_score * 0.40) + (rating_score * 0.35) + (avail_score * 0.25)
            
            p["distance_km"] = round(dist_km, 1)
            p["duration"] = driving_durations[p_id]
            p["score"] = round(final_score, 2)
            
            # Compose reasoning based on language
            p["reasoning"] = self._generate_provider_reasoning(p, detected_language)
            ranked_list.append(p)

        # Sort ranked list descending by score
        ranked_list.sort(key=lambda x: x["score"], reverse=True)
        top_3 = ranked_list[:3]

        # Populate top recommendation reasoning
        top_rec_reasoning = ""
        if top_3:
            top_rec_reasoning = self._generate_top_recommendation_reasoning(top_3[0], detected_language)

        # Save to state
        state["providers"] = top_3
        state["top_recommendation_reasoning"] = top_rec_reasoning
        
        # Calculate latency
        latency_ms = int((datetime.datetime.now() - start_time).total_seconds() * 1000)
        
        # Append to trace log
        state["trace"].append({
            "step": "DiscoveryAgent",
            "tool_called": tool_called,
            "input_summary": f"service: {service_type}, lat/lng: {user_lat}/{user_lng}",
            "output_summary": f"Ranked {len(top_3)} providers. Top is {top_3[0]['name'] if top_3 else 'None'}",
            "latency_ms": latency_ms,
            "status": "fallback" if fallback_used else "success"
        })
        
        return state

    def _get_local_mock_providers(self, service_type: str) -> list:
        filepath = os.path.join(os.path.dirname(__file__), "..", "data", "mock_providers.json")
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                all_providers = json.load(f)
                return [p for p in all_providers if p["service_type"] == service_type]
        except Exception as e:
            print(f"Failed to read local mock providers file: {e}")
            return []

    def _haversine(self, lat1: float, lng1: float, lat2: float, lng2: float) -> float:
        """
        Calculates straight-line distance in km between two lat/lng coordinates.
        """
        R = 6371.0 # Earth radius in km
        d_lat = math.radians(lat2 - lat1)
        d_lng = math.radians(lng2 - lng1)
        a = math.sin(d_lat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lng / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

    def _generate_provider_reasoning(self, p: dict, lang: str) -> str:
        if lang == "urdu":
            return f"یہ آپ سے صرف {p['distance_km']} کلومیٹر دور ہیں، اور ان کی ریٹنگ {p['rating']}/5 ہے۔"
        elif lang == "roman_urdu":
            return f"Yeh aap se sirf {p['distance_km']} km door hain aur inki rating {p['rating']}/5 hai."
        else:
            return f"Located just {p['distance_km']} km away with a premium {p['rating']}/5 rating."

    def _generate_top_recommendation_reasoning(self, p: dict, lang: str) -> str:
        if lang == "urdu":
            return f"{p['name']} آپ کے لیے بہترین آپشن ہیں کیونکہ یہ انتہائی قریب ({p['distance_km']} کلومیٹر) ہیں اور ان کی ریٹنگ شاندار ({p['rating']}) ہے۔"
        elif lang == "roman_urdu":
            return f"{p['name']} aap ke liye best option hain kyun ke yeh boht kareeb ({p['distance_km']} km) hain aur inki rating behtareen ({p['rating']}) hai."
        else:
            return f"{p['name']} is your top recommendation because they are closest ({p['distance_km']} km) with an excellent rating of {p['rating']} stars."
