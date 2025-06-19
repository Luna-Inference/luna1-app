import requests

# Server base URL
BASE_URL = "http://100.76.203.80:8848"

def list_voices():
    try:
        response = requests.get(f"{BASE_URL}/api/v1/speakers")
        response.raise_for_status()
        speakers = response.json()
        
        print("Available Voices:")
        for name, speaker_id in sorted(speakers.items()):
            print(f"  - {name}: {speaker_id}")
    except requests.RequestException as e:
        print("Error retrieving voices:", e)

if __name__ == "__main__":
    list_voices()
