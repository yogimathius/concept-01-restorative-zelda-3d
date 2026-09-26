extends TestCase
## Parsing the Region 1 grids (world design §4) into cells.

func test_parses_all_five_areas() -> void:
	var level := GridLevel.load_file("res://levels/region1.txt")
	check(level.areas.size() == 5, "five areas (got %d)" % level.areas.size())
	for area in level.areas:
		check(area.rows.size() == 12, "%s has 12 rows" % area.id)
		for row in area.rows:
			check(row.length() == 16, "%s rows are 16 wide" % area.id)

func test_world_cell_coordinates_follow_area_origins() -> void:
	var level := GridLevel.load_file("res://levels/region1.txt")
	# S2 B1 is at column 8, row 6 of an area whose origin is (16, 0)
	var b := level.find("B")
	check(b.size() == 3, "three Bearers (got %d)" % b.size())
	check(Vector2i(23, 5) in b.map(func(c): return c.cell), "B1 at world cell (23,5) = S2 (8,6)")
	check(level.char_at(Vector2i(23, 5)) == "B", "char lookup by world cell")
	check(level.find("C").size() == 3, "three Chargers")
	check(level.find("G").size() == 5, "five gate cells")
	check(level.find("K").size() == 2, "two conduits")
	check(level.find("P").size() == 1, "one spawn")

func test_area_defaults_and_empty_space() -> void:
	var level := GridLevel.load_file("res://levels/region1.txt")
	check(level.area_at(Vector2i(2, 2)).default_state == "restored", "S1 starts restored")
	check(level.area_at(Vector2i(20, 2)).default_state == "corrupted", "S2 starts corrupted")
	check(level.char_at(Vector2i(0, 20)) == "", "outside every area is empty")
