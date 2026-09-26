class_name Hero
extends CharacterBody3D
## The player character. Owns movement, dash, hearts and reactions to
## influences; abilities are Verb children supplied by the HeroClass. Device
## input is read only when use_device_input is true. Tests drive move_input,
## request_dash() and set_verb_held() directly.

signal hearts_changed(hearts: int, max_hearts: int)
signal heart_lost(reason: StringName)
signal failed
signal dashed
signal overload_started(id: StringName)

const BASE_STATES := [
	preload("res://data/states/weight.tres"),
	preload("res://data/states/charge.tres"),
]
const TOON_MATERIAL: ShaderMaterial = preload("res://shaders/toon_outline_material.tres")
const SLOT_FORCE := &"force"
const SLOT_RESTORE := &"restore"

@export var hero_class: HeroClass
@export var max_hearts: int = 5
@export var gravity: float = 20.0
@export var friction: float = 40.0
@export var dash_time: float = 0.18
@export var dash_cooldown: float = 0.4
@export var surge_speed: float = 9.0
@export var knockback_scale: float = 1.5
@export var knockback_decay: float = 12.0
@export var heart_invuln_time: float = 1.0
@export var safe_hazard_margin: float = 0.75
@export var safe_creature_distance: float = 2.0
@export var use_device_input: bool = true

var hearts: int = 0
var facing := Vector2.DOWN   # x -> world x, y -> world z
var move_input := Vector2.ZERO
var dash_iframes := false
var invulnerable_left := 0.0
var rooted_left := 0.0
var surge_left := 0.0
var last_safe_position := Vector3.ZERO
var force_verb: Verb
var restore_verb: Verb
var anim_player: AnimationPlayer

var _move_velocity := Vector3.ZERO
var _knockback := Vector3.ZERO
var _dash_left := 0.0
var _dash_cooldown_left := 0.0
var _dash_dir := Vector3.ZERO
var _held := {SLOT_FORCE: false, SLOT_RESTORE: false}
# a verb only receives held/released after it received pressed (see Verb)
var _delivered := {SLOT_FORCE: false, SLOT_RESTORE: false}

@onready var gauge: StateGauge = $StateGauge
@onready var visuals: Node3D = $Visuals
@onready var verbs_root: Node = $Verbs

func _ready() -> void:
	add_to_group("hero")
	add_to_group("influenceable")
	gauge.overloaded.connect(_on_overloaded)
	apply_class(hero_class)
	hearts = max_hearts
	last_safe_position = global_position
	hearts_changed.emit(hearts, max_hearts)

# --- class setup ---

func apply_class(new_class: HeroClass) -> void:
	hero_class = new_class if new_class else HeroClass.new()
	for def in BASE_STATES:
		gauge.register(def)
	for def in hero_class.state_overrides:
		gauge.override_definition(def)
	_rebuild_model()
	_rebuild_verbs()

func _rebuild_model() -> void:
	for child in visuals.get_children():
		child.free()
	anim_player = null
	if hero_class.model == null:
		return
	var model := hero_class.model.instantiate()
	visuals.add_child(model)
	ToonUtil.apply_toon(model, TOON_MATERIAL)
	anim_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer

func _rebuild_verbs() -> void:
	for child in verbs_root.get_children():
		child.free()
	for slot in _held:
		_held[slot] = false
		_delivered[slot] = false
	force_verb = _make_verb(hero_class.force_verb)
	restore_verb = _make_verb(hero_class.restore_verb)

func _make_verb(scene: PackedScene) -> Verb:
	if scene == null:
		return null
	var verb := scene.instantiate() as Verb
	verbs_root.add_child(verb)
	verb.setup(self)
	return verb

# --- public API ---

func facing_3d() -> Vector3:
	return Vector3(facing.x, 0.0, facing.y)

func is_controllable() -> bool:
	return rooted_left <= 0.0 and surge_left <= 0.0

func is_dashing() -> bool:
	return _dash_left > 0.0

func set_verb_held(slot: StringName, held: bool) -> void:
	if _held.get(slot, false) == held:
		return
	_held[slot] = held
	var verb := _verb_for(slot)
	if verb == null:
		return
	if held:
		if is_controllable():
			_delivered[slot] = true
			verb.on_pressed()
	elif _delivered[slot]:
		_delivered[slot] = false
		verb.on_released()

func request_dash() -> void:
	if _dash_cooldown_left > 0.0 or is_dashing() or not is_controllable():
		return
	var dir := Vector3(move_input.x, 0.0, move_input.y)
	if dir.length() < 0.1:
		dir = facing_3d()
	_dash_dir = dir.normalized()
	_dash_left = dash_time
	_dash_cooldown_left = dash_time + dash_cooldown
	dash_iframes = true
	Juice.sfx("dash")
	Juice.burst(global_position + Vector3.UP * 0.2, Color(0.85, 0.9, 1.0), 8)
	dashed.emit()

func find_influenceables(radius: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group("influenceable"):
		if n == self or not (n is Node3D):
			continue
		var d: Vector3 = (n as Node3D).global_position - global_position
		d.y = 0.0
		if d.length() <= radius:
			out.append(n)
	return out

func play_anim(anim: StringName) -> void:
	if anim_player and anim_player.has_animation(anim):
		anim_player.play(anim)

func lose_heart(reason: StringName) -> bool:
	if hearts <= 0 or invulnerable_left > 0.0:
		return false
	hearts -= 1
	invulnerable_left = heart_invuln_time
	hearts_changed.emit(hearts, max_hearts)
	heart_lost.emit(reason)
	Juice.hitstop(120)
	Juice.shake(0.7)
	Juice.haptic(120)
	Juice.sfx("heart_lost")
	ToonUtil.flash(self, visuals, Color(1.0, 0.25, 0.25), 0.2)
	if hearts == 0:
		failed.emit()
	return true

func restore_hearts() -> void:
	hearts = max_hearts
	invulnerable_left = 0.0
	gauge.clear_all()
	hearts_changed.emit(hearts, max_hearts)

func respawn_at(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_move_velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	_dash_left = 0.0
	dash_iframes = false
	surge_left = 0.0
	rooted_left = 0.0
	last_safe_position = pos

func receive_influence(inf: Influence) -> void:
	match inf.kind:
		Influence.Kind.HAZARD:
			_on_hazard()
		Influence.Kind.STATE:
			if not dash_iframes:
				gauge.add(inf.state_id, inf.amount)
		Influence.Kind.FORCE:
			if not dash_iframes and inf.source != self:
				_knockback += inf.direction * inf.amount * knockback_scale \
					* gauge.modifier(StateDefinition.MOD_KNOCKBACK_TAKEN)

# --- frame update ---

func _physics_process(delta: float) -> void:
	if use_device_input:
		_read_device_input()
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	_dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)
	_tick_verbs(delta)
	var planar := _locomotion(delta) + _knockback
	_knockback = _knockback.move_toward(Vector3.ZERO, knockback_decay * delta)
	velocity.x = planar.x
	velocity.z = planar.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()
	_update_safe_position()
	_update_animation()

func _read_device_input() -> void:
	move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dash"):
		request_dash()
	_poll_verb(SLOT_FORCE, "force")
	_poll_verb(SLOT_RESTORE, "restore")

func _poll_verb(slot: StringName, action: StringName) -> void:
	var down := Input.is_action_pressed(action)
	if Input.is_action_just_pressed(action) and not down:
		# tapped and released between physics polls (fast touch taps do
		# this): deliver the press so the tap isn't lost
		set_verb_held(slot, true)
	set_verb_held(slot, down)

func _tick_verbs(delta: float) -> void:
	for slot in _held:
		var verb := _verb_for(slot)
		if verb == null:
			continue
		if _delivered[slot]:
			verb.on_held(delta)
		verb.tick(delta)

func _locomotion(delta: float) -> Vector3:
	if surge_left > 0.0:
		surge_left -= delta
		return _dash_dir * surge_speed
	if rooted_left > 0.0:
		rooted_left -= delta
		_move_velocity = Vector3.ZERO
		return Vector3.ZERO
	if _dash_left > 0.0:
		_dash_left -= delta
		if _dash_left <= 0.0:
			dash_iframes = false
			_move_velocity = _dash_dir * _top_speed()
		return _dash_dir * _dash_speed()
	return _steer(delta)

func _steer(delta: float) -> Vector3:
	var input := move_input.limit_length(1.0)
	var desired := Vector3(input.x, 0.0, input.y) * _top_speed() * _verb_move_multiplier()
	var rate: float
	if input.length() > 0.01:
		rate = hero_class.base_accel * gauge.modifier(StateDefinition.MOD_ACCEL)
		_turn_toward(input.normalized(), delta)
	else:
		rate = friction * gauge.modifier(StateDefinition.MOD_FRICTION)
	_move_velocity = _move_velocity.move_toward(desired, rate * delta)
	return _move_velocity

func _turn_toward(dir: Vector2, delta: float) -> void:
	var max_step := hero_class.base_turn_rate * gauge.modifier(StateDefinition.MOD_TURN_RATE) * delta
	var diff := wrapf(dir.angle() - facing.angle(), -PI, PI)
	facing = Vector2.from_angle(facing.angle() + clampf(diff, -max_step, max_step))
	visuals.rotation.y = atan2(facing.x, facing.y)

func _top_speed() -> float:
	return hero_class.base_speed * gauge.modifier(StateDefinition.MOD_MOVE_SPEED)

func _dash_speed() -> float:
	return hero_class.dash_distance * gauge.modifier(StateDefinition.MOD_DASH_DISTANCE) / dash_time

func _verb_move_multiplier() -> float:
	var m := 1.0
	for verb in [force_verb, restore_verb]:
		if verb:
			m *= verb.move_multiplier()
	return m

func _verb_for(slot: StringName) -> Verb:
	return force_verb if slot == SLOT_FORCE else restore_verb

## Losing control releases any held verb once; the player must press again
## after control returns (a channel never silently resumes).
func _interrupt_verbs() -> void:
	for slot in _delivered:
		if _delivered[slot]:
			_delivered[slot] = false
			var verb := _verb_for(slot)
			if verb:
				verb.on_released()

func _on_overloaded(_id: StringName, def: StateDefinition) -> void:
	_interrupt_verbs()
	_dash_left = 0.0
	dash_iframes = false
	match def.overload:
		StateDefinition.Overload.ROOT:
			rooted_left = def.overload_duration
			Juice.sfx("overload_root")
			Juice.burst(global_position + Vector3.UP * 0.1, Color(0.62, 0.55, 0.45), 22)
		StateDefinition.Overload.SURGE:
			var heading := Vector3(_move_velocity.x, 0.0, _move_velocity.z)
			_dash_dir = heading.normalized() if heading.length() > 0.2 else facing_3d()
			surge_left = def.overload_duration
			Juice.sfx("overload_surge")
			Juice.burst(global_position + Vector3.UP * 0.5, Color(0.3, 0.95, 1.0), 22)
	Juice.shake(0.5)
	overload_started.emit(def.id)
	lose_heart(&"overload")

func _on_hazard() -> void:
	_interrupt_verbs()
	lose_heart(&"hazard")
	Juice.sfx("hazard")
	respawn_at(last_safe_position)

func _update_safe_position() -> void:
	if not is_on_floor() or not is_controllable() or is_dashing():
		return
	var pos := global_position
	for hazard in get_tree().get_nodes_in_group("hazard"):
		if hazard.has_method("contains_point") and hazard.contains_point(pos, safe_hazard_margin):
			return
	for creature in get_tree().get_nodes_in_group("creature"):
		if (creature as Node3D).global_position.distance_to(pos) < safe_creature_distance:
			return
	last_safe_position = pos

func _update_animation() -> void:
	if anim_player == null or (force_verb and force_verb.active):
		return
	# let the attack clip's follow-through finish after the hit lands
	if anim_player.current_animation == &"attack" and anim_player.is_playing():
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	var anim := &"walk" if moving else &"idle"
	if anim_player.current_animation != anim and anim_player.has_animation(anim):
		anim_player.play(anim)
