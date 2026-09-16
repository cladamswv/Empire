extends Control

signal city_clicked(city_id: int)

var hover_city_id: int = -1
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

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_button: InputEventMouseButton = event
        if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
            var hit: int = _pick_city(mouse_button.position)
            if hit != -1:
                GameState.select_world_city(hit)
                city_clicked.emit(hit)
                queue_redraw()
    elif event is InputEventMouseMotion:
        var motion: InputEventMouseMotion = event
        hover_city_id = _pick_city(motion.position)
        queue_redraw()

func _draw() -> void:
    _draw_map_background()
    _draw_seas()
    _draw_regions()
    _draw_rivers()
    _draw_forests()
    _draw_mountains()
    _draw_trade_routes()
    _draw_landmarks()
    for city: Dictionary in GameState.world_cities:
        _draw_city(city)
    _draw_compass()

func _draw_map_background() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("b6c88d"))
    for i: int in range(6):
        var shade: Color = Color(0.95, 0.87, 0.66, 0.035 + float(i) * 0.01)
        draw_circle(Vector2(size.x * (0.12 + float(i) * 0.15), size.y * (0.18 + float((i * 3) % 4) * 0.17)), 120.0 + float(i) * 22.0, shade)
    draw_rect(Rect2(0, 0, size.x, size.y), Color(0.08, 0.12, 0.08, 0.035))

func _draw_seas() -> void:
    var east_sea: PackedVector2Array = PackedVector2Array([
        Vector2(size.x * 0.72, 0), Vector2(size.x, 0), Vector2(size.x, size.y),
        Vector2(size.x * 0.86, size.y), Vector2(size.x * 0.82, size.y * 0.80),
        Vector2(size.x * 0.88, size.y * 0.63), Vector2(size.x * 0.80, size.y * 0.48),
        Vector2(size.x * 0.84, size.y * 0.30), Vector2(size.x * 0.76, size.y * 0.16)
    ])
    draw_colored_polygon(east_sea, Color("5d9ec2"))
    for i: int in range(10):
        var y: float = 20.0 + float(i) * size.y / 10.0
        draw_line(Vector2(size.x * 0.83, y), Vector2(size.x - 12.0, y + 8.0), Color(1,1,1,0.12), 2.0)

func _draw_regions() -> void:
    var regions: Array[Dictionary] = [
        {"c": Vector2(size.x * 0.20, size.y * 0.25), "r": 120.0, "color": Color("a5bd78")},
        {"c": Vector2(size.x * 0.46, size.y * 0.23), "r": 105.0, "color": Color("c6bd79")},
        {"c": Vector2(size.x * 0.56, size.y * 0.62), "r": 135.0, "color": Color("a7ba6f")},
        {"c": Vector2(size.x * 0.27, size.y * 0.68), "r": 130.0, "color": Color("bfc783")}
    ]
    for region: Dictionary in regions:
        draw_circle(region["c"], float(region["r"]), region["color"])
        draw_arc(region["c"], float(region["r"]), 0, TAU, 48, Color(0.25,0.31,0.17,0.12), 2.0)

func _draw_rivers() -> void:
    var river: PackedVector2Array = PackedVector2Array([
        Vector2(size.x * 0.02, size.y * 0.18), Vector2(size.x * 0.14, size.y * 0.24),
        Vector2(size.x * 0.24, size.y * 0.20), Vector2(size.x * 0.33, size.y * 0.31),
        Vector2(size.x * 0.43, size.y * 0.27), Vector2(size.x * 0.54, size.y * 0.41),
        Vector2(size.x * 0.67, size.y * 0.38), Vector2(size.x * 0.79, size.y * 0.49)
    ])
    draw_polyline(river, Color("508db4"), 15.0)
    draw_polyline(river, Color("8fc7df"), 7.0)

func _draw_forests() -> void:
    var forest_centers: Array[Vector2] = [
        Vector2(size.x * 0.12, size.y * 0.55), Vector2(size.x * 0.34, size.y * 0.48), Vector2(size.x * 0.60, size.y * 0.23), Vector2(size.x * 0.68, size.y * 0.68)
    ]
    for center: Vector2 in forest_centers:
        for i: int in range(11):
            var angle: float = float(i) * 2.399
            var radius: float = 8.0 + float((i * 13) % 38)
            var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
            _draw_map_tree(pos, 0.75 + float(i % 3) * 0.08)

func _draw_map_tree(pos: Vector2, scale_factor: float) -> void:
    draw_circle(pos, 5.5 * scale_factor, Color("426f3b"))
    draw_circle(pos + Vector2(0, -4) * scale_factor, 4.5 * scale_factor, Color("548848"))
    draw_line(pos + Vector2(0, 3), pos + Vector2(0, 8), Color("74543c"), 1.5)

func _draw_mountains() -> void:
    var mountain_centers: Array[Vector2] = [
        Vector2(size.x * 0.17, size.y * 0.12), Vector2(size.x * 0.22, size.y * 0.13), Vector2(size.x * 0.50, size.y * 0.82), Vector2(size.x * 0.55, size.y * 0.79), Vector2(size.x * 0.60, size.y * 0.80)
    ]
    for i: int in range(mountain_centers.size()):
        var c: Vector2 = mountain_centers[i]
        var height: float = 26.0 + float(i % 2) * 8.0
        var mountain: PackedVector2Array = PackedVector2Array([c + Vector2(-18, 13), c + Vector2(0, -height), c + Vector2(20, 13)])
        draw_colored_polygon(mountain, Color("778277"))
        var snow: PackedVector2Array = PackedVector2Array([c + Vector2(-6, -height + 10), c + Vector2(0, -height), c + Vector2(7, -height + 11)])
        draw_colored_polygon(snow, Color("e8ece9"))

func _draw_trade_routes() -> void:
    if GameState.world_cities.is_empty():
        return
    var player: Dictionary = GameState.world_cities[0]
    var start: Vector2 = _map_point(player)
    for city: Dictionary in GameState.world_cities:
        if int(city["id"]) == 1:
            continue
        draw_dashed_line(start, _map_point(city), Color(0.29, 0.22, 0.14, 0.38), 2.5, 9.0)

func _draw_landmarks() -> void:
    var lighthouse: Vector2 = Vector2(size.x * 0.77, size.y * 0.64)
    draw_rect(Rect2(lighthouse + Vector2(-5, -24), Vector2(10, 24)), Color("d9d1bb"))
    draw_colored_polygon(PackedVector2Array([lighthouse + Vector2(-8,-24), lighthouse + Vector2(0,-34), lighthouse + Vector2(8,-24)]), Color("b55a42"))
    draw_circle(lighthouse + Vector2(0,-35), 3.5, Color("f0c55e"))

    var ruins: Vector2 = Vector2(size.x * 0.42, size.y * 0.69)
    for i: int in range(3):
        draw_line(ruins + Vector2(float(i) * 10, 0), ruins + Vector2(float(i) * 10, -18 - float(i) * 3), Color("b9ad8e"), 4.0)
    draw_line(ruins + Vector2(-4,-18), ruins + Vector2(26,-23), Color("b9ad8e"), 4.0)

func _map_point(city: Dictionary) -> Vector2:
    return Vector2(float(city["x"]) / 720.0 * size.x * 0.78 + size.x * 0.03, float(city["y"]) / 420.0 * size.y * 0.88 + size.y * 0.05)

func _draw_city(city: Dictionary) -> void:
    var pos: Vector2 = _map_point(city)
    var civ: String = String(city["civ"])
    var banner_color: Color = _civ_color(civ)
    var selected: bool = int(city["id"]) == GameState.selected_world_city_id
    var hovered: bool = int(city["id"]) == hover_city_id
    var scale_factor: float = 0.82 + float(city.get("level", 1)) * 0.04

    draw_circle(pos + Vector2(4, 7), 16.0 * scale_factor, Color(0,0,0,0.14))
    var wall: PackedVector2Array = PackedVector2Array([
        pos + Vector2(-15,-2) * scale_factor, pos + Vector2(0,-12) * scale_factor,
        pos + Vector2(17,-2) * scale_factor, pos + Vector2(0,9) * scale_factor
    ])
    draw_colored_polygon(wall, Color("d2c5a8"))
    draw_polyline(_closed(wall), Color("786e5e"), 1.6)
    for tower_x: float in [-10.0, 10.0]:
        draw_rect(Rect2(pos + Vector2(tower_x - 4, -18) * scale_factor, Vector2(8, 14) * scale_factor), Color("c4b69a"))
        draw_rect(Rect2(pos + Vector2(tower_x - 5, -20) * scale_factor, Vector2(10, 4) * scale_factor), banner_color.darkened(0.15))
    draw_line(pos + Vector2(0,-11) * scale_factor, pos + Vector2(0,-29) * scale_factor, Color("5d4838"), 1.8)
    var wave: float = sin(anim_time * 2.4 + pos.x * 0.02) * 2.0
    var flag: PackedVector2Array = PackedVector2Array([
        pos + Vector2(0,-29) * scale_factor,
        pos + Vector2(14 + wave,-26) * scale_factor,
        pos + Vector2(11,-19) * scale_factor,
        pos + Vector2(0,-21) * scale_factor
    ])
    draw_colored_polygon(flag, banner_color)

    if selected or hovered:
        draw_arc(pos, 25.0 * scale_factor + 4.0, 0, TAU, 36, Color("f4cd68"), 3.0)
    if selected:
        draw_arc(pos, 31.0 * scale_factor + sin(anim_time * 3.0) * 2.0, 0, TAU, 36, Color(0.96,0.78,0.36,0.35), 2.0)

    var label_y: float = pos.y - 38.0 * scale_factor
    draw_string(get_theme_default_font(), Vector2(pos.x - 44, label_y), String(city["name"]), HORIZONTAL_ALIGNMENT_CENTER, 88, 13, Color("1a2026"))
    draw_string(get_theme_default_font(), Vector2(pos.x - 36, label_y + 14), "%s  Lv.%d" % [civ, int(city.get("level", 1))], HORIZONTAL_ALIGNMENT_CENTER, 72, 10, banner_color.darkened(0.28))

func _civ_color(civ: String) -> Color:
    match civ:
        "Rome": return Color("bd4a3d")
        "Egypt": return Color("c8a13f")
        "Carthage": return Color("7b3f60")
        "Greece": return Color("467eb8")
        _: return Color("6d756c")

func _draw_compass() -> void:
    var center: Vector2 = Vector2(44, 44)
    draw_circle(center, 24, Color(0.08,0.10,0.12,0.72))
    draw_arc(center, 24, 0, TAU, 32, Color("d7ad55"), 2.0)
    var north: PackedVector2Array = PackedVector2Array([center + Vector2(0,-18), center + Vector2(6,3), center + Vector2(0,0), center + Vector2(-6,3)])
    draw_colored_polygon(north, Color("d7ad55"))
    draw_string(get_theme_default_font(), center + Vector2(-5, 13), "N", HORIZONTAL_ALIGNMENT_LEFT, 12, 10, Color.WHITE)

func _pick_city(pos: Vector2) -> int:
    for city: Dictionary in GameState.world_cities:
        if _map_point(city).distance_to(pos) <= 30.0:
            return int(city["id"])
    return -1

func _closed(points: PackedVector2Array) -> PackedVector2Array:
    var result: PackedVector2Array = points.duplicate()
    if result.size() > 0:
        result.append(result[0])
    return result
