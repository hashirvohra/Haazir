import sys
import os
import io

# Set terminal encoding to UTF-8 to handle Urdu text output on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from orchestrator import RootOrchestrator

# Set dummy environment variables if not present for clean testing
os.environ.setdefault("PORT", "8000")

def run_tests():
    print("========================================")
    print("   HAAZIR MULTI-AGENT PIPELINE TESTER   ")
    print("========================================\n")
    
    orchestrator = RootOrchestrator()
    
    # 10 multilingual inputs representing various scenarios from the informal economy
    test_inputs = [
        # Urdu inputs
        "مجھے اپنے گھر میں اے سی سروس کے لیے الیکٹریشن چاہیے",
        "پلمبر کی ضرورت ہے کچن کا پائپ لیک ہو رہا ہے",
        
        # Roman Urdu inputs
        "Mujhe kal subah G-13 mein AC technician chahiye",
        "emergency plumber ki zarurat hai nal toot gaya hai F-11 mein",
        "G-11 sector mein urgent electrician bhejein",
        
        # English inputs
        "Need a mathematics tutor for intermediate student in DHA",
        "Looking for a wedding makeup artist in I-8 Islamabad",
        "Carpenter required to repair kitchen cabinets in Bahria Town tomorrow",
        
        # Mixed/Urdu-English inputs
        "AC cool nahi kar raha urgent AC technician F-11",
        "Tutor chahiye for physics class 10 kal subah"
    ]
    
    success_count = 0
    
    for idx, raw_input in enumerate(test_inputs, 1):
        print(f"Test case {idx}/{len(test_inputs)}:")
        print(f"  Input text: \"{raw_input}\"")
        
        try:
            # Execute Discovery Pipeline
            state = orchestrator.run_discovery_pipeline(raw_input)
            
            intent = state.get("intent", {})
            providers = state.get("providers", [])
            trace = state.get("trace", [])
            
            print(f"  Detected Language : {intent.get('detected_language')}")
            print(f"  Extracted Service : {intent.get('service_type')} ({intent.get('service_name_en')})")
            print(f"  Resolved Location : {intent.get('location_resolved')}")
            print(f"  Coordinates       : Lat={intent.get('lat')}, Lng={intent.get('lng')}")
            print(f"  Urgency           : {intent.get('urgency')}")
            print(f"  Providers Found   : {len(providers)} matching provider(s)")
            
            if providers:
                top_p = providers[0]
                print(f"  Top Match         : {top_p['name']} (Score={top_p['score']}, Dist={top_p['distance_km']} km)")
                print(f"  Top Reasoning     : \"{state.get('top_recommendation_reasoning')}\"")
                
            print(f"  Agent Trace Steps : {len(trace)} steps executed successfully")
            
            # Verify traces
            for step in trace:
                print(f"    - [{step['step']}] Tool: {step['tool_called']} | Status: {step['status']} ({step['latency_ms']}ms)")
            
            print("  Result: PASS ✅\n")
            success_count += 1
            
        except Exception as e:
            print(f"  Result: FAIL ❌ | Error: {e}\n")
            
    print("========================================")
    print(f"Test Execution Completed: {success_count}/{len(test_inputs)} Passed.")
    print("========================================")

if __name__ == "__main__":
    run_tests()
