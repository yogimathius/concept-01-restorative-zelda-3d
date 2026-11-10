class_name WaykeeperResources
extends RefCounted
## Resource rules independent of region, UI and legacy combat fixtures.
## tick() is called only during active play; saves never regenerate offline.
signal changed
signal unmoored
const STABILITY_MAX := 100.0
const FLOW_MAX := 100.0
const FLOW_REGEN := 8.0
const WATER_REGEN := 6.0
const LOSS_GRACE := 4.0
var max_stability := STABILITY_MAX
var max_flow := FLOW_MAX
var water_bonus := 0.0
var linked_bonus := 0.0
var completion_bonus := 0.0
var stability := STABILITY_MAX
var flow := FLOW_MAX
var protection_left := 0.0
var since_loss := LOSS_GRACE
var spending_left := 0.0

func can_spend(amount: float) -> bool:
	return is_finite(amount) and amount >= 0 and stability > 0 and flow + 0.00001 >= amount

func spend(amount: float) -> bool:
	if not can_spend(amount): return false
	flow = maxf(0, flow - amount)
	if amount > 0: spending_left = 0.15
	changed.emit()
	return true

func lose_stability(amount: float, weight := 0.0) -> bool:
	if not is_finite(amount) or amount <= 0 or stability <= 0 or protection_left > 0: return false
	stability = maxf(0, stability - amount * (1.0 - 0.25 * clampf(weight, 0, 1)))
	protection_left = 1.0
	since_loss = 0.0
	changed.emit()
	if stability <= 0: unmoored.emit()
	return true

func tick(delta: float, healthy_water := false, weight := 0.0, charge := 0.0, linked_water := false, living_shelter := false) -> void:
	if delta <= 0 or not is_finite(delta) or stability <= 0: return
	protection_left = maxf(0, protection_left - delta)
	var previous_stability := stability
	var previous_flow := flow
	since_loss = minf(LOSS_GRACE, since_loss + delta)
	var regenerating := FLOW_REGEN if spending_left <= 0 else FLOW_REGEN * 0.5
	spending_left = maxf(0, spending_left - delta)
	if healthy_water: regenerating += WATER_REGEN + water_bonus
	if linked_water: regenerating += linked_bonus
	flow = minf(max_flow, flow + regenerating * (1 - 0.25 * clampf(weight,0,1) + 0.5 * clampf(charge,0,1)) * delta)
	if since_loss >= LOSS_GRACE:
		stability = minf(max_stability, stability + ((3.0 if healthy_water else 1.0) + (2.0 if living_shelter else 0.0)) * delta)
	if stability != previous_stability or flow != previous_flow: changed.emit()

func restoration_reward() -> void:
	# Called only by a first-time completion, never by save replay or an empty cast.
	if stability <= 0: return
	flow = minf(max_flow, flow + 12.0 + completion_bonus)
	stability = minf(max_stability, stability + 10.0)
	changed.emit()

func recover() -> void:
	stability = max_stability
	flow = maxf(flow, max_flow * 0.5)
	protection_left = 2.0
	since_loss = 0.0
	spending_left = 0.0
	changed.emit()

func to_data() -> Dictionary:
	return {"stability":stability,"flow":flow,"protection":protection_left,"since_loss":since_loss,"spending":spending_left}

func apply_data(data: Dictionary) -> void:
	stability = _number(data.get("stability"), max_stability, max_stability)
	flow = _number(data.get("flow"), max_flow, max_flow)
	protection_left = _number(data.get("protection"),0,2)
	since_loss = _number(data.get("since_loss"),LOSS_GRACE,LOSS_GRACE)
	spending_left = _number(data.get("spending"),0,0.15)
	changed.emit()

func _number(value: Variant, fallback: float, ceiling: float) -> float:
	if not (value is float or value is int): return fallback
	return clampf(value,0,ceiling) if is_finite(value) else fallback

func configure(nodes: PackedStringArray) -> void:
	max_stability = STABILITY_MAX + (8.0 if nodes.has("steady_vessel") else 0.0)
	max_flow = FLOW_MAX + (10.0 if nodes.has("deep_reserve") else 0.0)
	water_bonus = 4.0 if nodes.has("spring_attunement") else 0.0
	linked_bonus = 4.0 if nodes.has("living_conduit") else 0.0
	completion_bonus = 8.0 if nodes.has("restoration_return") else 0.0
	stability = minf(stability,max_stability)
	flow = minf(flow,max_flow)
	changed.emit()
