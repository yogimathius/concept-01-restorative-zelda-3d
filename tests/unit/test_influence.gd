extends TestCase

class Receiver extends Node3D:
	var received: Array = []
	func receive_influence(inf: Influence) -> void:
		received.append(inf)

func test_force_flattens_and_normalizes_direction() -> void:
	var inf := Influence.force(null, 8.0, Vector3(3, 5, 4))
	check(inf.kind == Influence.Kind.FORCE, "kind should be FORCE")
	check_near(inf.direction.y, 0.0, 0.0001, "direction y flattened")
	check_near(inf.direction.length(), 1.0, 0.0001, "direction normalized")
	check_near(inf.direction.x, 0.6, 0.0001, "direction x")
	check_near(inf.amount, 8.0, 0.0001, "amount")

func test_zero_direction_stays_zero() -> void:
	var inf := Influence.force(null, 3.0, Vector3(0, 2, 0))
	check(inf.direction == Vector3.ZERO, "vertical-only direction flattens to zero")

func test_state_factory_sets_id_and_amount() -> void:
	var inf := Influence.state(null, &"weight", 25.0)
	check(inf.kind == Influence.Kind.STATE, "kind should be STATE")
	check(inf.state_id == &"weight", "state id")
	check_near(inf.amount, 25.0, 0.0001, "amount")

func test_send_delivers_to_receiver() -> void:
	var r := Receiver.new()
	world.add_child(r)
	var ok := Influence.send(r, Influence.hazard(null))
	check(ok, "send should report delivery")
	check(r.received.size() == 1, "receiver got one influence")
	check(r.received[0].kind == Influence.Kind.HAZARD, "receiver got HAZARD")

func test_send_ignores_non_receivers_and_null() -> void:
	var n := Node3D.new()
	world.add_child(n)
	check(not Influence.send(n, Influence.hazard(null)), "plain node is not a receiver")
	check(not Influence.send(null, Influence.hazard(null)), "null target is ignored")
