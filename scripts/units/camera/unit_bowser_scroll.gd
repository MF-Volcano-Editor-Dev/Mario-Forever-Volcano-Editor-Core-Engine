@tool
extends RayCast2D

@export_category("Bowser Scroll Trigger")
@export var to_global_position: Vector2
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var speed: float = 50
@export_group("Music", "music_")
@export var music_boss_battle: AudioStream = preload("res://engine/assets/musics/music_bowser_battle.mp3")

var _tweener: Tween


func _draw() -> void:
	if !Engine.is_editor_hint():
		return
	
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE / scale)
	draw_line(Vector2.ZERO, to_global_position - global_position, Color.PALE_VIOLET_RED, 4)
	draw_circle(to_global_position - global_position, 8, Color.PALE_VIOLET_RED)

func _process(delta: float) -> void:
	if !Engine.is_editor_hint():
		return
	queue_redraw()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if !is_colliding():
		return
	
	var autoscroll := AutoScrollCamera2D.new()
	var cam := get_viewport().get_camera_2d()

	autoscroll.global_position = cam.get_screen_center_position()
	autoscroll.limit_left = cam.limit_left
	autoscroll.limit_right = cam.limit_right
	autoscroll.limit_top = cam.limit_top
	autoscroll.limit_bottom = cam.limit_bottom
	(func() -> void:
		cam.add_sibling(autoscroll, true)
		cam.get_parent().move_child(autoscroll, cam.get_index() + 1)
		cam.queue_free() # Yes, you cannot reuse the previous camera anymore.
		autoscroll.make_current()
		autoscroll.force_update_scroll()
		
		_tweener = autoscroll.create_tween()
		_tweener.tween_property(autoscroll, ^"global_position", to_global_position, autoscroll.global_position.distance_to(to_global_position) / speed)
		
		Music.fade_all(-50, 1, true)
		Music.play(get_tree(), music_boss_battle, 0)
	).call_deferred()
	
	queue_free()
