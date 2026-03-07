"""
Vosk Speech Recognition Server for Godot Pronunciation Mode.

Runs a WebSocket server that:
1. Receives audio data (16-bit PCM, 16kHz mono) from Godot
2. Runs Vosk speech recognition with restricted vocabulary
3. Returns recognized text back to Godot

Usage:
    python vosk_server.py

Protocol (JSON over WebSocket):
    Client -> Server:
        {"type": "config", "vocabulary": ["elephant", "chocolate", ...]}
        Binary audio frames (16-bit PCM, 16kHz, mono)
        {"type": "stop"}

    Server -> Client:
        {"type": "partial", "text": "eleph"}
        {"type": "result", "text": "elephant"}
        {"type": "final", "text": "elephant"}
        {"type": "ready"}
        {"type": "error", "message": "..."}
"""

import asyncio
import json
import os
import sys

try:
    import vosk
except ImportError:
    print("ERROR: vosk not installed. Run: pip install vosk")
    sys.exit(1)

try:
    import websockets
except ImportError:
    print("ERROR: websockets not installed. Run: pip install websockets")
    sys.exit(1)

# Suppress Vosk logs (set to -1 for silent, 0 for errors only)
vosk.SetLogLevel(-1)

MODEL_NAME = "vosk-model-small-en-us-0.15"
SAMPLE_RATE = 16000
HOST = "localhost"
PORT = 8765

model = None


def load_model():
    """Load Vosk model, auto-downloading if needed."""
    global model

    # Check for local model directory first
    script_dir = os.path.dirname(os.path.abspath(__file__))
    local_model_path = os.path.join(script_dir, "model")

    if os.path.exists(local_model_path):
        print(f"Loading local model from: {local_model_path}")
        model = vosk.Model(local_model_path)
    else:
        # Auto-download using vosk's built-in downloader
        print(f"Downloading model: {MODEL_NAME} (this may take a minute)...")
        try:
            model = vosk.Model(model_name=MODEL_NAME)
        except Exception as e:
            print(f"ERROR: Failed to load model: {e}")
            print(f"You can manually download from https://alphacephei.com/vosk/models")
            print(f"Extract to: {local_model_path}")
            sys.exit(1)

    print("Vosk model loaded successfully.")


async def handle_client(websocket):
    """Handle a single WebSocket client (Godot game)."""
    print(f"Client connected: {websocket.remote_address}")
    rec = vosk.KaldiRecognizer(model, SAMPLE_RATE)
    current_vocab_json = None  # Remember vocabulary for resets

    def make_recognizer():
        """Create a fresh recognizer with the current vocabulary."""
        if current_vocab_json:
            return vosk.KaldiRecognizer(model, SAMPLE_RATE, current_vocab_json)
        return vosk.KaldiRecognizer(model, SAMPLE_RATE)

    try:
        await websocket.send(json.dumps({"type": "ready"}))

        async for message in websocket:
            if isinstance(message, str):
                # JSON control message
                try:
                    data = json.loads(message)
                except json.JSONDecodeError:
                    continue

                msg_type = data.get("type", "")

                if msg_type == "config":
                    # Set restricted vocabulary
                    vocabulary = data.get("vocabulary", [])
                    if vocabulary:
                        vocab_with_unk = vocabulary + ["[unk]"]
                        current_vocab_json = json.dumps(vocab_with_unk)
                        rec = make_recognizer()
                        print(f"  Vocabulary set: {vocabulary}")
                    else:
                        current_vocab_json = None
                        rec = make_recognizer()
                        print("  Open vocabulary mode")

                    await websocket.send(json.dumps({"type": "ready"}))

                elif msg_type == "stop":
                    # Finalize recognition and reset for next word
                    result = json.loads(rec.FinalResult())
                    text = result.get("text", "").strip()
                    await websocket.send(
                        json.dumps({"type": "final", "text": text})
                    )
                    # Reset recognizer WITH vocabulary preserved
                    rec = make_recognizer()

                elif msg_type == "reset":
                    # Reset recognizer without finalize (for new word)
                    rec = make_recognizer()

            else:
                # Binary audio data — feed to recognizer
                if rec.AcceptWaveform(message):
                    result = json.loads(rec.Result())
                    text = result.get("text", "").strip()
                    if text:
                        await websocket.send(
                            json.dumps({"type": "result", "text": text})
                        )
                else:
                    partial = json.loads(rec.PartialResult())
                    text = partial.get("partial", "").strip()
                    if text:
                        await websocket.send(
                            json.dumps({"type": "partial", "text": text})
                        )

    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        print(f"Client disconnected: {websocket.remote_address}")


async def main():
    load_model()
    print(f"Starting Vosk server on ws://{HOST}:{PORT}")
    print("Waiting for Godot to connect...")

    async with websockets.serve(handle_client, HOST, PORT):
        await asyncio.Future()  # Run forever


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped.")
