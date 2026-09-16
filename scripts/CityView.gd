extends Control

signal building_clicked(building_id: int)

const TILE_W: float = 74.0
const TILE_H: float = 38.0
const GRID_W: int = 12
const GRID_H: int = 10

var selected_building_id: int = -1
var drag_building_id: int = -1
var drag_screen_position: Vector2 = Vector2.ZERO
var hover_building_id: int = -1
var pan_offset: Vector2 = Vector2(-28, 2)
var anim_time: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    GameState.state_changed.connect(queue_redraw)
    set_process(true)

func _process(delta: float) -> void:
    anim_time += delta
    if anim_time > 1000.0:
        anim_time = 0.0
    queue_redraw()

func set_selected_building(building_id: int) -> void:
    selected_building_id = building_id
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_button: InputEventMouseButton = event
        if mouse_button.button_index == MOUSE_BUTTON_LEFT:
            if mouse_button.pressed:
                var hit: int = _pick_building(mouse_button.position)
                if hit != -1:
                    selected_building_id = hit
                    drag_building_id = hit
                    drag_screen_position = mouse_button.position
                    building_clicked.emit(hit)
                    queue_redraw()
            else:
                if drag_building_id != -1:
                    var grid: Vector2i = _screen_to_grid(mouse_button.position)
                    GameState.move_building(drag_building_id, grid.x, grid.y)
                    drag_building_id = -1
                    queue_redraw()
    elif event is InputEventMouseMotion:
        var motion: InputEventMouseMotion = event
        hover_building_id = _pick_building(motion.position)
        if drag_building_id != -1:
            drag_screen_position = motion.position
        queue_redraw()

func _draw() -> void:
    _draw_background()
    _draw_distant_landscape()
    _draw_island_shadow()
    _draw_tiles()
    _draw_roads()
    _draw_plaza()
    _draw_decorations()
    _draw_walls()
    _draw_buildings()
    _draw_people()
    _draw_foreground_frame()

func _draw_background() -> void:
    var sky_bands: Array[Color] = [
        Color("7eb7e8"), Color("8fc2eb"), Color("a5ceeb"), Color("bad9eb"), Color("d6e4e6")
    ]
    var band_h: float = max(1.0, size.y * 0.12)
    for i: int in range(sky_bands.size()):
        draw_rect(Rect2(0, float(i) * band_h, size.x, band_h + 2.0), sky_bands[i])
    draw_rect(Rect2(0, band_h * float(sky_bands.size()), size.x, size.y), Color("74a95c"))

    var sea_top: float = size.y * 0.12
    var sea_poly: PackedVector2Array = PackedVector2Array([
        Vector2(size.x * 0.62, sea_top), Vector2(size.x, sea_top), Vector2(size.x, size.y * 0.53),
        Vector2(size.x * 0.88, size.y * 0.46), Vector2(size.x * 0.78, size.y * 0.40), Vector2(size.x * 0.70, size.y * 0.32)
    ])
    draw_colored_polygon(sea_poly, Color("4f96c8"))
    for i: int in range(7):
        var y: float = sea_top + 25.0 + float(i) * 24.0
        draw_line(Vector2(size.x * 0.66 + float(i % 2) * 20.0, y), Vector2(size.x - 20.0, y + 5.0), Color(1, 1, 1, 0.16), 2.0)

func _draw_distant_landscape() -> void:
    var hill_color: Color = Color("648c56")
    var hill_dark: Color = Color("527648")
    var horizon_y: float = size.y * 0.34
    for i: int in range(9):
        var x: float = float(i) * size.x / 8.0
        var radius: float = 65.0 + float((i * 17) % 45)
        draw_circle(Vector2(x, horizon_y + float((i % 3) * 15)), radius, hill_color if i % 2 == 0 else hill_dark)
    draw_rect(Rect2(0, horizon_y + 32.0, size.x, size.y - horizon_y), Color("78ad60"))

    var mountain: PackedVector2Array = PackedVector2Array([
        Vector2(size.x * 0.04, horizon_y + 8), Vector2(size.x * 0.12, horizon_y - 100), Vector2(size.x * 0.20, horizon_y + 8),
        Vector2(size.x * 0.15, horizon_y + 8), Vector2(size.x * 0.25, horizon_y - 70), Vector2(size.x * 0.34, horizon_y + 8)
    ])
    draw_colored_polygon(mountain, Color("71816f"))

    for cloud_pos: Vector2 in [Vector2(120, 55), Vector2(420, 78), Vector2(size.x * 0.72, 55)]:
        _draw_cloud(cloud_pos)

func _draw_cloud(center: Vector2) -> void:
    draw_circle(center, 19, Color(1, 1, 1, 0.55))
    draw_circle(center + Vector2(18, 3), 15, Color(1, 1, 1, 0.48))
    draw_circle(center + Vector2(-18, 4), 14, Color(1, 1, 1, 0.48))
    draw_rect(Rect2(center + Vector2(-24, 5), Vector2(48, 13)), Color(1, 1, 1, 0.42))

func _draw_island_shadow() -> void:
    var origin: Vector2 = _origin()
    var poly: PackedVector2Array = PackedVector2Array([
        origin + Vector2(-260, 120), origin + Vector2(40, -35), origin + Vector2(370, 125),
        origin + Vector2(55, 300), origin + Vector2(-300, 160)
    ])
    draw_colored_polygon(poly, Color(0.13, 0.22, 0.12, 0.20))

func _origin() -> Vector2:
    return Vector2(size.x * 0.42, size.y * 0.12) + pan_offset

func _grid_to_screen(gx: int, gy: int) -> Vector2:
    var origin: Vector2 = _origin()
    return origin + Vector2((float(gx) - float(gy)) * TILE_W * 0.5, (float(gx) + float(gy)) * TILE_H * 0.5)

func _screen_to_grid(pos: Vector2) -> Vector2i:
    var local: Vector2 = pos - _origin()
    var gx: int = int(round((local.x / (TILE_W * 0.5) + local.y / (TILE_H * 0.5)) * 0.5))
    var gy: int = int(round((local.y / (TILE_H * 0.5) - local.x / (TILE_W * 0.5)) * 0.5))
    return Vector2i(clamp(gx, 0, GRID_W - 1), clamp(gy, 0, GRID_H - 1))

func _draw_tiles() -> void:
    for gy: int in range(GRID_H):
        for gx: int in range(GRID_W):
            var center: Vector2 = _grid_to_screen(gx, gy)
            var color: Color = Color("92c56e") if (gx + gy) % 2 == 0 else Color("88bb65")
            if gy >= 7 and gx <= 4:
                color = Color("a7bf6c")
            var diamond: PackedVector2Array = _diamond(center, TILE_W * 0.5, TILE_H * 0.5)
            draw_colored_polygon(diamond, color)
            draw_polyline(_closed(diamond), Color(0, 0, 0, 0.06), 1.0)

func _draw_roads() -> void:
    for gx: int in range(2, 10):
        _draw_road_tile(gx, 4)
    for gy: int in range(2, 8):
        _draw_road_tile(6, gy)
    for gx: int in range(4, 9):
        _draw_road_tile(gx, 6)

func _draw_road_tile(gx: int, gy: int) -> void:
    var center: Vector2 = _grid_to_screen(gx, gy)
    var diamond: PackedVector2Array = _diamond(center, TILE_W * 0.45, TILE_H * 0.42)
    draw_colored_polygon(diamond, Color("cdbf9c"))
    draw_polyline(_closed(diamond), Color(0.30, 0.26, 0.19, 0.18), 1.0)
    draw_circle(center + Vector2(-9, 1), 1.4, Color("9e9278"))
    draw_circle(center + Vector2(11, -2), 1.4, Color("9e9278"))

func _draw_plaza() -> void:
    var center: Vector2 = _grid_to_screen(6, 4)
    var plaza: PackedVector2Array = _diamond(center, 52, 27)
    draw_colored_polygon(plaza, Color("d8cdb2"))
    draw_polyline(_closed(plaza), Color("9f9278"), 2.0)
    draw_circle(center + Vector2(0, -9), 11, Color("76b7cf"))
    draw_circle(center + Vector2(0, -9), 6, Color("b7e5ef"))
    draw_line(center + Vector2(0, -18), center + Vector2(0, -34), Color("ded3bc"), 4.0)
    draw_circle(center + Vector2(0, -35), 4, Color("d7ad55"))

func _draw_decorations() -> void:
    var tree_spots: Array[Vector2i] = [
        Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 6), Vector2i(1, 9), Vector2i(10, 8), Vector2i(11, 8),
        Vector2i(10, 7), Vector2i(11, 5), Vector2i(2, 1), Vector2i(9, 8)
    ]
    for spot: Vector2i in tree_spots:
        _draw_tree(_grid_to_screen(spot.x, spot.y), 1.0)

    for gx: int in range(1, 5):
        var farm_center: Vector2 = _grid_to_screen(gx, 8)
        for row: int in range(3):
            draw_line(farm_center + Vector2(-24 + float(row) * 8.0, -5), farm_center + Vector2(-4 + float(row) * 8.0, 7), Color("dfc56f"), 2.0)

    var aqueduct_start: Vector2 = _grid_to_screen(10, 1) + Vector2(30, -24)
    for i: int in range(5):
        var base: Vector2 = aqueduct_start + Vector2(float(i) * 28.0, float(i) * 10.0)
        draw_line(base, base + Vector2(0, -35), Color("c8baa0"), 6.0)
        draw_line(base + Vector2(22, 8), base + Vector2(22, -27), Color("c8baa0"), 6.0)
        draw_arc(base + Vector2(11, -24), 11, PI, TAU, 16, Color("c8baa0"), 5.0)
        draw_line(base + Vector2(0, -35), base + Vector2(22, -27), Color("a99c86"), 4.0)

func _draw_tree(center: Vector2, scale_factor: float) -> void:
    draw_ellipse_shadow(center + Vector2(0, 2), Vector2(18, 7) * scale_factor, Color(0, 0, 0, 0.16))
    draw_line(center + Vector2(0, -3) * scale_factor, center + Vector2(0, -25) * scale_factor, Color("76533b"), 5.0 * scale_factor)
    draw_circle(center + Vector2(-7, -28) * scale_factor, 12.0 * scale_factor, Color("4f8e45"))
    draw_circle(center + Vector2(7, -29) * scale_factor, 13.0 * scale_factor, Color("5fa052"))
    draw_circle(center + Vector2(0, -39) * scale_factor, 12.0 * scale_factor, Color("68ad57"))

func draw_ellipse_shadow(center: Vector2, radii: Vector2, color: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    var steps: int = 18
    for i: int in range(steps):
        var angle: float = TAU * float(i) / float(steps)
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)

func _draw_walls() -> void:
    var wall_path: Array[Vector2i] = [
        Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2),
        Vector2i(9, 3), Vector2i(9, 4), Vector2i(9, 5), Vector2i(8, 6), Vector2i(7, 7), Vector2i(6, 7),
        Vector2i(5, 7), Vector2i(4, 7), Vector2i(3, 6), Vector2i(3, 5), Vector2i(3, 4), Vector2i(3, 3)
    ]
    for p: Vector2i in wall_path:
        var center: Vector2 = _grid_to_screen(p.x, p.y)
        var wall_top: PackedVector2Array = _diamond(center + Vector2(0, -15), 22, 9)
        draw_colored_polygon(wall_top, Color("d3c7ad"))
        draw_line(center + Vector2(-22, -15), center + Vector2(-22, 1), Color("a69983"), 3.0)
        draw_line(center + Vector2(22, -15), center + Vector2(22, 1), Color("8e836f"), 3.0)
        for notch: int in range(-2, 3):
            draw_rect(Rect2(center + Vector2(float(notch) * 8.0 - 2.0, -24), Vector2(5, 5)), Color("c5b89d"))

func _sorted_buildings() -> Array[Dictionary]:
    var sorted: Array[Dictionary] = []
    for building: Dictionary in GameState.buildings:
        sorted.append(building)
    sorted.sort_custom(_building_sort)
    return sorted

func _building_sort(a: Dictionary, b: Dictionary) -> bool:
    return int(a["gx"]) + int(a["gy"]) < int(b["gx"]) + int(b["gy"])

func _draw_buildings() -> void:
    for building: Dictionary in _sorted_buildings():
        var center: Vector2 = _grid_to_screen(int(building["gx"]), int(building["gy"]))
        if int(building["id"]) == drag_building_id:
            center = drag_screen_position
        _draw_building(building, center)

func _palette() -> Dictionary:
    match GameState.civilization:
        "Egypt":
            return {"wall": Color("e0c889"), "roof": Color("c98442"), "trim": Color("6f5231"), "accent": Color("2f9ca0"), "banner": Color("258a8b")}
        "Carthage":
            return {"wall": Color("dccab6"), "roof": Color("8c405c"), "trim": Color("583443"), "accent": Color("d2a64b"), "banner": Color("71324f")}
        "Greece":
            return {"wall": Color("ece9df"), "roof": Color("4d8fc5"), "trim": Color("546b7c"), "accent": Color("d7b657"), "banner": Color("377eb7")}
        _:
            return {"wall": Color("d9cbb3"), "roof": Color("ba6848"), "trim": Color("704c36"), "accent": Color("d3a94e"), "banner": Color("b33d36")}

func _draw_building(building: Dictionary, center: Vector2) -> void:
    var btype: String = String(building["type"])
    if btype == "farm":
        _draw_farm(center, building)
        return
    if btype == "quarry":
        _draw_quarry(center)
        return

    var palette: Dictionary = _palette()
    var wall: Color = palette["wall"]
    var roof: Color = palette["roof"]
    var trim: Color = palette["trim"]
    var accent: Color = palette["accent"]
    var banner: Color = palette["banner"]

    var width: float = 27.0
    var depth: float = 17.0
    var height: float = 25.0
    match btype:
        "city_hall":
            width = 45; depth = 28; height = 46
        "temple":
            width = 49; depth = 25; height = 34
        "market":
            width = 38; depth = 22; height = 22
        "barracks":
            width = 40; depth = 24; height = 27
        "house":
            width = 25; depth = 17; height = 23
        "sawmill":
            width = 33; depth = 21; height = 18
        "mine":
            width = 34; depth = 21; height = 18
        "wall_tower":
            width = 21; depth = 21; height = 37
        "gate":
            width = 44; depth = 21; height = 29

    draw_ellipse_shadow(center + Vector2(4, 3), Vector2(width * 1.1, depth * 0.6), Color(0, 0, 0, 0.18))

    var roof_top: PackedVector2Array = PackedVector2Array([
        center + Vector2(0, -height - depth), center + Vector2(width, -height - depth * 0.5),
        center + Vector2(0, -height), center + Vector2(-width, -height - depth * 0.5)
    ])
    var left_face: PackedVector2Array = PackedVector2Array([
        center + Vector2(-width, -height - depth * 0.5), center + Vector2(0, -height),
        center + Vector2(0, 0), center + Vector2(-width, -depth * 0.5)
    ])
    var right_face: PackedVector2Array = PackedVector2Array([
        center + Vector2(0, -height), center + Vector2(width, -height - depth * 0.5),
        center + Vector2(width, -depth * 0.5), center + Vector2(0, 0)
    ])

    draw_colored_polygon(left_face, wall.darkened(0.08))
    draw_colored_polygon(right_face, wall)
    draw_colored_polygon(roof_top, roof if btype != "temple" else accent)
    draw_polyline(_closed(roof_top), trim, 1.8)
    draw_polyline(_closed(left_face), trim.darkened(0.1), 1.3)
    draw_polyline(_closed(right_face), trim.darkened(0.1), 1.3)

    _draw_building_details(btype, center, width, height, wall, roof, trim, accent, banner, int(building["id"]))
    _draw_smoke_if_needed(btype, center, height)

    if int(building["id"]) == selected_building_id or int(building["id"]) == hover_building_id:
        var outline: PackedVector2Array = PackedVector2Array([
            center + Vector2(0, -height - depth - 8), center + Vector2(width + 8, -height - depth * 0.5),
            center + Vector2(0, 8), center + Vector2(-width - 8, -depth * 0.5)
        ])
        draw_polyline(_closed(outline), Color("ffd76b"), 3.0)
        var label: String = "%s  Lv.%d" % [GameState.get_building_display_name(btype), int(building["level"])]
        draw_string(get_theme_default_font(), center + Vector2(-48, -height - depth - 17), label, HORIZONTAL_ALIGNMENT_CENTER, 96, 13, Color("17202a"))

func _draw_building_details(btype: String, center: Vector2, width: float, height: float, wall: Color, roof: Color, trim: Color, accent: Color, banner: Color, building_id: int) -> void:
    if btype == "city_hall":
        draw_rect(Rect2(center + Vector2(-8, -24), Vector2(16, 24)), trim.darkened(0.1))
        draw_rect(Rect2(center + Vector2(-5, -21), Vector2(10, 21)), Color("6a4432"))
        for side: int in [-1, 1]:
            draw_line(center + Vector2(float(side) * 20, -30), center + Vector2(float(side) * 20, -57), trim, 2.0)
            _draw_flag(center + Vector2(float(side) * 20, -58), banner, side)
        for col: int in range(-2, 3):
            draw_line(center + Vector2(float(col) * 9, -6), center + Vector2(float(col) * 9, -30), Color(1,1,1,0.45), 2.4)
    elif btype == "temple":
        var pediment: PackedVector2Array = PackedVector2Array([
            center + Vector2(-37, -height - 7), center + Vector2(0, -height - 29), center + Vector2(37, -height - 7)
        ])
        draw_colored_polygon(pediment, accent.lightened(0.15))
        draw_polyline(_closed(pediment), trim, 1.5)
        for col: int in range(-3, 4):
            draw_line(center + Vector2(float(col) * 10, -3), center + Vector2(float(col) * 10, -27), wall.lightened(0.18), 3.0)
    elif btype == "market":
        for i: int in range(-2, 3):
            var awning_color: Color = Color("efc95f") if i % 2 == 0 else banner
            draw_rect(Rect2(center + Vector2(float(i) * 12 - 5, -15), Vector2(10, 7)), awning_color)
        draw_circle(center + Vector2(20, -7), 3, Color("ca8748"))
        draw_circle(center + Vector2(12, -4), 3, Color("7cae52"))
    elif btype == "barracks":
        draw_rect(Rect2(center + Vector2(-7, -19), Vector2(14, 19)), trim.darkened(0.05))
        _draw_shield(center + Vector2(19, -15), banner)
        _draw_shield(center + Vector2(-19, -18), banner)
    elif btype == "house":
        var door_x: float = -4.0 if building_id % 2 == 0 else 5.0
        draw_rect(Rect2(center + Vector2(door_x - 4, -14), Vector2(8, 14)), Color("73513d"))
        draw_rect(Rect2(center + Vector2(-17, -17), Vector2(6, 6)), Color("6da4bd"))
        draw_rect(Rect2(center + Vector2(11, -13), Vector2(6, 6)), Color("6da4bd"))
    elif btype == "sawmill":
        for i: int in range(4):
            draw_line(center + Vector2(-22 + float(i) * 6, 2), center + Vector2(-5 + float(i) * 6, 10), Color("8b5c37"), 4.0)
        draw_arc(center + Vector2(18, -6), 10, 0, TAU, 20, Color("d5d7d9"), 3.0)
    elif btype == "mine":
        draw_arc(center + Vector2(0, -4), 13, PI, TAU, 18, Color("665244"), 7.0)
        draw_rect(Rect2(center + Vector2(-10, -4), Vector2(20, 12)), Color("3b3430"))
        draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), trim, 2.0)
    elif btype == "wall_tower":
        for notch: int in range(-2, 3):
            draw_rect(Rect2(center + Vector2(float(notch) * 7 - 2, -height - 11), Vector2(5, 6)), wall.lightened(0.1))
        _draw_flag(center + Vector2(0, -height - 22), banner, 1)
    elif btype == "gate":
        draw_arc(center + Vector2(0, 0), 13, PI, TAU, 18, Color("6c4937"), 7.0)
        draw_rect(Rect2(center + Vector2(-10, -1), Vector2(20, 15)), Color("5b4032"))
        _draw_flag(center + Vector2(0, -height - 16), banner, 1)

func _draw_smoke_if_needed(btype: String, center: Vector2, height: float) -> void:
    if btype not in ["house", "sawmill", "barracks"]:
        return
    var phase: float = fmod(anim_time * 15.0 + center.x * 0.03, 20.0)
    for i: int in range(3):
        var rise: float = phase + float(i) * 8.0
        draw_circle(center + Vector2(11 + sin(anim_time + float(i)) * 2.0, -height - 18 - rise), 4.0 + float(i), Color(0.86, 0.88, 0.89, 0.16))

func _draw_flag(anchor: Vector2, color: Color, direction: int) -> void:
    var wave: float = sin(anim_time * 2.4 + anchor.x * 0.02) * 2.0
    draw_line(anchor + Vector2(0, 8), anchor + Vector2(0, -7), Color("594436"), 2.0)
    var flag: PackedVector2Array = PackedVector2Array([
        anchor + Vector2(0, -7), anchor + Vector2(float(direction) * (17 + wave), -4), anchor + Vector2(float(direction) * 13, 4), anchor + Vector2(0, 2)
    ])
    draw_colored_polygon(flag, color)

func _draw_shield(center: Vector2, color: Color) -> void:
    var shield: PackedVector2Array = PackedVector2Array([
        center + Vector2(-5, -7), center + Vector2(5, -7), center + Vector2(6, 1), center + Vector2(0, 7), center + Vector2(-6, 1)
    ])
    draw_colored_polygon(shield, color)
    draw_polyline(_closed(shield), Color("f2d58c"), 1.2)

func _draw_farm(center: Vector2, building: Dictionary) -> void:
    var farm: PackedVector2Array = _diamond(center, 31, 16)
    draw_colored_polygon(farm, Color("d4b75e"))
    draw_polyline(_closed(farm), Color("9e8339"), 1.0)
    for i: int in range(-3, 4):
        draw_line(center + Vector2(float(i) * 7 - 9, -8), center + Vector2(float(i) * 7 + 9, 8), Color("f0d876"), 1.8)
    draw_rect(Rect2(center + Vector2(17, -16), Vector2(11, 11)), Color("d8c59c"))
    var roof: PackedVector2Array = PackedVector2Array([
        center + Vector2(15, -16), center + Vector2(23, -24), center + Vector2(31, -16)
    ])
    draw_colored_polygon(roof, _palette()["roof"])
    if int(building["id"]) == selected_building_id or int(building["id"]) == hover_building_id:
        draw_polyline(_closed(farm), Color("ffd76b"), 3.0)

func _draw_quarry(center: Vector2) -> void:
    draw_ellipse_shadow(center + Vector2(0, 4), Vector2(28, 9), Color(0,0,0,0.15))
    draw_circle(center + Vector2(-12, -8), 11, Color("9ea4a8"))
    draw_circle(center + Vector2(5, -15), 14, Color("b7bdc0"))
    draw_circle(center + Vector2(18, -3), 11, Color("8b9397"))
    draw_line(center + Vector2(-22, 5), center + Vector2(23, 5), Color("7d6c5d"), 5.0)
    draw_line(center + Vector2(-5, -4), center + Vector2(11, 8), Color("8a5e3a"), 3.0)

func _draw_people() -> void:
    var people: Array[Vector2i] = [
        Vector2i(6, 4), Vector2i(5, 4), Vector2i(7, 4), Vector2i(6, 5), Vector2i(7, 5), Vector2i(5, 5), Vector2i(8, 4)
    ]
    for i: int in range(people.size()):
        var base: Vector2 = _grid_to_screen(people[i].x, people[i].y) + Vector2(-14 + float((i * 11) % 27), 2 + float((i * 7) % 8))
        var bob: float = sin(anim_time * 2.0 + float(i)) * 1.0
        draw_circle(base + Vector2(0, -9 + bob), 2.6, Color("d8a67b"))
        draw_line(base + Vector2(0, -6 + bob), base + Vector2(0, 1 + bob), Color("6e4e3b") if i % 2 == 0 else Color("b33d36"), 3.0)
        draw_line(base + Vector2(-3, -3 + bob), base + Vector2(3, -3 + bob), Color("5d463a"), 1.5)

func _draw_foreground_frame() -> void:
    draw_rect(Rect2(0, 0, size.x, 4), Color(0, 0, 0, 0.10))
    draw_rect(Rect2(0, size.y - 4, size.x, 4), Color(0, 0, 0, 0.14))

func _pick_building(pos: Vector2) -> int:
    var reversed: Array[Dictionary] = _sorted_buildings()
    reversed.reverse()
    for building: Dictionary in reversed:
        var center: Vector2 = _grid_to_screen(int(building["gx"]), int(building["gy"]))
        var pick_rect: Rect2 = Rect2(center + Vector2(-42, -82), Vector2(84, 86))
        if pick_rect.has_point(pos):
            return int(building["id"])
    return -1

func _diamond(center: Vector2, half_w: float, half_h: float) -> PackedVector2Array:
    return PackedVector2Array([
        center + Vector2(0, -half_h), center + Vector2(half_w, 0), center + Vector2(0, half_h), center + Vector2(-half_w, 0)
    ])

func _closed(points: PackedVector2Array) -> PackedVector2Array:
    var result: PackedVector2Array = points.duplicate()
    if result.size() > 0:
        result.append(result[0])
    return result
