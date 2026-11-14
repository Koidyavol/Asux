extends Node2D

const TILE := 32
const WORLD_W := 80
const WORLD_H := 28
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const BLOCKS := {
    "Tanah": Color("#9b633d"),
    "Batu": Color("#7b8490"),
    "Air": Color("#3498db"),
    "Pasir": Color("#e7cc83"),
    "end": Color("#34495e")
}

var player: CharacterBody2D
var inventory := {"Tanah": 20, "Batu": 20, "Air": 20, "Pasir": 20}
var selected_block := "Tanah"
var cells: Dictionary = {}
var tile_layer := Node2D.new()
var ui_layer := CanvasLayer.new()
var info_label: Label
var inventory_buttons := {}
var inventory_counts := {}

func _ready() -> void:
    _setup_input()
    add_child(tile_layer)
    _build_world()
    player = PLAYER_SCENE.instantiate()
    player.position = Vector2(160, 220)
    add_child(player)
    _build_ui()
    _update_inventory_ui()

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("punch"):
        _punch_nearby()

func _setup_input() -> void:
    _add_key("move_left", KEY_A)
    _add_key("move_left", KEY_LEFT)
    _add_key("move_right", KEY_D)
    _add_key("move_right", KEY_RIGHT)
    _add_key("jump", KEY_SPACE)
    _add_key("jump", KEY_W)
    _add_key("punch", KEY_J)

func _add_key(action: String, key: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action, event)

func _build_world() -> void:
    for x in range(WORLD_W):
        _set_cell(Vector2i(x, 20), "Tanah")
        _set_cell(Vector2i(x, 21), "Tanah")
        _set_cell(Vector2i(x, 22), "Batu")
        _set_cell(Vector2i(x, 23), "Batu")
        _set_cell(Vector2i(x, 24), "end")
    for x in range(8, 15):
        _set_cell(Vector2i(x, 19), "Pasir")
    for x in range(25, 30):
        _set_cell(Vector2i(x, 18), "Batu")
    for x in range(42, 48):
        _set_cell(Vector2i(x, 19), "Tanah")
    for x in range(55, 61):
        _set_cell(Vector2i(x, 20), "Pasir")
    for x in range(12, 18):
        _set_cell(Vector2i(x, 17), "Air")
    queue_redraw()

func _set_cell(cell: Vector2i, block: String) -> void:
    if cells.has(cell):
        return
    cells[cell] = block
    var body := StaticBody2D.new()
    body.position = Vector2(cell.x * TILE + TILE / 2, cell.y * TILE + TILE / 2)
    body.collision_layer = 1
    body.collision_mask = 0
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(TILE, TILE)
    shape.shape = rect
    body.add_child(shape)
    tile_layer.add_child(body)
    body.set_meta("cell", cell)
    body.add_to_group("world_blocks")
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)])
    visual.color = BLOCKS[block]
    body.add_child(visual)
    var outline := Line2D.new()
    outline.points = PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16), Vector2(-16, -16)])
    outline.width = 1.0
    outline.default_color = Color(0,0,0,0.22)
    body.add_child(outline)

func _draw() -> void:
    draw_rect(Rect2(-200, 0, WORLD_W * TILE + 400, WORLD_H * TILE), Color("#83c9e8"))
    for x in range(WORLD_W):
        draw_rect(Rect2(x * TILE, 0, 1, WORLD_H * TILE), Color(1,1,1,0.025))
    draw_rect(Rect2(0, 24 * TILE, WORLD_W * TILE, 4 * TILE), Color("#557b48"))

func _build_ui() -> void:
    add_child(ui_layer)
    var top := PanelContainer.new()
    top.position = Vector2(12, 10)
    top.size = Vector2(320, 48)
    ui_layer.add_child(top)
    info_label = Label.new()
    info_label.text = "ASUX  |  World 01"
    info_label.add_theme_font_size_override("font_size", 20)
    top.add_child(info_label)

    var inv_title := Label.new()
    inv_title.text = "INVENTORI  •  pilih blok"
    inv_title.position = Vector2(12, 64)
    inv_title.add_theme_color_override("font_color", Color("#17212b"))
    inv_title.add_theme_font_size_override("font_size", 15)
    ui_layer.add_child(inv_title)

    var names := ["Tanah", "Batu", "Air", "Pasir"]
    for i in range(names.size()):
        var name: String = names[i]
        var b := Button.new()
        b.position = Vector2(12 + i * 88, 88)
        b.size = Vector2(80, 82)
        b.text = ""
        b.tooltip_text = name
        b.pressed.connect(_select_block.bind(name))
        ui_layer.add_child(b)

        var icon := ColorRect.new()
        icon.position = Vector2(22, 8)
        icon.size = Vector2(36, 36)
        icon.color = BLOCKS[name]
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(icon)

        var item_name := Label.new()
        item_name.text = name
        item_name.position = Vector2(4, 48)
        item_name.size = Vector2(72, 20)
        item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        item_name.add_theme_font_size_override("font_size", 12)
        item_name.add_theme_color_override("font_color", Color("#17212b"))
        item_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(item_name)

        var count := Label.new()
        count.position = Vector2(48, 1)
        count.size = Vector2(29, 18)
        count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        count.add_theme_font_size_override("font_size", 12)
        count.add_theme_color_override("font_color", Color("#17212b"))
        count.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(count)

        inventory_buttons[name] = b
        inventory_counts[name] = count

    # Mobile action pads: directional controls on the left, actions on the right.
    _add_control("◀", "KIRI", Vector2(22, 424), Vector2(76, 76), "move_left", Color("#2878a8"))
    _add_control("▶", "KANAN", Vector2(108, 424), Vector2(76, 76), "move_right", Color("#2878a8"))
    _add_control("▲", "LOMPAT", Vector2(690, 424), Vector2(88, 76), "jump", Color("#268b70"))
    _add_control("✦", "PUKUL", Vector2(788, 424), Vector2(104, 76), "punch", Color("#bd7134"))

    var hint := Label.new()
    hint.text = "Keyboard: A/D atau ←/→ • Space lompat • J pukul • Tap area kosong untuk pasang blok"
    hint.position = Vector2(340, 14)
    hint.add_theme_color_override("font_color", Color("#17212b"))
    hint.add_theme_font_size_override("font_size", 13)
    ui_layer.add_child(hint)

func _add_control(symbol: String, caption: String, pos: Vector2, button_size: Vector2, action: String, accent: Color) -> void:
    var b := Button.new()
    b.text = symbol
    b.position = pos
    b.size = button_size
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", 27)
    b.add_theme_color_override("font_color", Color("#ffffff"))
    b.add_theme_color_override("font_hover_color", Color("#ffffff"))
    b.add_theme_color_override("font_pressed_color", Color("#ffffff"))

    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#172b3b")
    normal.border_color = accent
    normal.set_border_width_all(3)
    normal.set_corner_radius_all(22)
    normal.shadow_color = Color(0, 0, 0, 0.28)
    normal.shadow_size = 5
    normal.shadow_offset = Vector2(0, 3)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#24465b")
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = accent
    pressed.shadow_size = 1
    pressed.shadow_offset = Vector2(0, 1)
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", pressed)
    b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

    var tag := Label.new()
    tag.text = caption
    tag.position = Vector2(0, button_size.y - 23)
    tag.size = Vector2(button_size.x, 18)
    tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    tag.add_theme_font_size_override("font_size", 10)
    tag.add_theme_color_override("font_color", Color("#eaf6ff"))
    tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
    b.add_child(tag)

    b.button_down.connect(func(): Input.action_press(action))
    b.button_up.connect(func(): Input.action_release(action))
    b.mouse_exited.connect(func():
        if Input.is_action_pressed(action):
            Input.action_release(action)
    )
    ui_layer.add_child(b)

func _select_block(block: String) -> void:
    selected_block = block
    _update_inventory_ui()

func _update_inventory_ui() -> void:
    for block in inventory_buttons:
        var b: Button = inventory_buttons[block]
        var count: Label = inventory_counts[block]
        count.text = str(inventory[block])
        b.modulate = Color("#fff0b3") if block == selected_block else Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _try_place(get_global_mouse_position())
    elif event is InputEventScreenTouch and event.pressed:
        _try_place(get_global_mouse_position())

func _try_place(world_pos: Vector2) -> void:
    if player == null:
        return
    var cell := Vector2i(floori(world_pos.x / TILE), floori(world_pos.y / TILE))
    var center := Vector2(cell.x * TILE + TILE/2, cell.y * TILE + TILE/2)
    if center.distance_to(player.position) > TILE * 4:
        return
    if cells.has(cell) or inventory[selected_block] <= 0:
        return
    _set_cell(cell, selected_block)
    inventory[selected_block] -= 1
    _update_inventory_ui()

func _punch_nearby() -> void:
    if player == null:
        return
    player.call("play_punch")
    var facing: int = int(player.get("facing"))
    var target := Vector2i(roundi((player.position.x + facing * TILE) / TILE), roundi((player.position.y + 8) / TILE))
    if not cells.has(target):
        target = Vector2i(roundi(player.position.x / TILE), roundi((player.position.y + 36) / TILE))
    if not cells.has(target):
        return
    var block: String = cells[target]
    if block == "end":
        return
    cells.erase(target)
    for child in tile_layer.get_children():
        if child is StaticBody2D and child.get_meta("cell", Vector2i(-999,-999)) == target:
            child.queue_free()
            break
    inventory[block] += 1
    _update_inventory_ui()
