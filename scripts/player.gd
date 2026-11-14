extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -430.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing := 1

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0:
        facing = 1 if direction > 0 else -1
        velocity.x = direction * SPEED
        $Body.scale.x = facing
        $Face.scale.x = facing
        $Hair.scale.x = facing
    else:
        velocity.x = move_toward(velocity.x, 0.0, SPEED * 0.8)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    move_and_slide()
