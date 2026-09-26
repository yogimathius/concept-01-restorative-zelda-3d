class_name GridLevel
extends RefCounted
## Parses the world designer's ASCII region format (world design §4):
##   area <id> origin=<x>,<z> default=<corrupted|restored>
##   <12 rows of 16 chars, row 1 = north>
##   end
## World cells are 0-based: cell = origin + (col - 1, row - 1); a tile's
## centre in world space is cell + 0.5.

class Area:
	var id: String
	var origin: Vector2i
	var default_state := "corrupted"
	var rows: PackedStringArray = PackedStringArray()

	func contains(cell: Vector2i) -> bool:
		var local := cell - origin
		return local.x >= 0 and local.y >= 0 and local.y < rows.size() and local.x < rows[local.y].length()

	func char_at(cell: Vector2i) -> String:
		var local := cell - origin
		return rows[local.y][local.x]

class Cell:
	var cell: Vector2i
	var ch: String
	var area: Area

var areas: Array[Area] = []

static func load_file(path: String) -> GridLevel:
	var level := GridLevel.new()
	var text := FileAccess.get_file_as_string(path)
	var current: Area = null
	for raw in text.split("\n"):
		var line := raw.strip_edges(false, true)
		if line.begins_with("#") and current == null:
			continue  # comment (walls only appear inside an area block)
		if line.begins_with("area "):
			current = Area.new()
			for part in line.split(" ", false):
				if part.begins_with("origin="):
					var xy := part.trim_prefix("origin=").split(",")
					current.origin = Vector2i(int(xy[0]), int(xy[1]))
				elif part.begins_with("default="):
					current.default_state = part.trim_prefix("default=")
				elif part != "area":
					current.id = part
		elif line == "end":
			level.areas.append(current)
			current = null
		elif current != null and line.length() > 0:
			current.rows.append(line)
	return level

func area_at(cell: Vector2i) -> Area:
	for a in areas:
		if a.contains(cell):
			return a
	return null

func char_at(cell: Vector2i) -> String:
	var a := area_at(cell)
	return a.char_at(cell) if a else ""

func cells() -> Array[Cell]:
	var out: Array[Cell] = []
	for a in areas:
		for r in a.rows.size():
			for c in a.rows[r].length():
				var cell := Cell.new()
				cell.cell = a.origin + Vector2i(c, r)
				cell.ch = a.rows[r][c]
				cell.area = a
				out.append(cell)
	return out

func find(ch: String) -> Array[Cell]:
	return cells().filter(func(c: Cell) -> bool: return c.ch == ch)
