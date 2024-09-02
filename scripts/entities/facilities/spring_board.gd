extends EntityBody2D

## Emitted when an object squashes the spring board
signal spring_board_triggered

@export_category("Spring Board")
## Jumping speed passed to the player when the player is squashing the spring without jumping key being held.
@export_range(0, 9999, 0.001, "or_greater", "suffix:px/s") var player_jumping_strength_tipped: float = 500
## Jumping speed passed to the player when the player is squashing the spring without jumping key being held.
@export_range(0, 9999, 0.001, "or_greater", "suffix:px/s") var player_jumping_strength_squashed: float = 990
## Jumping speed passed to the player when an object is squashing the spring.
@export_range(0, 9999, 0.001, "or_greater", "suffix:px/s") var item_jumping_strength_squashed: float = 745
@export_group("Sounds", "sound_")
## Sound of pushing objects up
@export var sound_spring: AudioStream = preload("res://engine/assets/sounds/springboard.wav")

@onready var _jumping_check: Area2D = $JumpingCheck
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_jumping_check.body_entered.connect(_on_spring_pushing_object_up)

func _physics_process(delta: float) -> void:
	calculate_gravity()
	calculate_damp()
	move_and_slide()


func _on_spring_pushing_object_up(body: Node2D) -> void:
	var up := Vector2.UP.rotated(global_rotation)
	
	if body is CharacterBody2D && !body.velocity.is_zero_approx():
		var vdot: float = body.velocity.normalized().dot(up)
		if vdot > 0 || is_zero_approx(vdot):
			return
		
		if body is Character:
			up *= player_jumping_strength_squashed if body.get_input_pressed(&"jump") else player_jumping_strength_tipped
		else:
			up *= item_jumping_strength_squashed
		
		body.velocity = up
		
		Sound.play_2d(sound_spring, self)
		
		_animated_sprite.play(&"squashed")
		_animated_sprite.animation_finished.connect(_animated_sprite.play.bind(&"default"), CONNECT_ONE_SHOT)
		
		spring_board_triggered.emit()
