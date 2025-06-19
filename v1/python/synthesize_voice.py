import requests

# Server base URL
BASE_URL = "http://100.76.203.80:8848"

# Step 1: Get speaker mapping
def get_speakers():
    response = requests.get(f"{BASE_URL}/api/v1/speakers")
    response.raise_for_status()
    return response.json()

# Step 2: Synthesize audio from text
def synthesize(text, speaker_name="Asta", audio_format="opus", output_file="output.ogg"):
    speakers = get_speakers()
    # speaker_id = speakers.get(speaker_name)

    # if speaker_id is None:
        # raise ValueError(f"Speaker '{speaker_name}' not found in speaker list.")

    payload = {
        "text": text,
        # "speaker_id": speaker_id,
        "audio_format": audio_format
    }

    response = requests.post(
        f"{BASE_URL}/api/v1/synthesise",
        json=payload,
        headers={"Content-Type": "application/json"}
    )
    response.raise_for_status()

    with open(output_file, "wb") as f:
        f.write(response.content)
    print(f"Saved audio to {output_file}")

# Example usage
if __name__ == "__main__":
    text_to_speak = "Stop, bitch"
    synthesize(text_to_speak, speaker_name="Asta", output_file="asta.ogg")
