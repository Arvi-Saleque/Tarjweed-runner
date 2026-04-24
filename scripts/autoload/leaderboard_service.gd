extends Node
## LeaderboardService — Firebase Realtime Database integration.
## Submits run entries and fetches the global leaderboard via REST.
## All operations are fire-and-forget / callback-based; the game never
## blocks or crashes when the network is unavailable.

const FIREBASE_BASE := "https://tajweed-runner-default-rtdb.asia-southeast1.firebasedatabase.app"
const ENDPOINT      := FIREBASE_BASE + "/leaderboard.json"
const FETCH_LIMIT   := 100


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# ---------------------------------------------------------------------------
# submit_entry — POST one entry after a run ends.
# Silent on network error; the local leaderboard is already saved first.
# ---------------------------------------------------------------------------
func submit_entry(entry: Dictionary) -> void:
	var http := HTTPRequest.new()
	http.timeout = 8.0
	http.use_threads = true
	http.set_tls_options(TLSOptions.client_unsafe())
	add_child(http)

	var body    := JSON.stringify(entry)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err     := http.request(ENDPOINT, headers, HTTPClient.METHOD_POST, body)

	if err != OK:
		print("LeaderboardService: submit_entry request failed (err=%d)" % err)
		http.queue_free()
		return

	http.request_completed.connect(func(result: int, code: int, _hdrs, _body):
		if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
			print("LeaderboardService: submit_entry HTTP %d (result=%d)" % [code, result])
		else:
			print("LeaderboardService: submit_entry OK (HTTP %d)" % code)
		http.queue_free()
	)


# ---------------------------------------------------------------------------
# fetch_global — GET the top FETCH_LIMIT entries ordered by distance desc.
# Calls on_done(entries: Array, success: bool) when done.
#   success=true,  entries non-empty  → valid data
#   success=true,  entries empty      → DB is empty (no runs yet)
#   success=false, entries empty      → real network / parse error
# ---------------------------------------------------------------------------
func fetch_global(on_done: Callable) -> void:
	# Fetch all entries — sorted client-side. No query params needed (avoids
	# Firebase 400 "orderBy required with limitToLast" on the free Spark plan).
	var url  := FIREBASE_BASE + "/leaderboard.json"
	var http := HTTPRequest.new()
	http.timeout = 12.0
	http.use_threads = true
	http.set_tls_options(TLSOptions.client_unsafe())
	add_child(http)

	print("LeaderboardService: fetch_global -> %s" % url)
	var err := http.request(url, [], HTTPClient.METHOD_GET, "")
	if err != OK:
		print("LeaderboardService: fetch_global request() failed (err=%d)" % err)
		http.queue_free()
		on_done.call([], false)
		return

	http.request_completed.connect(func(result: int, code: int, _hdrs, raw_body: PackedByteArray):
		http.queue_free()

		if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
			print("LeaderboardService: fetch_global FAILED — HTTP %d result=%d (5=TLS,4=conn,3=dns,2=cantconnect)" % [code, result])
			on_done.call([], false)
			return

		print("LeaderboardService: fetch_global OK (HTTP %d)" % code)
		var text := raw_body.get_string_from_utf8()

		var json := JSON.new()
		if json.parse(text) != OK:
			push_warning("LeaderboardService: fetch_global JSON parse error — body: %s" % text.left(200))
			on_done.call([], false)
			return

		var data: Variant = json.get_data()

		# Firebase returns JSON null when the /leaderboard node has no data yet — valid empty
		if data == null or data is bool:
			on_done.call([], true)
			return

		if not data is Dictionary:
			push_warning("LeaderboardService: fetch_global unexpected data type")
			on_done.call([], false)
			return

		# Convert Firebase object (keyed by push-ID) to a plain Array
		var entries: Array[Dictionary] = []
		for key in (data as Dictionary):
			var v: Variant = (data as Dictionary)[key]
			if v is Dictionary:
				entries.append((v as Dictionary).duplicate(true))

		# Sort by distance descending, tiebreak by coins, cap at FETCH_LIMIT
		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var da: int = int(a.get("distance", 0))
			var db: int = int(b.get("distance", 0))
			if da == db:
				return int(a.get("coins", 0)) > int(b.get("coins", 0))
			return da > db
		)
		if entries.size() > FETCH_LIMIT:
			entries.resize(FETCH_LIMIT)

		on_done.call(entries, true)
	)
