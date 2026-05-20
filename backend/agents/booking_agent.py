import os
import json
import random
import datetime
import string
from google.cloud import firestore
from googleapiclient.discovery import build
from google.oauth2 import service_account

class BookingAgent:
    def __init__(self):
        self.db = None
        self.creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        self.sheet_id = os.getenv("GOOGLE_SHEET_ID")
        
        # Initialize Firestore
        if self.creds_path and os.path.exists(self.creds_path):
            try:
                self.db = firestore.Client()
            except Exception as e:
                print(f"BookingAgent: Firestore client init failed: {e}")

    def execute(self, state: dict, provider_id: str, selected_slot: str) -> dict:
        """
        Creates a booking, writes to Firestore, appends to Google Sheets, and updates provider status.
        """
        start_time = datetime.datetime.now()
        intent = state.get("intent", {})
        providers = state.get("providers", [])
        
        # Find chosen provider details
        provider = None
        for p in providers:
            if p["id"] == provider_id:
                provider = p
                break
                
        # If not found in previous ranked list, check mock data
        if not provider:
            provider = self._get_fallback_provider(provider_id)
            
        provider_name = provider.get("name", "Unknown Provider") if provider else "Unknown Provider"
        price_estimate = provider.get("price_range", "PKR 1000-2000") if provider else "PKR 1000-2000"
        service_type = intent.get("service_type", "ac_technician")
        location_resolved = intent.get("location_resolved", "Islamabad, Pakistan")

        # 1. Generate Booking ID (HZR-YYYYMMDD-XXXX)
        today_str = datetime.datetime.now().strftime("%Y%m%d")
        random_suffix = "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
        booking_id = f"HZR-{today_str}-{random_suffix}"

        # 2. Build Booking Object
        booking_object = {
            "booking_id": booking_id,
            "created_at": datetime.datetime.now().isoformat(),
            "service_type": service_type,
            "provider_id": provider_id,
            "provider_name": provider_name,
            "location": location_resolved,
            "slot": selected_slot,
            "slot_display": f"{selected_slot}",
            "price_estimate": price_estimate,
            "status": "confirmed",
            "sheets_row": 0
        }

        firestore_success = False
        sheets_success = False
        tool_called = "generate_booking_id"

        # 3. Write to Firestore bookings/ collection
        if self.db:
            try:
                self.db.collection("bookings").document(booking_id).set(booking_object)
                firestore_success = True
                tool_called += " + write_firestore_booking"
            except Exception as e:
                print(f"BookingAgent: Failed to write to Firestore: {e}")

        # 4. Append to Google Sheets via Sheets API
        if self.creds_path and os.path.exists(self.creds_path) and self.sheet_id:
            try:
                sheets_row = self._append_to_google_sheet(booking_object)
                if sheets_row:
                    booking_object["sheets_row"] = sheets_row
                    # Update Firestore with sheets row index if Firestore was successful
                    if firestore_success and self.db:
                        self.db.collection("bookings").document(booking_id).update({"sheets_row": sheets_row})
                    sheets_success = True
                    tool_called += " + append_sheets_row"
            except Exception as e:
                print(f"BookingAgent: Failed to write to Google Sheets: {e}")

        state["booking"] = booking_object
        
        # Calculate latency
        latency_ms = int((datetime.datetime.now() - start_time).total_seconds() * 1000)
        
        # Determine status
        status = "success"
        if not firestore_success or not sheets_success:
            status = "fallback" # proceed with local in-memory booking representation

        # Append to trace log
        state["trace"].append({
            "step": "BookingAgent",
            "tool_called": tool_called,
            "input_summary": f"provider: {provider_id}, slot: {selected_slot}",
            "output_summary": f"Created booking {booking_id}. Firestore: {firestore_success}, Sheets: {sheets_success}",
            "latency_ms": latency_ms,
            "status": status
        })

        return state

    def _append_to_google_sheet(self, booking: dict) -> int:
        """
        Appends booking row to the Google Sheet using GSheets API and service account credentials.
        """
        scopes = ['https://www.googleapis.com/auth/spreadsheets']
        creds = service_account.Credentials.from_service_account_file(self.creds_path, scopes=scopes)
        service = build('sheets', 'v4', credentials=creds)
        
        # Map values to columns:
        # booking_id | timestamp | service | provider_name | location | slot | status | price_estimate
        row_data = [
            booking["booking_id"],
            booking["created_at"],
            booking["service_type"],
            booking["provider_name"],
            booking["location"],
            booking["slot_display"],
            booking["status"],
            booking["price_estimate"]
        ]
        
        body = {
            'values': [row_data]
        }
        
        # We append to "Sheet1!A:H"
        result = service.spreadsheets().values().append(
            spreadsheetId=self.sheet_id,
            range="Sheet1!A:H",
            valueInputOption="USER_ENTERED",
            body=body
        ).execute()
        
        import re
        # Try to parse the range to get the row number
        # Output range is usually "Sheet1!A42:H42"
        updated_range = result.get("updates", {}).get("updatedRange", "")
        row_number = 0
        if updated_range:
            parts = updated_range.split("!")[-1]
            # Match the first number
            match = re.search(r'\d+', parts)
            if match:
                row_number = int(match.group())
                
        return row_number

    def _get_fallback_provider(self, provider_id: str) -> dict:
        filepath = os.path.join(os.path.dirname(__file__), "..", "data", "mock_providers.json")
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                all_providers = json.load(f)
                for p in all_providers:
                    if p["id"] == provider_id:
                        return p
        except Exception:
            pass
        return {"id": provider_id, "name": "Haazir Service Partner", "price_range": "PKR 1000-2000"}
