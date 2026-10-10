class_name SfxSynth
extends RefCounted
## Procedural placeholder SFX so every action has a sound before real audio
## exists. Streams are generated once and cached.

const MIX_RATE := 22050
## name -> [waveform ("sine" | "square" | "noise"), start_hz, end_hz, seconds, volume]
const PRESETS := {
	"mend": ["sine", 660.0, 880.0, 0.25, 0.2],
	"refuse": ["sine", 180.0, 100.0, 0.2, 0.18],
	"catch": ["sine", 400.0, 1100.0, 0.22, 0.3],
	"spark": ["sine", 1000.0, 500.0, 0.16, 0.2],
	"anchor": ["sine", 520.0, 1040.0, 0.5, 0.3],
	"pulse_hit": ["square", 150.0, 45.0, 0.18, 0.7],
	"pulse_emit": ["sine", 180.0, 720.0, 0.16, 0.45],
	"dash": ["noise", 0.0, 0.0, 0.12, 0.3],
	"heart_lost": ["square", 440.0, 110.0, 0.35, 0.6],
	"overload_root": ["sine", 90.0, 40.0, 0.5, 0.8],
	"overload_surge": ["square", 300.0, 900.0, 0.3, 0.5],
	"hazard": ["noise", 0.0, 0.0, 0.4, 0.5],
	"restore": ["sine", 440.0, 990.0, 0.6, 0.5],
}

static var _cache: Dictionary = {}

static func get_stream(name: String) -> AudioStreamWAV:
	if _cache.has(name):
		return _cache[name]
	if not PRESETS.has(name):
		return null
	var p: Array = PRESETS[name]
	var stream := make(p[0], p[1], p[2], p[3], p[4])
	_cache[name] = stream
	return stream

static func make(wave: String, start_hz: float, end_hz: float, seconds: float, volume: float) -> AudioStreamWAV:
	var samples := int(seconds * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var phase := 0.0
	for i in samples:
		var t := float(i) / samples
		phase += lerpf(start_hz, end_hz, t) / MIX_RATE
		var s: float
		match wave:
			"sine":
				s = sin(phase * TAU)
			"square":
				s = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			_:
				s = rng.randf() * 2.0 - 1.0
		var envelope := (1.0 - t) * (1.0 - t)
		bytes.encode_s16(i * 2, int(clampf(s * envelope * volume, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
