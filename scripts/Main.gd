extends Control

const C_BG: Color = Color("10151d")
const C_PANEL: Color = Color("19212d")
const C_PANEL_2: Color = Color("222c3a")
const C_GOLD: Color = Color("d7ad55")
const C_TEXT: Color = Color("edf1f5")
const C_MUTED: Color = Color("aeb8c5")
const C_GREEN: Color = Color("79c78a")

var current_view: String = "city"
var message_text: String = ""
var selected_building_id: int = -1

var top_bar: Panel
var title_label: Label
var subtitle_label: Label
var accent_line: ColorRect
var resource_cards: Array[Panel] = []
var resource_value_labels: Array[Label] = []
var resource_rate_labels: Array[Label] = []
var nav_city: Button
var nav_world: Button
var nav_reports: Button

var city_view: Control
var world_view: Control
var reports_frame: Panel
var reports_title: Label
var reports_box: RichTextLabel

var side_panel: Panel
var side_title: Label
var side_kicker: Label
var side_text: RichTextLabel
var scout_button: Button
var attack_button: Button

var bottom_bar: Panel
var build_label: Label
var culture_label: Label
var action_buttons: Array[Button] = []
var culture_buttons: Array[Button] = []
var status_label: Label

func _ready() -> void:
    set_process_input(true)
    _build_ui()
    GameState.state_changed.connect(_refresh_all)
    GameState.reports_changed.connect(_refresh_reports)
    _switch_view("city")
    _refresh_all()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and is_instance_valid(top_bar):
        _layout_ui()

func _build_ui() -> void:
    top_bar = Panel.new()
    top_bar.add_theme_stylebox_override("panel", _panel_style(C_BG, 0, Color.TRANSPARENT, 0))
    add_child(top_bar)

    title_label = Label.new()
    title_label.text = "EMPIRES RISE"
    title_label.add_theme_font_size_override("font_size", 27)
    title_label.add_theme_color_override("font_color", C_GOLD)
    top_bar.add_child(title_label)

    subtitle_label = Label.new()
    subtitle_label.add_theme_font_size_override("font_size", 13)
    subtitle_label.add_theme_color_override("font_color", C_MUTED)
    top_bar.add_child(subtitle_label)

    accent_line = ColorRect.new()
    accent_line.color = C_GOLD.darkened(0.2)
    top_bar.add_child(accent_line)

    var resource_names: Array[String] = ["FOOD", "WOOD", "STONE", "METAL", "COIN"]
    for resource_name: String in resource_names:
        var card: Panel = Panel.new()
        card.add_theme_stylebox_override("panel", _panel_style(C_PANEL, 10, Color("2e3948"), 1))
        top_bar.add_child(card)
        resource_cards.append(card)

        var name_label: Label = Label.new()
        name_label.text = resource_name
        name_label.add_theme_font_size_override("font_size", 10)
        name_label.add_theme_color_override("font_color", C_MUTED)
        name_label.position = Vector2(10, 5)
        name_label.size = Vector2(95, 14)
        card.add_child(name_label)

        var value_label: Label = Label.new()
        value_label.add_theme_font_size_override("font_size", 16)
        value_label.add_theme_color_override("font_color", C_TEXT)
        value_label.position = Vector2(10, 18)
        value_label.size = Vector2(72, 24)
        card.add_child(value_label)
        resource_value_labels.append(value_label)

        var rate_label: Label = Label.new()
        rate_label.add_theme_font_size_override("font_size", 10)
        rate_label.add_theme_color_override("font_color", C_GREEN)
        rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        rate_label.position = Vector2(64, 24)
        rate_label.size = Vector2(42, 16)
        card.add_child(rate_label)
        resource_rate_labels.append(rate_label)

    nav_city = _make_nav_button("CITY")
    nav_city.pressed.connect(_switch_view.bind("city"))
    nav_world = _make_nav_button("WORLD")
    nav_world.pressed.connect(_switch_view.bind("world"))
    nav_reports = _make_nav_button("REPORTS")
    nav_reports.pressed.connect(_switch_view.bind("reports"))
    top_bar.add_child(nav_city)
    top_bar.add_child(nav_world)
    top_bar.add_child(nav_reports)

    city_view = preload("res://scripts/CityView.gd").new()
    city_view.building_clicked.connect(_on_building_clicked)
    add_child(city_view)

    world_view = preload("res://scripts/WorldView.gd").new()
    world_view.city_clicked.connect(_on_world_city_clicked)
    add_child(world_view)

    reports_frame = Panel.new()
    reports_frame.add_theme_stylebox_override("panel", _panel_style(Color("141b25"), 14, Color("354153"), 1))
    add_child(reports_frame)

    reports_title = Label.new()
    reports_title.text = "CHRONICLE"
    reports_title.add_theme_font_size_override("font_size", 22)
    reports_title.add_theme_color_override("font_color", C_GOLD)
    reports_frame.add_child(reports_title)

    reports_box = RichTextLabel.new()
    reports_box.fit_content = false
    reports_box.scroll_active = true
    reports_box.bbcode_enabled = true
    reports_box.add_theme_font_size_override("normal_font_size", 15)
    reports_box.add_theme_color_override("default_color", C_TEXT)
    reports_frame.add_child(reports_box)

    side_panel = Panel.new()
    side_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.075, 0.10, 0.14, 0.94), 16, Color("3b485c"), 1, 10))
    add_child(side_panel)

    side_kicker = Label.new()
    side_kicker.add_theme_font_size_override("font_size", 11)
    side_kicker.add_theme_color_override("font_color", C_GOLD)
    side_panel.add_child(side_kicker)

    side_title = Label.new()
    side_title.add_theme_font_size_override("font_size", 23)
    side_title.add_theme_color_override("font_color", C_TEXT)
    side_panel.add_child(side_title)

    side_text = RichTextLabel.new()
    side_text.fit_content = false
    side_text.scroll_active = true
    side_text.bbcode_enabled = true
    side_text.add_theme_font_size_override("normal_font_size", 14)
    side_text.add_theme_color_override("default_color", C_MUTED)
    side_panel.add_child(side_text)

    scout_button = _make_action_button("SCOUT", C_GOLD)
    scout_button.pressed.connect(GameState.scout_selected_city)
    attack_button = _make_action_button("ATTACK", Color("c95b55"))
    attack_button.pressed.connect(GameState.attack_selected_city)
    side_panel.add_child(scout_button)
    side_panel.add_child(attack_button)

    bottom_bar = Panel.new()
    bottom_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.08, 0.11, 0.96), 0, Color("303a49"), 1))
    add_child(bottom_bar)

    build_label = Label.new()
    build_label.text = "BUILD"
    build_label.add_theme_font_size_override("font_size", 10)
    build_label.add_theme_color_override("font_color", C_GOLD)
    bottom_bar.add_child(build_label)

    culture_label = Label.new()
    culture_label.text = "CITY STYLE"
    culture_label.add_theme_font_size_override("font_size", 10)
    culture_label.add_theme_color_override("font_color", C_GOLD)
    bottom_bar.add_child(culture_label)

    var build_defs: Array = [
        ["HOUSE", "house"], ["FARM", "farm"], ["MARKET", "market"],
        ["BARRACKS", "barracks"], ["TEMPLE", "temple"], ["TOWER", "wall_tower"]
    ]
    for definition: Array in build_defs:
        var build_button: Button = _make_dock_button(String(definition[0]))
        build_button.pressed.connect(_on_add_building.bind(String(definition[1])))
        bottom_bar.add_child(build_button)
        action_buttons.append(build_button)

    for civ: String in ["Rome", "Egypt", "Carthage", "Greece"]:
        var culture_button: Button = _make_dock_button(civ.to_upper())
        culture_button.pressed.connect(_on_switch_civ.bind(civ))
        bottom_bar.add_child(culture_button)
        culture_buttons.append(culture_button)

    var reset_button: Button = _make_dock_button("RESET")
    reset_button.pressed.connect(_on_reset_demo)
    bottom_bar.add_child(reset_button)
    action_buttons.append(reset_button)

    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 12)
    status_label.add_theme_color_override("font_color", C_MUTED)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bottom_bar.add_child(status_label)

    _layout_ui()

func _layout_ui() -> void:
    var top_h: float = 76.0
    var bottom_h: float = 96.0
    var side_w: float = min(284.0, size.x * 0.26)

    top_bar.position = Vector2.ZERO
    top_bar.size = Vector2(size.x, top_h)
    accent_line.position = Vector2(0, top_h - 2)
    accent_line.size = Vector2(size.x, 2)

    title_label.position = Vector2(18, 7)
    title_label.size = Vector2(240, 32)
    subtitle_label.position = Vector2(20, 40)
    subtitle_label.size = Vector2(260, 22)

    var card_w: float = 106.0
    var card_gap: float = 7.0
    var card_start: float = 286.0
    for i: int in range(resource_cards.size()):
        resource_cards[i].position = Vector2(card_start + float(i) * (card_w + card_gap), 11)
        resource_cards[i].size = Vector2(card_w, 52)

    var nav_w: float = 84.0
    nav_reports.position = Vector2(size.x - nav_w - 14, 17)
    nav_reports.size = Vector2(nav_w, 42)
    nav_world.position = Vector2(size.x - nav_w * 2.0 - 22, 17)
    nav_world.size = Vector2(nav_w, 42)
    nav_city.position = Vector2(size.x - nav_w * 3.0 - 30, 17)
    nav_city.size = Vector2(nav_w, 42)

    var content_rect: Rect2 = Rect2(0, top_h, size.x, max(120.0, size.y - top_h - bottom_h))
    city_view.position = content_rect.position
    city_view.size = content_rect.size
    world_view.position = content_rect.position
    world_view.size = content_rect.size

    reports_frame.position = content_rect.position + Vector2(18, 18)
    reports_frame.size = content_rect.size - Vector2(36, 36)
    reports_title.position = Vector2(20, 14)
    reports_title.size = Vector2(reports_frame.size.x - 40, 30)
    reports_box.position = Vector2(20, 54)
    reports_box.size = Vector2(reports_frame.size.x - 40, reports_frame.size.y - 72)

    side_panel.position = Vector2(size.x - side_w - 16, top_h + 16)
    side_panel.size = Vector2(side_w, max(220.0, content_rect.size.y - 32))
    side_kicker.position = Vector2(18, 16)
    side_kicker.size = Vector2(side_w - 36, 16)
    side_title.position = Vector2(18, 34)
    side_title.size = Vector2(side_w - 36, 34)
    side_text.position = Vector2(18, 78)
    side_text.size = Vector2(side_w - 36, side_panel.size.y - 150)
    scout_button.position = Vector2(18, side_panel.size.y - 58)
    scout_button.size = Vector2((side_w - 46) * 0.5, 40)
    attack_button.position = Vector2(28 + scout_button.size.x, side_panel.size.y - 58)
    attack_button.size = scout_button.size

    bottom_bar.position = Vector2(0, size.y - bottom_h)
    bottom_bar.size = Vector2(size.x, bottom_h)
    build_label.position = Vector2(16, 8)
    build_label.size = Vector2(70, 14)
    culture_label.position = Vector2(size.x - 410, 8)
    culture_label.size = Vector2(100, 14)

    var x: float = 16.0
    for i: int in range(action_buttons.size()):
        var button: Button = action_buttons[i]
        if i == action_buttons.size() - 1:
            button.position = Vector2(size.x - 86, 28)
            button.size = Vector2(70, 38)
        else:
            button.position = Vector2(x, 28)
            button.size = Vector2(82, 38)
            x += 88.0

    var culture_start: float = size.x - 402.0
    for i: int in range(culture_buttons.size()):
        culture_buttons[i].position = Vector2(culture_start + float(i) * 78.0, 28)
        culture_buttons[i].size = Vector2(72, 38)

    status_label.position = Vector2(16, 70)
    status_label.size = Vector2(size.x - 32, 20)

func _panel_style(bg: Color, radius: int, border: Color, border_width: int, shadow: int = 0) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.border_width_left = border_width
    style.border_width_right = border_width
    style.border_width_top = border_width
    style.border_width_bottom = border_width
    style.border_color = border
    if shadow > 0:
        style.shadow_color = Color(0, 0, 0, 0.35)
        style.shadow_size = shadow
    return style

func _make_nav_button(text: String) -> Button:
    var button: Button = Button.new()
    button.text = text
    button.add_theme_font_size_override("font_size", 12)
    button.add_theme_color_override("font_color", C_TEXT)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_color_override("font_disabled_color", C_GOLD)
    button.add_theme_stylebox_override("normal", _panel_style(C_PANEL, 9, Color("344050"), 1))
    button.add_theme_stylebox_override("hover", _panel_style(C_PANEL_2, 9, C_GOLD.darkened(0.25), 1))
    button.add_theme_stylebox_override("pressed", _panel_style(Color("2e3846"), 9, C_GOLD, 1))
    button.add_theme_stylebox_override("disabled", _panel_style(Color("2b3440"), 9, C_GOLD, 1))
    return button

func _make_dock_button(text: String) -> Button:
    var button: Button = Button.new()
    button.text = text
    button.add_theme_font_size_override("font_size", 10)
    button.add_theme_color_override("font_color", C_TEXT)
    button.add_theme_stylebox_override("normal", _panel_style(Color("202935"), 8, Color("374354"), 1))
    button.add_theme_stylebox_override("hover", _panel_style(Color("2a3544"), 8, C_GOLD.darkened(0.2), 1))
    button.add_theme_stylebox_override("pressed", _panel_style(Color("3b3426"), 8, C_GOLD, 1))
    return button

func _make_action_button(text: String, accent: Color) -> Button:
    var button: Button = Button.new()
    button.text = text
    button.add_theme_font_size_override("font_size", 12)
    button.add_theme_color_override("font_color", C_TEXT)
    button.add_theme_stylebox_override("normal", _panel_style(accent.darkened(0.5), 8, accent.darkened(0.1), 1))
    button.add_theme_stylebox_override("hover", _panel_style(accent.darkened(0.35), 8, accent, 1))
    button.add_theme_stylebox_override("pressed", _panel_style(accent.darkened(0.6), 8, accent, 1))
    return button

func _switch_view(view_name: String) -> void:
    current_view = view_name
    city_view.visible = view_name == "city"
    world_view.visible = view_name == "world"
    reports_frame.visible = view_name == "reports"
    side_panel.visible = view_name != "reports"
    scout_button.visible = view_name == "world"
    attack_button.visible = view_name == "world"
    bottom_bar.visible = view_name == "city"
    _refresh_side_panel()
    _refresh_nav_buttons()

func _refresh_nav_buttons() -> void:
    nav_city.disabled = current_view == "city"
    nav_world.disabled = current_view == "world"
    nav_reports.disabled = current_view == "reports"

func _refresh_all() -> void:
    subtitle_label.text = "%s  •  %s  •  CITY HALL %d" % [GameState.city_name.to_upper(), GameState.civilization.to_upper(), GameState.city_hall]
    var keys: Array[String] = ["food", "wood", "stone", "metal", "coin"]
    for i: int in range(keys.size()):
        var key: String = keys[i]
        resource_value_labels[i].text = _compact_number(int(GameState.resources[key]))
        resource_rate_labels[i].text = "+%s/h" % _compact_number(int(GameState.resources_per_hour[key]))
    _refresh_side_panel()
    _refresh_reports()
    _refresh_culture_buttons()
    status_label.text = message_text if message_text != "" else "DRAG A BUILDING TO MOVE IT  •  TAP A BUILDING FOR DETAILS  •  WORLD OPENS THE STRATEGIC MAP"

func _refresh_culture_buttons() -> void:
    var civs: Array[String] = ["Rome", "Egypt", "Carthage", "Greece"]
    for i: int in range(culture_buttons.size()):
        culture_buttons[i].disabled = civs[i] == GameState.civilization
        if culture_buttons[i].disabled:
            culture_buttons[i].add_theme_stylebox_override("disabled", _panel_style(Color("3a3325"), 8, C_GOLD, 1))
            culture_buttons[i].add_theme_color_override("font_disabled_color", C_GOLD)

func _compact_number(value: int) -> String:
    if value >= 1000000:
        return "%.1fM" % (float(value) / 1000000.0)
    if value >= 1000:
        return "%.1fk" % (float(value) / 1000.0)
    return str(value)

func _refresh_side_panel() -> void:
    if current_view == "world":
        var city: Dictionary = GameState.get_selected_world_city()
        side_kicker.text = "STRATEGIC TARGET"
        side_title.text = String(city.get("name", "Unknown"))
        side_text.text = "[color=#d7ad55]%s[/color] culture\nRuled by %s\nLevel %d city\n\nThe world-map mockup now uses civilization markers, terrain dressing, roads and stronger visual framing.\n\nSelect another city or test the action buttons below." % [String(city.get("civ", "Neutral")), String(city.get("owner", "Unknown")), int(city.get("level", 1))]
    else:
        side_kicker.text = "CITY INSPECTOR"
        if selected_building_id != -1:
            var building: Dictionary = GameState.get_building_by_id(selected_building_id)
            if not building.is_empty():
                side_title.text = GameState.get_building_display_name(String(building["type"]))
                side_text.text = "[color=#d7ad55]LEVEL %d[/color]\nPlot %d, %d\n\nDrag this building to another tile. The city redraws immediately with the current civilization palette and details." % [int(building["level"]), int(building["gx"]), int(building["gy"])]
                return
        side_title.text = GameState.city_name
        side_text.text = "[color=#d7ad55]%s CITY MOCKUP[/color]\nPopulation %d\n\nThis pass focuses on presentation: richer terrain, cleaner framing, more distinctive buildings, citizens, walls, roads and a compact mobile UI." % [GameState.civilization.to_upper(), GameState.population]

func _refresh_reports() -> void:
    var lines: PackedStringArray = []
    for report: Dictionary in GameState.reports:
        lines.append("[color=#d7ad55][b]%s[/b][/color]\n[color=#aeb8c5]%s[/color]" % [String(report.get("title", "Update")), String(report.get("body", ""))])
    reports_box.text = "\n\n".join(lines)

func _on_add_building(kind: String) -> void:
    GameState.add_building(kind)
    message_text = "PLACED %s  •  DRAG IT TO REPOSITION" % GameState.get_building_display_name(kind).to_upper()
    _refresh_all()

func _on_switch_civ(civ: String) -> void:
    GameState.set_civilization(civ)
    message_text = "%s STYLE ACTIVE" % civ.to_upper()
    _refresh_all()

func _on_building_clicked(building_id: int) -> void:
    selected_building_id = building_id
    city_view.set_selected_building(building_id)
    _refresh_side_panel()

func _on_world_city_clicked(city_id: int) -> void:
    GameState.select_world_city(city_id)
    message_text = "TARGET SELECTED"
    _refresh_side_panel()

func _on_reset_demo() -> void:
    GameState.reset_demo(GameState.civilization)
    message_text = "CITY LAYOUT RESET"
    selected_building_id = -1
    _refresh_all()
