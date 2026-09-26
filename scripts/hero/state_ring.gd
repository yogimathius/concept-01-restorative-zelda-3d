class_name StateRing
extends MeshInstance3D
## Flat ring under the hero's feet: stony for Weight, cyan for Charge. Hidden
## at rest, it brightens and grows with the dominant state and flickers near
## overload. States are read from the body, not from HUD numbers.

const WEIGHT_COLOR := Color(0.62, 0.55, 0.45)
const CHARGE_COLOR := Color(0.3, 0.95, 1.0)
const WARN_AT := 0.8

@export var gauge_path: NodePath = ^"../StateGauge"

var _gauge: StateGauge
var _mat := StandardMaterial3D.new()
var _time := 0.0

func _ready() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.55
	mesh = torus
	position.y = 0.03
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = _mat
	_gauge = get_node(gauge_path)
	visible = false

func current_color() -> Color:
	return _mat.albedo_color

func _process(delta: float) -> void:
	_time += delta
	var w := _gauge.normalized(&"weight")
	var c := _gauge.normalized(&"charge")
	var level := maxf(w, c)
	visible = level > 0.02
	var color := WEIGHT_COLOR if w >= c else CHARGE_COLOR
	color.a = 0.6 + 0.4 * absf(sin(_time * 18.0)) if level >= WARN_AT else level
	_mat.albedo_color = color
	var s := 1.0 + level * 0.35
	scale = Vector3(s, 0.15, s)
