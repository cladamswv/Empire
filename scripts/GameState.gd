extends Node

signal state_changed
signal reports_changed
signal world_selected(city_id: int)

const GRID_W: int = 12
const GRID_H: int = 10

var city_name: String = "Nova Roma"
var civilization: String = "Rome"
var city_hall: int = 8
var population: int = 2600
var next_building_id: int = 1
var selected_world_city_id: int = 2

var resources: Dictionary = {
    "food": 9200,
    "wood": 7400,
    "stone": 5100,
    "metal": 2800,
    "coin": 4600,
}

var resources_per_hour: Dictionary = {
    "food": 860,
    "wood": 540,
    "stone": 280,
    "metal": 160,
    "coin": 220,
}

var buildings: Array[Dictionary] = []
var reports: Array[Dictionary] = []
var world_cities: Array[Dictionary] = []

func _ready() -> void:
    reset_demo("Rome")

func reset_demo(civ: String = "Rome") -> void:
    civilization = civ
    city_hall = 8
    population = 2600
    city_name = String({
        "Rome": "Nova Roma",
        "Egypt": "Akhet Delta",
        "Carthage": "Qart Aurelia",
        "Greece": "Helios Polis",
    }.get(civ, "Frontier Town"))
    resources = {
        "food": 9200,
        "wood": 7400,
        "stone": 5100,
        "metal": 2800,
        "coin": 4600,
    }
    resources_per_hour = {
        "food": 860,
        "wood": 540,
        "stone": 280,
        "metal": 160,
        "coin": 220,
    }
    reports.clear()
    buildings.clear()
    next_building_id = 1

    _spawn_building("city_hall", 5, 3, 3)
    _spawn_building("temple", 6, 7, 2)
    _spawn_building("market", 4, 6, 5)
    _spawn_building("barracks", 4, 8, 5)
    _spawn_building("house", 3, 4, 5)
    _spawn_building("house", 3, 4, 6)
    _spawn_building("house", 3, 5, 6)
    _spawn_building("house", 3, 6, 6)
    _spawn_building("farm", 2, 2, 7)
    _spawn_building("farm", 2, 2, 8)
    _spawn_building("farm", 2, 3, 8)
    _spawn_building("farm", 2, 3, 7)
    _spawn_building("sawmill", 2, 1, 4)
    _spawn_building("quarry", 2, 9, 1)
    _spawn_building("mine", 2, 10, 2)
    _spawn_building("wall_tower", 2, 3, 2)
    _spawn_building("wall_tower", 2, 8, 1)
    _spawn_building("wall_tower", 2, 9, 6)
    _spawn_building("wall_tower", 2, 4, 7)
    _spawn_building("gate", 2, 6, 7)
    _generate_world()
    add_report("Loaded %s mockup" % civilization, "This prototype focuses on clickable UI and a movable city mockup, not final graphics.")
    _emit_all()

func _generate_world() -> void:
    world_cities = [
        {"id": 1, "name": city_name, "civ": civilization, "owner": "You", "x": 220.0, "y": 210.0, "level": city_hall},
        {"id": 2, "name": "Thonis", "civ": "Egypt", "owner": "Nile Kingdom", "x": 480.0, "y": 170.0, "level": 7},
        {"id": 3, "name": "Byrsa", "civ": "Carthage", "owner": "Punic League", "x": 330.0, "y": 340.0, "level": 8},
        {"id": 4, "name": "Aurelia", "civ": "Rome", "owner": "Latin League", "x": 130.0, "y": 120.0, "level": 6},
        {"id": 5, "name": "Helikon", "civ": "Greece", "owner": "Aegean League", "x": 560.0, "y": 260.0, "level": 7},
        {"id": 6, "name": "Brennos", "civ": "Neutral", "owner": "Hill Tribes", "x": 610.0, "y": 110.0, "level": 4},
        {"id": 7, "name": "Sais Gate", "civ": "Egypt", "owner": "Nile Kingdom", "x": 390.0, "y": 95.0, "level": 5},
    ]

func _spawn_building(type: String, level: int, gx: int, gy: int) -> void:
    buildings.append({
        "id": next_building_id,
        "type": type,
        "level": level,
        "gx": gx,
        "gy": gy,
    })
    next_building_id += 1

func add_building(type: String) -> void:
    var slot: Vector2i = find_open_spot()
    if slot == Vector2i(-1, -1):
        add_report("City Full", "No free plot was found in the current mockup.")
        return
    _spawn_building(type, 1, slot.x, slot.y)
    add_report("Added %s" % get_building_display_name(type), "Placed a new %s on the city grid." % get_building_display_name(type).to_lower())
    _emit_all()

func move_building(building_id: int, gx: int, gy: int) -> void:
    gx = clamp(gx, 0, GRID_W - 1)
    gy = clamp(gy, 0, GRID_H - 1)
    var moving: Dictionary = get_building_by_id(building_id)
    if moving.is_empty():
        return
    var old_x: int = int(moving["gx"])
    var old_y: int = int(moving["gy"])
    for other: Dictionary in buildings:
        if int(other["id"]) != building_id and int(other["gx"]) == gx and int(other["gy"]) == gy:
            other["gx"] = old_x
            other["gy"] = old_y
            break
    moving["gx"] = gx
    moving["gy"] = gy
    add_report("Moved %s" % get_building_display_name(String(moving["type"])), "Relocated to plot (%d, %d)." % [gx, gy])
    _emit_all()

func find_open_spot() -> Vector2i:
    for gy in range(GRID_H):
        for gx in range(GRID_W):
            if not _is_occupied(gx, gy):
                return Vector2i(gx, gy)
    return Vector2i(-1, -1)

func _is_occupied(gx: int, gy: int) -> bool:
    for building in buildings:
        if int(building["gx"]) == gx and int(building["gy"]) == gy:
            return true
    return false

func set_civilization(civ: String) -> void:
    civilization = civ
    city_name = String({
        "Rome": "Nova Roma",
        "Egypt": "Akhet Delta",
        "Carthage": "Qart Aurelia",
        "Greece": "Helios Polis",
    }.get(civ, city_name))
    world_cities[0]["name"] = city_name
    world_cities[0]["civ"] = civilization
    add_report("Style switched" , "The city mockup now uses the %s visual style." % civilization)
    _emit_all()

func get_building_display_name(type: String) -> String:
    return String({
        "city_hall": "City Hall",
        "temple": "Temple",
        "market": "Market",
        "barracks": "Barracks",
        "house": "House",
        "farm": "Farm",
        "sawmill": "Sawmill",
        "quarry": "Quarry",
        "mine": "Mine",
        "wall_tower": "Tower",
        "gate": "Gate",
    }.get(type, type.capitalize()))

func get_building_by_id(building_id: int) -> Dictionary:
    for building in buildings:
        if int(building["id"]) == building_id:
            return building
    return {}

func select_world_city(city_id: int) -> void:
    selected_world_city_id = city_id
    world_selected.emit(city_id)
    state_changed.emit()

func get_selected_world_city() -> Dictionary:
    for city in world_cities:
        if int(city["id"]) == selected_world_city_id:
            return city
    return world_cities[0] if not world_cities.is_empty() else {}

func scout_selected_city() -> void:
    var city: Dictionary = get_selected_world_city()
    add_report("Scout report: %s" % city.get("name", "Unknown"), "%s is a Level %s %s city ruled by %s." % [city.get("name", "Unknown"), city.get("level", 1), city.get("civ", "Neutral"), city.get("owner", "Unknown")])
    reports_changed.emit()

func attack_selected_city() -> void:
    var city: Dictionary = get_selected_world_city()
    if int(city.get("id", 0)) == 1:
        add_report("Orders ignored", "This is your own capital.")
    else:
        add_report("Mock attack ordered", "General Cassian marches toward %s. In the prototype, this is just a stub interaction." % city.get("name", "Unknown"))
    reports_changed.emit()

func add_report(title: String, body: String) -> void:
    reports.push_front({"title": title, "body": body})
    while reports.size() > 16:
        reports.resize(16)
    reports_changed.emit()

func get_summary_text() -> String:
    return "%s  •  %s  •  City Hall Lv.%d  •  Pop %d" % [city_name, civilization, city_hall, population]

func get_resource_text() -> String:
    return "Food %d (+%d/h)   Wood %d (+%d/h)   Stone %d (+%d/h)   Metal %d (+%d/h)   Coin %d (+%d/h)" % [
        int(resources["food"]), int(resources_per_hour["food"]),
        int(resources["wood"]), int(resources_per_hour["wood"]),
        int(resources["stone"]), int(resources_per_hour["stone"]),
        int(resources["metal"]), int(resources_per_hour["metal"]),
        int(resources["coin"]), int(resources_per_hour["coin"]),
    ]

func _emit_all() -> void:
    state_changed.emit()
    reports_changed.emit()
