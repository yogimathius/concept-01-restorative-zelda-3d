class_name StateGauge
extends Node
## Holds state values (Weight, Charge) for one entity. Owners route STATE
## influences into add(). Values decay after a delay; reaching max emits
## overloaded and resets the state to zero.

signal changed(id: StringName, normalized: float)
signal overloaded(id: StringName, definition: StateDefinition)

var _defs: Dictionary = {}        # StringName -> StateDefinition
var _values: Dictionary = {}      # StringName -> float
var _since_gain: Dictionary = {}  # StringName -> seconds since last gain

func register(def: StateDefinition) -> void:
	_defs[def.id] = def
	_values[def.id] = 0.0
	_since_gain[def.id] = 0.0

func override_definition(def: StateDefinition) -> void:
	var keep: float = _values.get(def.id, 0.0)
	_defs[def.id] = def
	_values[def.id] = minf(keep, def.max_value)
	if not _since_gain.has(def.id):
		_since_gain[def.id] = 0.0

func add(id: StringName, amount: float) -> void:
	if not _defs.has(id):
		return
	var def: StateDefinition = _defs[id]
	_values[id] = clampf(_values[id] + amount, 0.0, def.max_value)
	if amount > 0.0:
		_since_gain[id] = 0.0
	changed.emit(id, normalized(id))
	if _values[id] >= def.max_value:
		_values[id] = 0.0
		changed.emit(id, 0.0)
		overloaded.emit(id, def)

func value(id: StringName) -> float:
	return _values.get(id, 0.0)

func normalized(id: StringName) -> float:
	if not _defs.has(id):
		return 0.0
	var def: StateDefinition = _defs[id]
	return _values[id] / def.max_value if def.max_value > 0.0 else 0.0

func definition(id: StringName) -> StateDefinition:
	return _defs.get(id)

func clear_all() -> void:
	for id in _values:
		_values[id] = 0.0
		changed.emit(id, 0.0)

func modifier(name: String) -> float:
	var result := 1.0
	for id in _defs:
		result *= (_defs[id] as StateDefinition).modifier(name, normalized(id))
	return result

func tick(delta: float) -> void:
	for id in _defs:
		_since_gain[id] += delta
		var def: StateDefinition = _defs[id]
		if _values[id] > 0.0 and _since_gain[id] >= def.decay_delay:
			_values[id] = maxf(0.0, _values[id] - def.decay_rate * delta)
			changed.emit(id, normalized(id))

func _physics_process(delta: float) -> void:
	tick(delta)
