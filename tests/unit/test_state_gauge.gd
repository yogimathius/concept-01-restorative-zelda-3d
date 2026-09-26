extends TestCase

const WEIGHT: StateDefinition = preload("res://data/states/weight.tres")
const CHARGE: StateDefinition = preload("res://data/states/charge.tres")

var gauge: StateGauge

func before_each() -> void:
	super()
	gauge = StateGauge.new()   # deliberately not in the tree: no auto-decay
	gauge.register(WEIGHT)
	gauge.register(CHARGE)

func after_each() -> void:
	gauge.free()
	await super()

func test_add_raises_value_and_normalized() -> void:
	gauge.add(&"weight", 25.0)
	check_near(gauge.value(&"weight"), 25.0, 0.001, "value")
	check_near(gauge.normalized(&"weight"), 0.25, 0.001, "normalized")

func test_value_never_goes_negative() -> void:
	gauge.add(&"weight", -10.0)
	check_near(gauge.value(&"weight"), 0.0, 0.001, "clamped at zero")

func test_reaching_max_overloads_once_and_resets() -> void:
	var count := [0]
	gauge.overloaded.connect(func(_id: StringName, _d: StateDefinition) -> void: count[0] += 1)
	gauge.add(&"charge", 60.0)
	gauge.add(&"charge", 60.0)
	check(count[0] == 1, "overloaded should fire exactly once")
	check_near(gauge.value(&"charge"), 0.0, 0.001, "value resets to 0 on overload")

func test_decay_waits_for_delay_then_drains() -> void:
	gauge.add(&"weight", 50.0)
	gauge.tick(0.9)
	check_near(gauge.value(&"weight"), 50.0, 0.001, "no decay before delay")
	gauge.tick(0.2)
	check_near(gauge.value(&"weight"), 46.0, 0.001, "decays 20/s once past the delay")

func test_new_gain_restarts_decay_delay() -> void:
	gauge.add(&"weight", 50.0)
	gauge.tick(0.9)
	gauge.add(&"weight", 10.0)
	gauge.tick(0.9)
	check_near(gauge.value(&"weight"), 60.0, 0.001, "delay restarted by new gain")

func test_modifier_interpolates_linearly() -> void:
	gauge.add(&"weight", 50.0)
	check_near(gauge.modifier(StateDefinition.MOD_MOVE_SPEED), 0.775, 0.0001, "halfway between 1.0 and 0.55")

func test_modifier_multiplies_across_states() -> void:
	gauge.add(&"weight", 50.0)
	gauge.add(&"charge", 50.0)
	check_near(gauge.modifier(StateDefinition.MOD_MOVE_SPEED), 0.775 * 1.225, 0.0001, "product of both states")

func test_unknown_modifier_is_one() -> void:
	gauge.add(&"weight", 80.0)
	check_near(gauge.modifier("nonsense"), 1.0, 0.0001, "unknown modifier")

func test_override_keeps_value_and_changes_modifier() -> void:
	gauge.add(&"weight", 50.0)
	var strong: StateDefinition = WEIGHT.duplicate()
	strong.modifiers_at_max = {"force_output": 2.2}
	gauge.override_definition(strong)
	check_near(gauge.value(&"weight"), 50.0, 0.001, "value kept")
	check_near(gauge.modifier(StateDefinition.MOD_FORCE_OUTPUT), 1.6, 0.0001, "uses override curve")

func test_unknown_state_is_ignored() -> void:
	gauge.add(&"nope", 30.0)
	check_near(gauge.value(&"nope"), 0.0, 0.001, "unknown state reads as 0")
