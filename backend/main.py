import os
import asyncio
import datetime
from typing import Dict, Any
from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Set sys path to include backend root
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.orchestrator import RootOrchestrator
from google.cloud import firestore

app = FastAPI(title="Haazir AI Service Orchestrator API", version="1.0.0")

# Enable CORS for Flutter mobile/web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global orchestrator and storage fallbacks
orchestrator = RootOrchestrator()
in_memory_bookings = {}
in_memory_traces = {}

# Initialize Firestore
db = None
creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if creds_path and os.path.exists(creds_path):
    try:
        db = firestore.Client()
        print("FastAPI: Firestore client successfully initialized.")
    except Exception as e:
        print(f"FastAPI: Firestore client failed to initialize: {e}")

# Pydantic models
class DiscoverRequest(BaseModel):
    query: str

class BookRequest(BaseModel):
    state: dict
    provider_id: str
    selected_slot: str
    username: str = None  # Optional field to associate booking with user

class AuthRequest(BaseModel):
    username: str
    password: str

class SearchRequest(BaseModel):
    query: str

import hashlib
import secrets

# In-memory authentication & recent search stores
in_memory_users = {}
in_memory_recent_searches = {}

def hash_password(password: str) -> tuple[str, str]:
    salt = secrets.token_hex(16)
    pw_hash = hashlib.pbkdf2_hmac(
        'sha256', 
        password.encode('utf-8'), 
        salt.encode('utf-8'), 
        100000
    ).hex()
    return pw_hash, salt

def verify_password(password: str, pw_hash: str, salt: str) -> bool:
    new_hash = hashlib.pbkdf2_hmac(
        'sha256', 
        password.encode('utf-8'), 
        salt.encode('utf-8'), 
        100000
    ).hex()
    return new_hash == pw_hash

# Status progression background worker
async def simulate_booking_progression(booking_id: str):
    """
    Simulates status updates in a compressed timeline (seconds instead of minutes)
    for interactive demo visibility in the Flutter App.
    Sequence: Confirmed -> Provider Assigned (5s) -> En Route (15s) -> Arrived (25s) -> Completed (35s)
    """
    timeline = [
        {"status": "provider_assigned", "delay": 5},
        {"status": "en_route", "delay": 10},
        {"status": "arrived", "delay": 10},
        {"status": "completed", "delay": 10}
    ]

    print(f"Starting progression simulation for booking {booking_id}...")

    for step in timeline:
        await asyncio.sleep(step["delay"])
        new_status = step["status"]
        
        # 1. Update in-memory fallback
        if booking_id in in_memory_bookings:
            in_memory_bookings[booking_id]["status"] = new_status
            print(f"In-Memory update: Booking {booking_id} status set to {new_status}")
            
        # 2. Update Firestore
        if db:
            try:
                db.collection("bookings").document(booking_id).update({
                    "status": new_status
                })
                print(f"Firestore update: Booking {booking_id} status set to {new_status}")
            except Exception as e:
                print(f"Firestore progression write failed: {e}")

@app.post("/api/agent/discover")
async def discover(request: DiscoverRequest):
    """
    Runs the Intent Parsing and Service Provider Discovery Multi-Agent Pipeline.
    """
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")
        
    try:
        # Run orchestrator discovery
        state = orchestrator.run_discovery_pipeline(request.query)
        session_id = state["session_id"]
        
        # Store trace logs in memory for trace endpoint fallback
        in_memory_traces[session_id] = state["trace"]
        
        return state
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Discovery pipeline failed: {str(e)}")

@app.post("/api/agent/book")
async def book(request: BookRequest, background_tasks: BackgroundTasks):
    """
    Runs the Booking committing and Follow-up push scheduling Multi-Agent Pipeline.
    Triggers an asynchronous background status progression simulator.
    """
    try:
        state = request.state
        provider_id = request.provider_id
        selected_slot = request.selected_slot
        username = request.username
        
        # Run orchestrator booking
        state = orchestrator.run_booking_pipeline(state, provider_id, selected_slot)
        
        booking = state.get("booking", {})
        booking_id = booking.get("booking_id")
        
        if booking_id:
            if username:
                booking["username"] = username
                
            # Save booking in-memory
            in_memory_bookings[booking_id] = booking
            
            # Save booking to Firestore if available
            if db and username:
                try:
                    db.collection("bookings").document(booking_id).set(booking)
                    print(f"Firestore update: Booking {booking_id} saved for user {username}")
                except Exception as e:
                    print(f"Firestore booking save failed: {e}")
            
            # Save final traces
            session_id = state.get("session_id")
            if session_id:
                in_memory_traces[session_id] = state["trace"]
                
            # Launch status progression in background
            background_tasks.add_task(simulate_booking_progression, booking_id)
            
        return state
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Booking pipeline failed: {str(e)}")

@app.post("/api/auth/signup")
async def signup(request: AuthRequest):
    username = request.username.strip()
    password = request.password
    
    if not username or not password:
        raise HTTPException(status_code=400, detail="Username and password are required")
        
    pw_hash, salt = hash_password(password)
    
    # Check if user already exists
    if db:
        try:
            user_doc = db.collection("users").document(username).get()
            if user_doc.exists:
                raise HTTPException(status_code=400, detail="Username already exists")
                
            db.collection("users").document(username).set({
                "username": username,
                "password_hash": pw_hash,
                "salt": salt,
                "created_at": datetime.datetime.now().isoformat(),
                "recent_searches": []
            })
        except HTTPException:
            raise
        except Exception as e:
            print(f"Firestore signup failed: {e}")
            # Fallback to in-memory if Firestore fails
            if username in in_memory_users:
                raise HTTPException(status_code=400, detail="Username already exists")
            in_memory_users[username] = {
                "username": username,
                "password_hash": pw_hash,
                "salt": salt,
                "recent_searches": []
            }
    else:
        if username in in_memory_users:
            raise HTTPException(status_code=400, detail="Username already exists")
        in_memory_users[username] = {
            "username": username,
            "password_hash": pw_hash,
            "salt": salt,
            "recent_searches": []
        }
        
    return {"status": "success", "message": "User registered successfully", "username": username}

@app.post("/api/auth/login")
async def login(request: AuthRequest):
    username = request.username.strip()
    password = request.password
    
    user_data = None
    
    if db:
        try:
            doc = db.collection("users").document(username).get()
            if doc.exists:
                user_data = doc.to_dict()
        except Exception as e:
            print(f"Firestore login check failed: {e}")
            
    if not user_data:
        user_data = in_memory_users.get(username)
        
    if not user_data:
        raise HTTPException(status_code=401, detail="Invalid username or password")
        
    pw_hash = user_data["password_hash"]
    salt = user_data["salt"]
    
    if not verify_password(password, pw_hash, salt):
        raise HTTPException(status_code=401, detail="Invalid username or password")
        
    return {
        "status": "success",
        "username": username,
        "token": f"mock-token-{secrets.token_hex(8)}"
    }

@app.get("/api/users/{username}/searches")
async def get_searches(username: str):
    searches = []
    if db:
        try:
            doc = db.collection("users").document(username).get()
            if doc.exists:
                searches = doc.to_dict().get("recent_searches", [])
                return {"username": username, "searches": searches}
        except Exception as e:
            print(f"Firestore get searches failed: {e}")
            
    searches = in_memory_recent_searches.get(username, [])
    return {"username": username, "searches": searches}

@app.post("/api/users/{username}/searches")
async def add_search(username: str, request: SearchRequest):
    query = request.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Search query cannot be empty")
        
    if db:
        try:
            doc_ref = db.collection("users").document(username)
            doc = doc_ref.get()
            if doc.exists:
                current_searches = doc.to_dict().get("recent_searches", [])
                if query in current_searches:
                    current_searches.remove(query)
                current_searches.insert(0, query)
                current_searches = current_searches[:10]  # Limit to 10 recent
                doc_ref.update({"recent_searches": current_searches})
                return {"status": "success", "searches": current_searches}
        except Exception as e:
            print(f"Firestore add search failed: {e}")
            
    current_searches = in_memory_recent_searches.get(username, [])
    if query in current_searches:
        current_searches.remove(query)
    current_searches.insert(0, query)
    current_searches = current_searches[:10]
    in_memory_recent_searches[username] = current_searches
    return {"status": "success", "searches": current_searches}

@app.get("/api/users/{username}/bookings")
async def get_user_bookings(username: str):
    user_bookings = []
    # 1. Check Firestore
    if db:
        try:
            docs = db.collection("bookings").where("username", "==", username).stream()
            for doc in docs:
                user_bookings.append(doc.to_dict())
            if user_bookings:
                # Sync in-memory cache
                for b in user_bookings:
                    bid = b.get("booking_id")
                    if bid:
                        in_memory_bookings[bid] = b
                return {"username": username, "bookings": user_bookings}
        except Exception as e:
            print(f"Firestore get user bookings failed: {e}")
            
    # 2. Check in-memory
    user_bookings = [b for b in in_memory_bookings.values() if b.get("username") == username]
    return {"username": username, "bookings": user_bookings}

@app.get("/api/agent/trace/{session_id}")
async def get_trace(session_id: str):
    """
    Returns the accumulated trace log for a given agent execution session.
    """
    trace = in_memory_traces.get(session_id)
    if not trace:
        raise HTTPException(status_code=404, detail="Trace session not found")
    return {"session_id": session_id, "trace": trace}

@app.get("/api/bookings/{booking_id}")
async def get_booking(booking_id: str):
    """
    Retrieves the status and receipt of an active booking.
    Supports Firestore with a zero-delay local fallback.
    """
    # 1. Try local in-memory first (most up-to-date in case of cold-starts/local development)
    if booking_id in in_memory_bookings:
        return in_memory_bookings[booking_id]
        
    # 2. Try Firestore
    if db:
        try:
            doc = db.collection("bookings").document(booking_id).get()
            if doc.exists:
                data = doc.to_dict()
                in_memory_bookings[booking_id] = data # sync in-memory cache
                return data
        except Exception as e:
            print(f"Firestore get booking failed: {e}")
            
    raise HTTPException(status_code=404, detail="Booking not found")

@app.post("/api/bookings/{booking_id}/rate")
async def rate_booking(booking_id: str, rating: int):
    """
    Submits a user rating for a service provider, completing the booking workflow loop.
    """
    if rating < 1 or rating > 5:
        raise HTTPException(status_code=400, detail="Rating must be between 1 and 5")
        
    if booking_id in in_memory_bookings:
        in_memory_bookings[booking_id]["status"] = "rated"
        in_memory_bookings[booking_id]["user_rating"] = rating
        
    if db:
        try:
            db.collection("bookings").document(booking_id).update({
                "status": "rated",
                "user_rating": rating
            })
        except Exception as e:
            print(f"Firestore rating update failed: {e}")
            
    return {"status": "success", "booking_id": booking_id, "new_status": "rated"}

@app.get("/health")
async def health_check():
    """
    Health check endpoint for deployments.
    """
    return {
        "status": "healthy",
        "timestamp": datetime.datetime.now().isoformat(),
        "firestore": db is not None
    }

if __name__ == "__main__":
    import uvicorn
    # Read host and port from environment or default
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host=host, port=port)
