import os
import json
import datetime
from google.cloud import firestore

class FollowUpAgent:
    def __init__(self):
        self.db = None
        self.creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        
        if self.creds_path and os.path.exists(self.creds_path):
            try:
                self.db = firestore.Client()
            except Exception as e:
                print(f"FollowUpAgent: Firestore client init failed: {e}")

    def execute(self, state: dict) -> dict:
        """
        Schedules automated FCM push notification payloads and establishes a compressed 
        timeline of status updates for demo purposes.
        """
        start_time = datetime.datetime.now()
        booking = state.get("booking", {})
        booking_id = booking.get("booking_id")
        provider_name = booking.get("provider_name", "Haazir Partner")
        service_type = booking.get("service_type", "ac_technician")
        slot_display = booking.get("slot_display", "Today")

        # 1. REMINDER NOTIFICATION (Simulated Twilio/FCM Payload)
        # Scheduled for 1 hour before the slot (or instantly for demo)
        fcm_payload = {
            "title": f"Your {service_type.replace('_', ' ').title()} is confirmed",
            "body": f"{provider_name} will arrive at {slot_display}. Be ready!",
            "send_at": (datetime.datetime.now() + datetime.timedelta(minutes=1)).isoformat(),
            "target": "user_device_token"
        }

        # 2. STATUS SCHEDULE (For Frontend Stream Tracking)
        # Define the compressed seconds/minutes timeline for the live dashboard demo
        status_schedule = [
            {"step": 1, "status": "confirmed", "delay_seconds": 0, "completed": True},
            {"step": 2, "status": "provider_assigned", "delay_seconds": 10, "completed": False},
            {"step": 3, "status": "en_route", "delay_seconds": 25, "completed": False},
            {"step": 4, "status": "arrived", "delay_seconds": 40, "completed": False},
            {"step": 5, "status": "completed", "delay_seconds": 55, "completed": False}
        ]

        tool_called = "schedule_fcm_notification"
        fcm_success = False

        # In production, we would call the firebase_admin messaging SDK
        # For the demo, we write the notifications and schedule list to the booking document in Firestore
        # The background status simulator in FastAPI will process these steps
        if self.db and booking_id:
            try:
                self.db.collection("bookings").document(booking_id).update({
                    "fcm_payload": fcm_payload,
                    "status_schedule": status_schedule
                })
                fcm_success = True
                tool_called += " + update_firestore_status_schedule"
            except Exception as e:
                print(f"FollowUpAgent: Failed to update Firestore with schedule: {e}")

        followup_object = {
            "reminder_scheduled": True,
            "reminder_notification_payload": fcm_payload,
            "status_schedule": status_schedule,
            "completion_prompt_scheduled": True
        }

        state["followup"] = followup_object

        # Calculate latency
        latency_ms = int((datetime.datetime.now() - start_time).total_seconds() * 1000)

        # Append to trace log
        state["trace"].append({
            "step": "FollowUpAgent",
            "tool_called": tool_called,
            "input_summary": f"booking_id: {booking_id}",
            "output_summary": f"Scheduled FCM reminder. Set up compressed 5-step status progression timeline.",
            "latency_ms": latency_ms,
            "status": "success" if fcm_success else "fallback"
        })

        return state
