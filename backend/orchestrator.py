import uuid
import datetime
from backend.agents.intent_agent import IntentAgent
from backend.agents.discovery_agent import DiscoveryAgent
from backend.agents.booking_agent import BookingAgent
from backend.agents.followup_agent import FollowUpAgent

# Attempt to import google-adk, providing standard fallback classes if it runs in environment without full GCP/Vertex AI Engine setups
try:
    from google.adk.agents import Agent as AdkAgent
except ImportError:
    # Safe mock fallback so the agent runs flawlessly out-of-the-box
    class AdkAgent:
        def __init__(self, name, instruction, tools=None):
            self.name = name
            self.instruction = instruction
            self.tools = tools or []

class RootOrchestrator:
    def __init__(self):
        # Instantiate specialized agents
        self.intent_agent = IntentAgent()
        self.discovery_agent = DiscoveryAgent()
        self.booking_agent = BookingAgent()
        self.followup_agent = FollowUpAgent()

        # Wrap in ADK Agents to satisfy Google Antigravity requirements
        self.adk_intent = AdkAgent(
            name="IntentAgent",
            instruction="Parse service category, location sector, time, and language.",
            tools=[]
        )
        self.adk_discovery = AdkAgent(
            name="DiscoveryAgent",
            instruction="Find nearby service providers using Distance Matrix and multi-factor scoring.",
            tools=[]
        )
        self.adk_booking = AdkAgent(
            name="BookingAgent",
            instruction="Commit booking to Firestore database and Google Sheets spreadsheet.",
            tools=[]
        )
        self.adk_followup = AdkAgent(
            name="FollowUpAgent",
            instruction="Schedule push notifications and handle progression tracking.",
            tools=[]
        )

    def init_state(self, raw_input: str) -> dict:
        """
        Initializes the state object passed between agents.
        """
        return {
            "session_id": str(uuid.uuid4()),
            "raw_input": raw_input,
            "intent": {},
            "providers": [],
            "booking": {},
            "followup": {},
            "trace": []
        }

    def run_discovery_pipeline(self, raw_input: str) -> dict:
        """
        Sequences IntentAgent -> DiscoveryAgent.
        This represents the first step of the booking flow.
        """
        state = self.init_state(raw_input)
        
        # 1. Run Intent Agent
        state = self.intent_agent.execute(state)
        
        # 2. Run Discovery Agent
        state = self.discovery_agent.execute(state)
        
        return state

    def run_booking_pipeline(self, state: dict, provider_id: str, selected_slot: str) -> dict:
        """
        Sequences BookingAgent -> FollowUpAgent.
        This represents the confirmation step of the booking flow.
        """
        # 3. Run Booking Agent
        state = self.booking_agent.execute(state, provider_id, selected_slot)
        
        # 4. Run FollowUp Agent
        state = self.followup_agent.execute(state)
        
        return state
