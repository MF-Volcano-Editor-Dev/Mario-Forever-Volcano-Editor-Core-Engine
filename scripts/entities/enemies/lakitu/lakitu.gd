extends Node2D

signal pitched ## Emitted when lakitu pitched an object.

const _LakituDeath := preload("res://engine/scripts/entities/enemies/#death/lakitu_death.gd")

@export_category("Lakitu")
@export_node_path("Area2D") var activation_area_path: NodePath
@export_group("References")
@export_node_path("Timer") var timer_animation: NodePath = ^"TimerAnimation"
@export_node_path("Timer") var timer_pitch: NodePath = ^"TimerPitch"
@export_node_path("RayCast2D") var stop_pitching_path: NodePath = ^"StopPitching"
@export_node_path("AnimatedSprite2D") var animated_sprite_path: NodePath = ^"AnimatedSprite2D"
@export_node_path("Instantiater2D") var pitcher_path: NodePath = ^"Pitcher"
@export_node_path("VisibleOnScreenEnabler2D") var vision_enabler_path: NodePath = ^"VisibleOnScreenEnabler2D"
@export_group("Physics")
@export_range(0, 320, 0.001, "suffix:px") var hovering_margin: float = 100
@export_range(0, 320, 0.001, "suffix:px") var hovering_margin_extra: float = 50
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var out_margin_speed: float = 450
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var in_margin_speed: float = 100
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s²") var acceleration: float = 1000
@export_subgroup("Exitting")
@export_enum("Left: -1", "Right: 1") var exitting_direction: int = -1
@export_range(0, 10, 0.001, "suffix:s") var exitting_speed: float = 100
@export_group("Attack")
@export_range(0, 10, 0.001, "suffix:s") var pitch_interval: float = 4
@export_range(0, 10, 0.001, "suffix:s") var pitch_interval_extra: float = 1
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var pitched_item_x_speed_scale: float = 0.3
@export_group("Animation")
@export_range(0, 10, 0.001, "suffix:s") var animation_interval: float = 1
@export_range(0, 10, 0.001, "suffix:s") var animation_interval_extra: float = 2
@export_group("Death")
@export_enum("Left: -1", "Right: 1") var rebirth_side: int = 1
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px") var rebirth_safe_margin: float = 32
@export_range(-1, 100) var death_times: int = -1
@export_range(0, 60, 0.001, "suffix:s") var death_rebirth_time: float = 4
@export_group("Sounds", "sounds_")
@export var sounds_lakitu: Array[AudioStream] = [
	preload("res://engine/assets/sounds/lakitu_mek.ogg"),
	preload("res://engine/assets/sounds/lakitu_rek.ogg"),
	preload("res://engine/assets/sounds/lakitu_myu.ogg")
]

var _dir: int
var _parent: Node # Used for rebirth
var _death_spot: Vector2
var _activated: bool
var _speed: float

@onready var _activation_area: Area2D = get_node_or_null(activation_area_path)
@onready var _timer_anim: Timer = get_node(timer_animation)
@onready var _timer_pitch: Timer = get_node(timer_pitch)
@onready var _stop_pitching: RayCast2D = get_node(stop_pitching_path)
@onready var _sprite: AnimatedSprite2D = get_node(animated_sprite_path)
@onready var _pitcher: Instantiater2D = get_node_or_null(pitcher_path)
@onready var _vision_enabler: VisibleOnScreenEnabler2D = get_node(vision_enabler_path)


func _ready() -> void:
	if _activation_area:
		_activation_area.body_entered.connect(_on_activation.bind(true))
	else:
		_activated = true
		_timer_pitch.start(_get_rand(pitch_interval, pitch_interval_extra))
	
	_timer_anim.start(_get_rand(animation_interval, animation_interval_extra))
	_timer_anim.timeout.connect(_on_anim)
	_timer_pitch.timeout.connect(_on_attack)

func _process(delta: float) -> void:
	var tree := get_tree()
	if _activated && !Character.Getter.get_characters(tree).is_empty():
		var avepos := Character.Getter.get_average_global_position(tree, global_position) # Average character position
		var t_avepos_x := global_transform.affine_inverse().basis_xform(avepos).x # X component of transformed `avepos`
		var t_gpos_x := global_transform.affine_inverse().basis_xform(global_position).x # X component oftransformed `global_position`
		_dir = int(roundf(signf(t_avepos_x - t_gpos_x)))
		
		# Chasing (fast)
		if t_gpos_x < t_avepos_x - hovering_margin - hovering_margin_extra || t_gpos_x > t_avepos_x + hovering_margin + hovering_margin_extra:
			_speed = move_toward(_speed, _dir * out_margin_speed, acceleration * delta)
		# Hover (slow)
		elif _dir != 0 && ((t_gpos_x < t_avepos_x - hovering_margin && _speed < in_margin_speed) || (t_gpos_x > t_avepos_x + hovering_margin && _speed > -in_margin_speed)):
			_speed = move_toward(_speed, _dir * in_margin_speed, acceleration * 0.5 * delta)
	else:
		_speed = move_toward(_speed, exitting_speed * exitting_direction, acceleration * delta)
	
	move_local_x(_speed * delta)
	
	if _dir != 0:
		set_meta(&"facing", _dir)


func rebirth() -> void:
	_parent.add_child.call_deferred(self)
	_parent = null
	(func() -> void: # Add child is called in a deferred manner
		while get_viewport_rect().grow(rebirth_safe_margin).has_point(get_global_transform_with_canvas().get_origin()):
			global_position += rebirth_side * Vector2.RIGHT.rotated(global_rotation)
	).call_deferred()


func _on_activation(body: Node2D, in_or_out: bool) -> void:
	if !body is Character:
		return
	
	if in_or_out:
		_timer_pitch.paused = false
		_timer_pitch.start(_get_rand(pitch_interval, pitch_interval_extra))
	else:
		_timer_pitch.paused = true
	
	_activated = in_or_out
	_vision_enabler.enable_node_path = ^"." if in_or_out else _vision_enabler.get_path_to(self)

func _on_anim() -> void:
	if _sprite && !_sprite.animation == &"pitching":
		var rand: int = [0, 1].pick_random()
		_sprite.play(&"blink" + str(rand + 1))
		await _sprite.animation_finished
		_sprite.play(&"default")
	
	_timer_anim.start(_get_rand(animation_interval, animation_interval_extra))

func _on_attack() -> void:
	_timer_anim.stop()
	
	_sprite.play(&"pitch")
	await _sprite.animation_finished
	_sprite.play_backwards(&"pitch")
	# Pause pitching if the lakitu is colliding with a blocks
	while _stop_pitching.is_colliding():
		_sprite.frame = _sprite.sprite_frames.get_frame_count(_sprite.animation) - 1
		await get_tree().process_frame
	
	await _sprite.animation_finished
	_sprite.play(&"default")
	
	# Pitches the item only when the lakitu is in the screen
	if get_viewport_rect().has_point(get_global_transform_with_canvas().get_origin()) && !_stop_pitching.is_colliding():
		Sound.play_2d(sounds_lakitu.pick_random(), self)
		if _pitcher:
			var items := _pitcher.instantiate_all()
			for i in items:
				if i is EntityBody2D:
					i.velocality.x += _speed * pitched_item_x_speed_scale
	
	_timer_anim.start(_get_rand(animation_interval, animation_interval_extra))
	_timer_pitch.start(_get_rand(pitch_interval, pitch_interval_extra))


func _get_rand(base: float, extra: float = 0) -> float:
	return randf_range(absf(base), absf(base) + randf_range(0, absf(extra)))


func _on_killing(ins: CanvasItem) -> void:
	if !ins is _LakituDeath:
		return
	
	var death := ins as _LakituDeath
	death.rebirth_time_down(death_rebirth_time)
	death.lakitu_reborn.connect(rebirth)
	
	# Because we don't know if this call is processed first or _on_killed_processed(),
	# we have to defer this call to ensure its safety
	(func() -> void:
		if death_times == 0:
			death.last_one = true
	).call_deferred()

func _on_killed_processed() -> void:
	_parent = get_parent()
	_death_spot = global_position
	
	if death_times > 0:
		death_times -= 1
		if death_times <= 0:
			queue_free()
			return
	
	_parent.remove_child.call_deferred(self)
