Yes. Here is the full implementation plan for your Godot pronunciation mode using Azure Speech Pronunciation Assessment.

The final flow will be:

Godot records player voice
        ↓
Godot sends .wav audio to your backend
        ↓
FastAPI backend sends audio + expected word to Azure
        ↓
Azure returns pronunciation score
        ↓
Backend decides correct/wrong
        ↓
Godot performs action if correct

Azure Pronunciation Assessment is designed to evaluate spoken pronunciation using Speech SDK, and it can return accuracy, fluency, completeness, pronunciation score, word-level error type, and phoneme-level feedback depending on configuration. Microsoft also says it uses a specific speech-to-text model for pronunciation assessment, separate from normal STT, to keep assessment consistent.

Part 1: Create Azure Speech Resource
Step 1: Go to Azure Portal

Go to Azure Portal and create a Speech resource.

Use these settings:

Service: Azure AI Speech
Pricing tier: Free F0
Region: Southeast Asia / East US / any supported region

After creating the Speech resource, Azure gives you:

SPEECH_KEY
SPEECH_REGION

Microsoft’s quickstarts require a Speech resource and its key/endpoint or region before using Speech SDK.

Save these two values carefully.

Example:

SPEECH_KEY = your_secret_key
SPEECH_REGION = southeastasia

Do not put this key inside Godot.

Part 2: Create FastAPI Backend

Create a new folder outside your Godot project:

tajweed_pronunciation_backend

Inside this folder, create these files:

tajweed_pronunciation_backend/
│
├── main.py
├── requirements.txt
├── .env
└── .gitignore
Step 1: Create requirements.txt
fastapi
uvicorn
python-dotenv
azure-cognitiveservices-speech

The Azure Speech SDK for Python is installed using pip install azure-cognitiveservices-speech, according to Microsoft’s Speech SDK setup guide.

Step 2: Create .env
SPEECH_KEY=your_azure_speech_key_here
SPEECH_REGION=your_azure_region_here

Example:

SPEECH_KEY=xxxxxxxxxxxxxxxxxxxx
SPEECH_REGION=southeastasia
Step 3: Create .gitignore
.env
__pycache__/
*.wav
*.tmp

This protects your Azure key.

Step 4: Create main.py

Use this full code:

import json
import os
import tempfile
from typing import Any, Dict

import azure.cognitiveservices.speech as speechsdk
from dotenv import load_dotenv
from fastapi import FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

SPEECH_KEY = os.getenv("SPEECH_KEY")
SPEECH_REGION = os.getenv("SPEECH_REGION")

app = FastAPI(title="Tajweed Runner Pronunciation API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_threshold(difficulty: str) -> int:
    difficulty = difficulty.lower()

    if difficulty == "easy":
        return 60

    if difficulty == "hard":
        return 80

    return 70


def assess_pronunciation_from_file(
    audio_file_path: str,
    expected_text: str,
    language: str,
) -> Dict[str, Any]:
    if not SPEECH_KEY or not SPEECH_REGION:
        return {
            "success": False,
            "error": "Missing SPEECH_KEY or SPEECH_REGION in .env file",
        }

    speech_config = speechsdk.SpeechConfig(
        subscription=SPEECH_KEY,
        region=SPEECH_REGION,
    )

    audio_config = speechsdk.audio.AudioConfig(filename=audio_file_path)

    pronunciation_config = speechsdk.PronunciationAssessmentConfig(
        reference_text=expected_text,
        grading_system=speechsdk.PronunciationAssessmentGradingSystem.HundredMark,
        granularity=speechsdk.PronunciationAssessmentGranularity.Phoneme,
        enable_miscue=True,
    )

    speech_recognizer = speechsdk.SpeechRecognizer(
        speech_config=speech_config,
        language=language,
        audio_config=audio_config,
    )

    pronunciation_config.apply_to(speech_recognizer)

    result = speech_recognizer.recognize_once()

    if result.reason == speechsdk.ResultReason.Canceled:
        cancellation = speechsdk.CancellationDetails(result)
        return {
            "success": False,
            "error": "Azure speech recognition canceled",
            "reason": str(cancellation.reason),
            "details": cancellation.error_details,
        }

    if result.reason != speechsdk.ResultReason.RecognizedSpeech:
        return {
            "success": False,
            "error": "No recognizable speech found",
            "reason": str(result.reason),
        }

    raw_json = result.properties.get(
        speechsdk.PropertyId.SpeechServiceResponse_JsonResult
    )

    if not raw_json:
        return {
            "success": False,
            "error": "Azure returned empty pronunciation result",
        }

    return {
        "success": True,
        "azure_raw": json.loads(raw_json),
    }


def extract_game_result(
    azure_raw: Dict[str, Any],
    expected_text: str,
    difficulty: str,
) -> Dict[str, Any]:
    threshold = get_threshold(difficulty)

    nbest = azure_raw.get("NBest", [])
    if not nbest:
        return {
            "correct": False,
            "message": "No pronunciation result found",
            "threshold": threshold,
        }

    best = nbest[0]

    pronunciation = best.get("PronunciationAssessment", {})

    accuracy = pronunciation.get("AccuracyScore", 0)
    fluency = pronunciation.get("FluencyScore", 0)
    completeness = pronunciation.get("CompletenessScore", 0)
    pron_score = pronunciation.get("PronScore", 0)

    recognized_text = best.get("Display", "")

    words = best.get("Words", [])
    word_feedback = []

    has_bad_word = False

    for word in words:
        word_text = word.get("Word", "")
        word_pron = word.get("PronunciationAssessment", {})
        word_score = word_pron.get("AccuracyScore", 0)
        error_type = word_pron.get("ErrorType", "None")

        if error_type != "None" or word_score < 60:
            has_bad_word = True

        word_feedback.append(
            {
                "word": word_text,
                "accuracy": word_score,
                "error_type": error_type,
            }
        )

    correct = (
        accuracy >= threshold
        and completeness >= 60
        and not has_bad_word
    )

    if correct:
        message = "Good pronunciation! Action unlocked."
    else:
        message = "Try again. Pronunciation was not clear enough."

    return {
        "correct": correct,
        "message": message,
        "expected_text": expected_text,
        "recognized_text": recognized_text,
        "difficulty": difficulty,
        "threshold": threshold,
        "scores": {
            "accuracy": accuracy,
            "fluency": fluency,
            "completeness": completeness,
            "pronunciation": pron_score,
        },
        "word_feedback": word_feedback,
    }


@app.get("/")
def root():
    return {
        "status": "running",
        "message": "Tajweed Runner Pronunciation API is working",
    }


@app.post("/assess")
async def assess(
    request: Request,
    expected_text: str = Query(...),
    language: str = Query("en-US"),
    difficulty: str = Query("normal"),
):
    audio_bytes = await request.body()

    if not audio_bytes:
        return {
            "success": False,
            "error": "No audio received",
        }

    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_audio:
        temp_audio.write(audio_bytes)
        temp_audio_path = temp_audio.name

    try:
        azure_result = assess_pronunciation_from_file(
            audio_file_path=temp_audio_path,
            expected_text=expected_text,
            language=language,
        )

        if not azure_result["success"]:
            return azure_result

        game_result = extract_game_result(
            azure_raw=azure_result["azure_raw"],
            expected_text=expected_text,
            difficulty=difficulty,
        )

        return {
            "success": True,
            "result": game_result,
            "azure_raw": azure_result["azure_raw"],
        }

    finally:
        if os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)

Microsoft’s guide shows the same main SDK idea: create a SpeechRecognizer, create PronunciationAssessmentConfig, apply it to the recognizer, call recognize_once, and read pronunciation results as JSON.

Part 3: Run the Backend

Open terminal inside your backend folder.

Step 1: Create virtual environment

Windows:

python -m venv venv
venv\Scripts\activate

Mac/Linux:

python3 -m venv venv
source venv/bin/activate
Step 2: Install packages
pip install -r requirements.txt
Step 3: Run server
uvicorn main:app --reload

Now your backend should run here:

http://127.0.0.1:8000

Open browser:

http://127.0.0.1:8000

You should see:

{
  "status": "running",
  "message": "Tajweed Runner Pronunciation API is working"
}
Part 4: Test Backend Before Godot

Before adding Godot, test using one .wav file.

Record a small WAV file manually, maybe saying:

apple

Save it as:

test.wav

Then run:

curl -X POST "http://127.0.0.1:8000/assess?expected_text=apple&language=en-US&difficulty=normal" ^
-H "Content-Type: audio/wav" ^
--data-binary "@test.wav"

For PowerShell, use:

curl.exe -X POST "http://127.0.0.1:8000/assess?expected_text=apple&language=en-US&difficulty=normal" `
-H "Content-Type: audio/wav" `
--data-binary "@test.wav"

Expected response style:

{
  "success": true,
  "result": {
    "correct": true,
    "message": "Good pronunciation! Action unlocked.",
    "expected_text": "apple",
    "recognized_text": "Apple.",
    "difficulty": "normal",
    "threshold": 70,
    "scores": {
      "accuracy": 85,
      "fluency": 90,
      "completeness": 100,
      "pronunciation": 87
    }
  }
}
Part 5: Godot Setup

Now we connect Godot.

Godot supports microphone input with AudioStreamMicrophone, and audio recording is handled by AudioEffectRecord with methods like get_recording(), is_recording_active(), and set_recording_active(). Godot docs also mention that audio/driver/enable_input must be enabled for microphone input to work.

Step 1: Enable audio input

In Godot:

Project → Project Settings → Audio → Driver → Enable Input

Turn it on:

audio/driver/enable_input = true
Step 2: Create audio bus for recording

Go to:

Audio panel → Bus Layout

Create a new bus:

Record

Add effect to this bus:

AudioEffectRecord

Your bus setup should look like:

Master
Record  → AudioEffectRecord
Step 3: Create Pronunciation Scene

Create a scene:

PronunciationManager.tscn

Add nodes:

PronunciationManager (Node)
├── MicPlayer (AudioStreamPlayer)
└── HTTPRequest

Attach script to PronunciationManager.

Create file:

PronunciationManager.gd
Part 6: Godot Script

Use this full script:

extends Node

signal pronunciation_success(action_name: String)
signal pronunciation_failed(message: String)

@onready var mic_player: AudioStreamPlayer = $MicPlayer
@onready var http_request: HTTPRequest = $HTTPRequest

var record_effect: AudioEffectRecord
var backend_url := "http://127.0.0.1:8000/assess"

var current_expected_word := ""
var current_action_name := ""
var current_language := "en-US"
var current_difficulty := "normal"

func _ready() -> void:
	var bus_index := AudioServer.get_bus_index("Record")

	if bus_index == -1:
		push_error("Record bus not found. Create an audio bus named 'Record'.")
		return

	record_effect = AudioServer.get_bus_effect(bus_index, 0) as AudioEffectRecord

	if record_effect == null:
		push_error("AudioEffectRecord not found on Record bus.")
		return

	mic_player.stream = AudioStreamMicrophone.new()
	mic_player.bus = "Record"
	mic_player.play()

	http_request.request_completed.connect(_on_request_completed)


func start_pronunciation_challenge(
	expected_word: String,
	action_name: String,
	language: String = "en-US",
	difficulty: String = "normal"
) -> void:
	current_expected_word = expected_word
	current_action_name = action_name
	current_language = language
	current_difficulty = difficulty

	start_recording()


func start_recording() -> void:
	if record_effect == null:
		return

	record_effect.set_recording_active(true)
	print("Recording started...")


func stop_recording_and_send() -> void:
	if record_effect == null:
		return

	record_effect.set_recording_active(false)
	print("Recording stopped.")

	var recording: AudioStreamWAV = record_effect.get_recording()

	if recording == null:
		pronunciation_failed.emit("No recording found.")
		return

	var save_path := "user://pronunciation_input.wav"
	var save_error := recording.save_to_wav(save_path)

	if save_error != OK:
		pronunciation_failed.emit("Failed to save recording.")
		return

	var audio_bytes := FileAccess.get_file_as_bytes(save_path)

	if audio_bytes.is_empty():
		pronunciation_failed.emit("Recorded audio file is empty.")
		return

	send_audio_to_backend(audio_bytes)


func send_audio_to_backend(audio_bytes: PackedByteArray) -> void:
	var url := "%s?expected_text=%s&language=%s&difficulty=%s" % [
		backend_url,
		current_expected_word.uri_encode(),
		current_language.uri_encode(),
		current_difficulty.uri_encode()
	]

	var headers := [
		"Content-Type: audio/wav"
	]

	var error := http_request.request_raw(
		url,
		headers,
		HTTPClient.METHOD_POST,
		audio_bytes
	)

	if error != OK:
		pronunciation_failed.emit("Failed to send audio to backend.")


func _on_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if response_code != 200:
		pronunciation_failed.emit("Backend error: " + str(response_code))
		return

	var response_text := body.get_string_from_utf8()
	var json_data = JSON.parse_string(response_text)

	if json_data == null:
		pronunciation_failed.emit("Invalid JSON response from backend.")
		return

	if not json_data.get("success", false):
		var error_message = json_data.get("error", "Pronunciation check failed.")
		pronunciation_failed.emit(error_message)
		return

	var result_data = json_data.get("result", {})
	var is_correct = result_data.get("correct", false)
	var message = result_data.get("message", "")

	print("Pronunciation result: ", result_data)

	if is_correct:
		pronunciation_success.emit(current_action_name)
	else:
		pronunciation_failed.emit(message)
Part 7: How to Use This in Your Game

Suppose the next obstacle requires a jump.

Then your game should call:

$PronunciationManager.start_pronunciation_challenge(
	"jump",
	"jump",
	"en-US",
	"normal"
)

When player presses the microphone button:

$PronunciationManager.start_recording()

When player releases the microphone button:

$PronunciationManager.stop_recording_and_send()

Connect signals:

func _ready() -> void:
	$PronunciationManager.pronunciation_success.connect(_on_pronunciation_success)
	$PronunciationManager.pronunciation_failed.connect(_on_pronunciation_failed)


func _on_pronunciation_success(action_name: String) -> void:
	if action_name == "jump":
		player.jump()
	elif action_name == "bridge":
		player.create_bridge()
	elif action_name == "blast":
		player.blast()
	elif action_name == "invisible":
		player.activate_invisibility()


func _on_pronunciation_failed(message: String) -> void:
	print(message)
	show_wrong_feedback(message)
Part 8: Recommended Word/Action Mapping

For your game, make the pronunciation words simple.

Obstacle	Required action	Expected spoken word
Small stone	Jump	jump
River	Bridge	bridge
Big rock / hill	Blast	blast
Enemy	Hide / invisible	hide
Coin bonus	Collect	collect

For Arabic/tajweed mode, you can use Arabic syllables/words later:

Practice type	Expected text
Alif with Fatha	أَ or a
Ba with Fatha	بَ or ba
Ta with Fatha	تَ or ta
Simple word	باب
Simple word	نور

For the first version, I recommend starting with English action words because testing will be easier. Then add Arabic after the system is stable.

Part 9: Scoring Logic

In backend, I used this:

correct = (
    accuracy >= threshold
    and completeness >= 60
    and not has_bad_word
)

The threshold changes by difficulty:

Easy   → AccuracyScore >= 60
Normal → AccuracyScore >= 70
Hard   → AccuracyScore >= 80

Azure can return AccuracyScore, FluencyScore, CompletenessScore, PronScore, and ErrorType; Microsoft describes AccuracyScore as how closely phonemes match native pronunciation, CompletenessScore as pronounced words compared to the reference text, and ErrorType as values like None, Omission, Insertion, and Mispronunciation.

For children, keep it forgiving:

Easy mode: 60
Normal mode: 70
Hard mode: 80

Do not make it too strict, because child voice, accent, noise, and microphone quality will affect the score.

Part 10: How It Should Work in Gameplay

For pronunciation mode, your game loop should be:

1. Obstacle appears
2. Game shows word to pronounce
3. Player taps/holds mic button
4. Player says the word
5. Godot sends voice to backend
6. Backend checks pronunciation
7. If correct:
      perform required action
   Else:
      show retry / slow down / lose heart

Example:

Obstacle: River
Required action: Bridge
Shown word: bridge
Player says: "bridge"
Azure score: 82
Game result: correct
Runner creates bridge

Another example:

Obstacle: Stone
Required action: Jump
Shown word: jump
Player says wrong / unclear
Azure score: 43
Game result: wrong
Runner does not jump
Part 11: UI Suggestions for Pronunciation Mode

When pronunciation challenge starts, show a small card:

Say this word:
"jump"

Hold mic and speak clearly

When recording:

Listening...

When correct:

Great! Jump unlocked

When wrong:

Try again! Say: jump

Also show score for debugging only:

Accuracy: 76
Completeness: 100

For children, in final UI, avoid too many technical scores. Use stars:

⭐⭐⭐ Great!
⭐⭐ Try again
⭐ Speak clearly
Part 12: Android Export Important Setting

For Android APK, you must allow microphone permission.

In Godot Android export settings, enable:

Record Audio

Also keep:

Project Settings → Audio → Driver → Enable Input = true

Godot docs mention AudioStreamMicrophone needs audio input enabled, and Godot’s Android export platform exposes a permissions/record_audio option.

Part 13: Local Demo vs Real Deployment

For your university demo, this is enough:

Godot game running on laptop
FastAPI backend running locally
Azure free tier

Use:

http://127.0.0.1:8000

But for Android APK on phone, 127.0.0.1 means the phone itself, not your laptop.

For phone testing, use your laptop IP address.

Example:

http://192.168.0.105:8000/assess

Run FastAPI like this:

uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Then update Godot:

var backend_url := "http://192.168.0.105:8000/assess"

Your phone and laptop must be on the same Wi-Fi.

Part 14: Final File Checklist

Backend:

main.py
requirements.txt
.env
.gitignore

Godot:

PronunciationManager.tscn
PronunciationManager.gd
Audio bus named Record
AudioEffectRecord on Record bus
MicPlayer node
HTTPRequest node

Azure:

Speech resource created
Free F0 tier selected
SPEECH_KEY copied
SPEECH_REGION copied
Part 15: Best Implementation Order

Follow this exact order:

1. Create Azure Speech resource
2. Create FastAPI backend
3. Test backend with recorded .wav file
4. Add microphone recording in Godot
5. Save Godot recording as .wav
6. Send .wav to backend
7. Receive correct/wrong response
8. Connect response with player action
9. Add UI feedback
10. Test on Android

Do not start from Android first. First make it work on PC, then export.

Final Recommended Version for Your Game

Use this stack:

Godot 4.6.1
FastAPI backend
Azure Speech Pronunciation Assessment
Free F0 tier
WAV audio upload
Simple child-friendly scoring

For first prototype, use:

Language: en-US
Words: jump, bridge, blast, hide
Difficulty: easy or normal
Threshold: 60–70

After this works perfectly, add:

Arabic pronunciation words
Bangla UI instructions
Obstacle-based pronunciation challenges
Star-based feedback