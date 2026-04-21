import asyncio
import json
import sys
import threading
import time

try:
    import sounddevice as sd
    import numpy as np
    HAS_SOUNDDEVICE = True
except ImportError:
    HAS_SOUNDDEVICE = False

try:
    import websockets
except ImportError:
    print("ERROR: websockets not installed. Run: pip install websockets")
    sys.exit(1)

WS_URL = "ws://127.0.0.1:8765"
SAMPLE_RATE = 16000

WORDS = [
    # Remaining untested (Cat/Dog/Eat/Sun passed; Bus/Run/Hat failed — removed)
    "Cup", "Red", "Big", "Sit", "Top", "Bed", "Box", "Fish", "Milk", "Ball",
    "Tree", "Book", "Jump", "Stop", "Go", "Play", "Help", "Blue", "Green", "Car",
    "Hand", "Leg", "Egg", "Bag", "Pen", "Map", "Fox", "Frog", "Duck", "Pig",
    "Hen", "Cow", "Bee",
]

ATTEMPTS = 3  # tries per word — needs majority (2/3) to pass

results = {}  # word -> "pass" | "fail" | "skip"
heard_texts = []

VIRTUAL_KEYWORDS = ["virtual", "droidcam", "audiorelay", "vb-audio", "cable",
                    "voicemeeter", "sound mapper", "mapper", "primary"]

def pick_mic_device():
    """Return the index of the first real physical input device."""
    if not HAS_SOUNDDEVICE:
        return None
    devices = sd.query_devices()
    print("  [MIC] Available input devices:")
    for i, dev in enumerate(devices):
        if dev['max_input_channels'] >= 1:
            print(f"         [{i}] {dev['name']}")
    for i, dev in enumerate(devices):
        if dev['max_input_channels'] < 1:
            continue
        name_lower = dev['name'].lower()
        if any(kw in name_lower for kw in VIRTUAL_KEYWORDS):
            continue
        print(f"  [MIC] Selected device {i}: {dev['name']}")
        return i
    print("  [MIC] No non-virtual device found — using default")
    return None


async def test_words():
    if not HAS_SOUNDDEVICE:
        print("NOTE: sounddevice not installed — audio capture unavailable.")
        print("      Run: pip install sounddevice numpy")
        print("      Without it you can only manually judge results.\n")

    print("Connecting to Vosk server at", WS_URL, "...")
    try:
        ws = await websockets.connect(WS_URL, ping_interval=None)
    except Exception as e:
        print(f"ERROR: Could not connect: {e}")
        print("Make sure vosk_server.py is running first.")
        sys.exit(1)

    print("Connected!\n")

    # Consume the initial 'ready' sent on connection
    await asyncio.wait_for(ws.recv(), timeout=5.0)

    # Pick mic device once
    mic_device = pick_mic_device()

    # Send vocabulary — server replies with another 'ready'
    vocab = [w.lower() for w in WORDS]
    await ws.send(json.dumps({"type": "config", "vocabulary": vocab}))
    msg = await asyncio.wait_for(ws.recv(), timeout=5.0)  # consume post-config ready

    RECORD_SECONDS = 2.5

    for word in WORDS:
        print(f"\n{'='*50}")
        print(f"  Word: {word.upper()}")
        print(f"{'='*50}")

        attempt_passes = 0
        input(f"  Press ENTER when ready → 3 attempts will auto-run...")

        for attempt in range(1, ATTEMPTS + 1):
            # Reset recognizer and drain stale messages
            await ws.send(json.dumps({"type": "reset"}))
            heard_texts.clear()
            try:
                while True:
                    await asyncio.wait_for(ws.recv(), timeout=0.1)
            except asyncio.TimeoutError:
                pass

            print(f"\n  Attempt {attempt}/{ATTEMPTS} — speak in 1s...")
            await asyncio.sleep(1.0)
            print(f"  >> SPEAK NOW ({RECORD_SECONDS}s) <<")

            audio_chunks = []

            def callback(indata, frames, time_info, status):
                audio_chunks.append(indata.copy())

            stream = sd.InputStream(samplerate=SAMPLE_RATE, channels=1,
                                     dtype='int16', callback=callback,
                                     device=mic_device)
            stream.start()
            await asyncio.sleep(RECORD_SECONDS)
            stream.stop()
            stream.close()

            peak = 0
            if audio_chunks:
                all_audio = np.concatenate(audio_chunks, axis=0)
                peak = int(np.abs(all_audio).max())
            print(f"  Peak: {peak} {'(OK)' if peak > 500 else '(SILENT!)'}", end="  ")

            if audio_chunks:
                pcm_bytes = all_audio.tobytes()
                chunk_size = SAMPLE_RATE * 2 // 50
                for i in range(0, len(pcm_bytes), chunk_size):
                    await ws.send(pcm_bytes[i:i+chunk_size])
                    await asyncio.sleep(0.01)

            await ws.send(json.dumps({"type": "stop"}))
            try:
                for _ in range(5):
                    msg = await asyncio.wait_for(ws.recv(), timeout=2.0)
                    data = json.loads(msg)
                    t = data.get("type", "")
                    text = data.get("text", "").strip()
                    if text:
                        heard_texts.append(text)
                    if t in ("final", "result"):
                        break
            except asyncio.TimeoutError:
                pass

            heard = heard_texts[-1] if heard_texts else "(nothing)"
            matched = word.lower() in heard.lower()
            print(f"Heard: '{heard}'  {'✓' if matched else '✗'}")
            if matched:
                attempt_passes += 1

        needed = (ATTEMPTS // 2) + 1
        auto_verdict = attempt_passes >= needed
        print(f"\n  Score: {attempt_passes}/{ATTEMPTS}  →  {'AUTO-PASS' if auto_verdict else 'AUTO-FAIL'}")
        verdict = ""
        while verdict not in ("y", "n", "s"):
            default = "y" if auto_verdict else "n"
            verdict = input(f"  Accept? [Y/N/S] (default {default.upper()}): ").strip().lower()
            if not verdict:
                verdict = default

        if verdict == "y":
            results[word] = "pass"
            print(f"  → PASS")
        elif verdict == "n":
            results[word] = "fail"
            print(f"  → FAIL")
        else:
            results[word] = "skip"
            print(f"  → SKIPPED")

    try:
        await ws.close()
    except Exception:
        pass

    # Summary
    print(f"\n{'='*50}")
    print("RESULTS SUMMARY")
    print(f"{'='*50}")
    passing = [w for w, r in results.items() if r == "pass"]
    failing = [w for w, r in results.items() if r == "fail"]
    skipped = [w for w, r in results.items() if r == "skip"]

    print(f"\n✓ PASS ({len(passing)}): {', '.join(passing)}")
    print(f"✗ FAIL ({len(failing)}): {', '.join(failing)}")
    if skipped:
        print(f"  SKIP ({len(skipped)}): {', '.join(skipped)}")

    print(f"\n--- GDScript word bank (passing words only) ---")
    print("_word_bank = [")
    # Original hints from the game
    hints = {
        "Cat":"CAT","Dog":"DOG","Bus":"BUS","Eat":"EET","Run":"RUN","Hat":"HAT",
        "Sun":"SUN","Cup":"KUP","Red":"RED","Big":"BIG","Sit":"SIT","Top":"TOP",
        "Bed":"BED","Box":"BOKS","Fish":"FISH","Milk":"MILK","Ball":"BAWL",
        "Tree":"TREE","Book":"BUUK","Jump":"JUMP","Stop":"STOP","Go":"GOH",
        "Play":"PLAY","Help":"HELP","Blue":"BLOO","Green":"GREEN","Car":"KAR",
        "Hand":"HAND","Leg":"LEG","Egg":"EG","Bag":"BAG","Pen":"PEN","Map":"MAP",
        "Fox":"FOKS","Frog":"FROG","Duck":"DUK","Pig":"PIG","Hen":"HEN",
        "Cow":"KOW","Bee":"BEE",
    }
    for w in passing:
        hint = hints.get(w, w.upper())
        print(f'\t{{"word": "{w}", "correct": "{hint}"}},')
    print("]")


if __name__ == "__main__":
    asyncio.run(test_words())
