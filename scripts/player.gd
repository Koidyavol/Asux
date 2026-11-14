extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -430.0
const SPRITESHEET: Texture2D = preload("res://assets/characters/player/player_spritesheet.png")

# Frame regions are read directly from the single uploaded sprite sheet.
const IDLE_RECTS := [
    Rect2i(61, 14, 168, 228),
    Rect2i(284, 14, 169, 228),
    Rect2i(504, 14, 167, 228),
    Rect2i(725, 14, 166, 228)
]
const WALK_RECTS := [
    Rect2i(41, 262, 185, 229),
    Rect2i(265, 263, 182, 230),
    Rect2i(486, 262, 179, 228),
    Rect2i(697, 262, 177, 231),
    Rect2i(906, 260, 177, 231),
    Rect2i(1097, 261, 179, 231),
    Rect2i(1291, 260, 174, 231)
]
const JUMP_RECTS := [
    Rect2i(54, 521, 175, 213),
    Rect2i(277, 514, 176, 218),
    Rect2i(484, 521, 187, 220)
]
const PUNCH_RECTS := [
    Rect2i(57, 767, 173, 230),
    Rect2i(277, 766, 214, 231),
    Rect2i(504, 767, 208, 230),
    Rect2i(713, 767, 182, 230),
    Rect2i(929, 766, 178, 231),
    Rect2i(1137, 767, 179, 230)
]

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing := 1
var is_punching := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    _build_animations()
    animated_sprite.play("idle")
    animated_sprite.animation_finished.connect(_on_animation_finished)

func _build_animations() -> void:
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    _add_animation(frames, "idle", IDLE_RECTS, 5.0, true)
    _add_animation(frames, "walk", WALK_RECTS, 10.0, true)
    _add_animation(frames, "jump", JUMP_RECTS, 8.0, true)
    _add_animation(frames, "punch", PUNCH_RECTS, 12.0, false)
    animated_sprite.sprite_frames = frames

func _add_animation(frames: SpriteFrames, animation_name: String, regions: Array, speed: float, looping: bool) -> void:
    frames.add_animation(animation_name)
    frames.set_animation_speed(animation_name, speed)
    frames.set_animation_loop(animation_name, looping)
    for region in regions:
        var atlas_frame := AtlasTexture.new()
        atlas_frame.atlas = SPRITESHEET
        atlas_frame.region = Rect2(region.position, region.size)
        frames.add_frame(animation_name, atlas_frame)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0:
        facing = 1 if direction > 0 else -1
        velocity.x = direction * SPEED
        animated_sprite.flip_h = facing < 0
    else:
        velocity.x = move_toward(velocity.x, 0.0, SPEED * 0.8)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    move_and_slide()

    if is_punching:
        return
    if not is_on_floor():
        _play_animation("jump")
    elif absf(velocity.x) > 5.0:
        _play_animation("walk")
    else:
        _play_animation("idle")

func _play_animation(animation_name: String) -> void:
    if animated_sprite.animation != animation_name:
        animated_sprite.play(animation_name)

func play_punch() -> void:
    is_punching = true
    animated_sprite.play("punch")

func _on_animation_finished() -> void:
    if animated_sprite.animation == "punch":
        is_punching = false
