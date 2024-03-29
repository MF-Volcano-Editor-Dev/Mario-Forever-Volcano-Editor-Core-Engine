extends CharacterBody2D

signal thwomp_smashed ## Emitted when the thwomp smashed onto the ground.

@export_category("Thwomp")
@export var smashing_margin: Rect2 = Rect2(Vector2(-80, -32), Vector2(160, 480))
@export_group("Physics")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:x") var gravity_scale: float = 1
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var max_falling_speed: float = 1500
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var rising_speed: float = 50
@export_group("Await")
@export_range(0, 30, 0.001, "suffix:s") var waiting_duration_on_ground: float = 1
@export_range(0, 10, 0.001, "suffix:s") var waiting_after_return: float = 0.1
@export_group("Effects")
@export var explosion_effect: PackedScene = preload("res://engine/objects/entities/#effects/explosion_fire.tscn")
@export_group("References")
@export_node_path("AnimatedSprite2D") var sprite_path: NodePath = ^"AnimatedSprite2D"
@export_node_path("Timer") var timer_anim_path: NodePath = ^"TimerAnim"
@export_node_path("RayCast2D") var explosion_detc_left_path: NodePath = ^"ExplosionLeft"
@export_node_path("RayCast2D") var explosion_detc_right_path: NodePath = ^"ExplosionRight"
@export_group("Sounds", "sound_")
@export var sound_stun: AudioStream = preload("res://engine/assets/sounds/stun.wav")
@export var sound_laugh: AudioStream = preload("res://engine/assets/sounds/laughing.wav")

var _origin: Vector2
var _step: int

@onready var _sprite: AnimatedSprite2D = get_node(sprite_path)
@onready var _timer_anim: Timer = get_node(timer_anim_path)
@onready var _explosion_detc_left: RayCast2D = get_node(explosion_detc_left_path)
@onready var _explosion_detc_right: RayCast2D = get_node(explosion_detc_right_path)


func _ready() -> void:
	_timer_anim.start(randf_range(1, 3))
	_timer_anim.timeout.connect(func() -> void:
		_timer_anim.start(randf_range(1, 3))
		_sprite.play(&"blink")
	)
	_sprite.animation_finished.connect(func() -> void:
		if _sprite.animation == &"blink":
			_sprite.play(&"default")
	)


func _physics_process(delta: float) -> void:
	match _step:
		0:
			var np := Character.Getter.get_nearest(get_tree(), global_position)
			if !np:
				return
			
			var trans := global_transform.affine_inverse()
			var nptpos := trans.basis_xform(np.global_position)
			var margin := smashing_margin
			margin.position += trans.basis_xform(global_position)
			
			if margin.has_point(nptpos):
				_origin = global_position
				_step = 1
		1: # Smashing
			var ds := PhysicsServer2D.body_get_direct_state(get_rid())
			if !ds:
				return
			up_direction = Vector2.UP.rotated(global_rotation)
			velocity -= up_direction * gravity_scale * ds.total_gravity.length() * delta
			
			if velocity.project(-up_direction).length_squared() > max_falling_speed ** 2:
				velocity = Transform2DAlgo.get_projection_limit(velocity, -up_direction, max_falling_speed)
			
			move_and_slide()
			
			if is_on_floor():
				var cam := get_viewport().get_camera_2d() as GameCamera2D
				
				_step = 2
				
				# Explosion effect
				if explosion_effect:
					for i in 2:
						var detc := _explosion_detc_left if i == 0 else _explosion_detc_right
						detc.force_raycast_update()
						if !detc.is_colliding():
							continue
						
						var e := explosion_effect.instantiate()
						e.global_transform = detc.global_transform
						add_sibling.call_deferred(e)
						(func() -> void:
							e.get_parent().move_child(e, get_index() + 1)
						).call_deferred()
				
				# When the thwomp stuns on bricks,
				# the three lines will help avoid sounds repeating
				await get_tree().create_timer(0.05, false).timeout
				if _step != 2:
					if cam:
						cam.shake(Vector2.ONE * 8, 5)
					return
				
				if cam:
					cam.shake(Vector2.ONE * 12, 5)
				Sound.play_2d(sound_stun, self)
				
				await get_tree().create_timer(waiting_duration_on_ground, false).timeout
				_step = 3
		3: # Raising
			up_direction = Vector2.UP.rotated(global_rotation)
			velocity = up_direction * rising_speed
			move_and_slide()
			
			if is_on_ceiling() || _is_thwomp_rising_over():
				while _is_thwomp_rising_over():
					global_position -= up_direction
				
				_step = 4
				await get_tree().create_timer(waiting_after_return, false).timeout
				_step = 0


func _is_thwomp_rising_over() -> bool:
	return global_position.direction_to(_origin).dot(up_direction) < 0


func _on_player_touched(toucher: PhysicsBody2D) -> void:
	if !toucher is Character:
		return
	if toucher is Mario && toucher.is_invulnerable():
		return
	
	_timer_anim.paused = true
	_sprite.play(&"laugh")
	
	await Sound.play_2d(sound_laugh , self).finished
	await get_tree().create_timer(0.1).timeout
	
	_sprite.play(&"default")
	_timer_anim.paused = false

func _on_thwomp_breaking_bricks() -> void:
	_step = 1
