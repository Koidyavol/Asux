extends Node2D

const TILE := 32
const WORLD_W := 80
const WORLD_H := 28
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const BLOCKS := {
    "Tanah": Color("#9b633d"),
    "Batu": Color("#7b8490"),
    "Air": Color("#3498db"),
    "Pasir": Color("#e7cc83")
}

var player: CharacterBody2D
var inventory := {"Tanah": 20, "Batu": 20, "Air": 20, "Pasir": 20}
var selected_block := "Tanah"
var cells: Dictionary = {}
var tile_layer := Node2D.new()
var ui_layer := CanvasLayer.new()
var info_label: Label
var inventory_buttons := {}

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
    visual.polygon = PackedVector2Array(Vector2(-16,-16), Vector2(16,-16), Vector2(16,16), Vector2(-16,16))
    visual.color = BLOCKS[block]
    body.add_child(visual)
    var outline := Line2D.new()
    outline.points = PackedVector2Array(Vector2(-16,-16), Vector2(16,-16), Vector2(16,16), Vector2(-16,16), Vector2(-16,-16))
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
        b.position = Vector2(12 + i * 112, 88)
        b.size = Vector2(104, 52)
        b.text = name + "\n20"
        b.add_theme_font_size_override("font_size", 15)
        b.pressed.connect(_select_block.bind(name))
        ui_layer.add_child(b)
        inventory_buttons[name] = b

    _add_control("◀", Vector2(18, 430), Vector2(72, 72), "move_left")
    _add_control("▶", Vector2(100, 430), Vector2(72, 72), "move_right")
    _add_control("LOMPAT", Vector2(690, 430), Vector2(105, 72), "jump")
    _add_control("PUKUL", Vector2(810, 430), Vector2(125, 72), "punch")

    var hint := Label.new()
    hint.text = "Keyboard: A/D atau ←/→ • Space lompat • J pukul • Tap area kosong untuk pasang blok"
    hint.position = Vector2(340, 14)
    hint.add_theme_color_override("font_color", Color("#17212b"))
    hint.add_theme_font_size_override("font_size", 13)
    ui_layer.add_child(hint)

func _add_control(label_text: String, pos: Vector2, button_size: Vector2, action: String) -> void:
    var b := Button.new()
    b.text = label_text
    b.position = pos
    b.size = button_size
    b.add_theme_font_size_override("font_size", 19)
    b.button_down.connect(func(): Input.action_press(action))
    b.button_up.connect(func(): Input.action_release(action))
    ui_layer.add_child(b)

func _select_block(block: String) -> void:
    selected_block = block
    _update_inventory_ui()

func _update_inventory_ui() -> void:
    for block in inventory_buttons:
        var b: Button = inventory_buttons[block]
        b.text = block + "\n" + str(inventory[block])
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
    cells.erase(target)
    for child in tile_layer.get_children():
        if child is StaticBody2D and child.get_meta("cell", Vector2i(-999,-999)) == target:
            child.queue_free()
            break
    inventory[block] += 1
    _update_inventory_ui()
