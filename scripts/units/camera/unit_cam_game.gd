@tool
class_name GameCamera2D extends Camera2D

## Camera that is applied for general scenes, such as levels and maps.
##
## For autoscroll usage, please see [AutoScrollCamera2D]

@warning_ignore("unused_signal")
signal camera_done_transition ## Emitted when the camera done transition. (positive)
signal camera_get_transited_to ## Emitted when the camera is transited to. (passive)

## Decide in which process will the camera update its focus.[br]
## [br]
## [b]Note:[/b] Different from [member process_callback], this only affects the way the camera updates its global position.
@export_enum("Physics", "Idle") var focus_process_mode: int
@export_group("Limit", "limit_")
## Border of the limit color
@export var limit_border_color: Color = Color.GOLD:
	set(value):
		limit_border_color = value
		queue_redraw()
@export_group("Options")
## If [code]true[/code], the camera will focus on the average global position of characters.[br]
## [br]
## [b]Note:[/b] For autoscroll sections, please turn this off.
@export var focus_characters: bool = true:
	set = set_focus_characters
@export_group("Transition", "transition_")
## Initial speed of smooth transition between two cameras.[br]
## If set to 0, the process will be hard switching and no smooth transition will happen.
@export_range(0, 50, 0.001, "suffix:px/s") var transition_initial_speed: float

@export_storage var _initialized: bool # Used to initialize the properties to be overridden

var _on_transition_execution: bool
var _on_transition: bool
var _shaking: Tween

var _delay_of_beginning_smooth_transition: int = 6


#region == Property Overriders ==
func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"editor_draw_limits":
			editor_draw_limits = value
			if Engine.is_editor_hint():
				queue_redraw()
			return true
		&"limit_left":
			limit_left = value
			if Engine.is_editor_hint():
				queue_redraw()
			return true
		&"limit_right":
			limit_right = value
			if Engine.is_editor_hint():
				queue_redraw()
			return true
		&"limit_top":
			limit_top = value
			if Engine.is_editor_hint():
				queue_redraw()
			return true
		&"limit_bottom":
			limit_bottom = value
			if Engine.is_editor_hint():
				queue_redraw()
			return true
	return false

func _property_can_revert(property: StringName) -> bool:
	match property:
		&"limit_left", &"limit_right", &"limit_top", &"limit_bottom":
			return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"limit_left", &"limit_top":
			return 0
		&"limit_right":
			return ProjectSettings.get_setting_with_override(&"display/window/size/viewport_width")
		&"limit_bottom":
			return ProjectSettings.get_setting_with_override(&"display/window/size/viewport_height")
	return
#endregion

#region == Built-in Process ==
func _ready() -> void:
	# Initialization of properties to be overridden
	if _initialized:
		return
	
	_initialized = true
	
	if Engine.is_editor_hint():
		_init_overridden_properties()
		return

func _draw() -> void:
	if !Engine.is_editor_hint():
		return
	if !editor_draw_limits:
		return
	
	draw_set_transform(-global_position, 0, Vector2.ONE / global_scale)
	draw_rect(get_limit_rect(), limit_border_color, false, 4)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if focus_process_mode != CAMERA2D_PROCESS_IDLE:
		return
	_focus.call_deferred()
	_transition.call_deferred(delta)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if focus_process_mode != CAMERA2D_PROCESS_PHYSICS:
		return
	_focus.call_deferred()
	_transition.call_deferred(delta)
#endregion

#region == Overrider ==
func _init_overridden_properties() -> void:
	limit_left = 0
	limit_right = ProjectSettings.get_setting_with_override(&"display/window/size/viewport_width")
	limit_top = 0
	limit_bottom = ProjectSettings.get_setting_with_override(&"display/window/size/viewport_height")
#endregion


#region == Camera Process ==
func _focus() -> void:
	if !is_current() || \
		!focus_characters || \
		_on_transition || \
		_on_transition_execution: # `_on_transition_execution` prevents camera from focusing on the object when it is doing transition
			return
	
	global_position = Character.Getter.get_average_global_position(get_tree(), global_position)

func _transition(delta: float) -> void:
	if _delay_of_beginning_smooth_transition > 0:
		_delay_of_beginning_smooth_transition -= 1
	
	if is_current():
		return
	
	var limit_rect: Rect2 = get_limit_rect()
	
	var characters: Array[Character] = Character.Getter.get_characters(get_tree())
	if characters.is_empty():
		return
	
	var characters_amount_in: int = 0
	for i in characters:
		if !limit_rect.has_point(i.global_position):
			continue
		characters_amount_in += 1
	if characters_amount_in < characters.size():
		return
	
	if transition_initial_speed <= 0 || _delay_of_beginning_smooth_transition: # To prevent from smooth transition at the beginning of the game (Visually safe for check point)
		_hard_transition()
	else:
		_smooth_transition(delta)

func _hard_transition() -> void:
	enabled = true
	make_current()

func _smooth_transition(delta: float) -> void:
	if _on_transition:
		return
	
	_on_transition = true
	
	var acam := get_viewport().get_camera_2d() # Active camera, [NOTE]: NOT the target camera!
	var acam_limrect := get_limit_rect(acam) # Limit rect of the active camera
	var acam_pos: Vector2 = acam.global_position # Global position before the activate camera starts transition
	var hvp_size: Vector2 = get_viewport_rect().size / 2 # Half of viewport size
	
	acam.global_position = acam.get_screen_center_position()
	if acam is GameCamera2D:
		acam._on_transition_execution = true
	
	# Extends the limitations of the active camera to make sure the transition works as usual
	acam.limit_left = int(roundf(minf(acam.global_position.x - hvp_size.x, limit_left)))
	acam.limit_right = int(roundf(maxf(acam.global_position.x + hvp_size.x, limit_right)))
	acam.limit_top = int(roundf(minf(acam.global_position.y - hvp_size.y, limit_top)))
	acam.limit_bottom = int(roundf(maxf(acam.global_position.y + hvp_size.y, limit_bottom)))
	
	# Shrinks the edges of limitation; thus the camera will get smoothly transited by them.
	var speed := transition_initial_speed * delta
	var threshold := int(roundf(transition_initial_speed / 2))
	while is_inside_tree() && \
		(absi(acam.limit_left - limit_left) > threshold || \
		absi(acam.limit_right - limit_right) > threshold || \
		absi(acam.limit_top - limit_top) > threshold || \
		absi(acam.limit_bottom - limit_bottom) > threshold):
			acam.limit_left = int(roundf(lerpf(acam.limit_left, limit_left, speed)))
			acam.limit_right = int(roundf(lerpf(acam.limit_right, limit_right, speed)))
			acam.limit_top = int(roundf(lerpf(acam.limit_top, limit_top, speed)))
			acam.limit_bottom = int(roundf(lerpf(acam.limit_bottom, limit_bottom, speed)))
			acam.force_update_scroll()
			await get_tree().physics_frame
	
	# Then manages to track to the characters' average global position smoothly
	acam.global_position = acam.get_screen_center_position()
	while is_inside_tree() && \
		acam.global_position.is_equal_approx(Character.Getter.get_average_global_position(get_tree(), acam.global_position)):
			acam.global_position = acam.global_position.move_toward(Character.Getter.get_average_global_position(get_tree(), acam.global_position), speed)
			acam.force_update_scroll()
			await get_tree().physics_frame
	
	# Done transition
	_on_transition = false
	camera_get_transited_to.emit()
	if acam is GameCamera2D:
		acam._on_transition_execution = false
		acam.camera_done_transition.emit()
	
	global_position = acam.global_position
	acam.global_position = acam_pos
	acam.limit_left = acam_limrect.position.x
	acam.limit_right = acam_limrect.end.x
	acam.limit_top = acam_limrect.position.y
	acam.limit_bottom = acam_limrect.end.y
	force_update_scroll()
	
	enabled = true
	make_current()
#endregion


## Shakes the camera.
func shake(max_amplitude: Vector2, times: int, duration: float = 0.03, trans: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	if _shaking:
		return
	
	var ofs: Vector2 = offset
	_shaking = create_tween().set_trans(trans)
	for i in times:
		_shaking.tween_property(self, ^"offset", Vector2(randf_range(-max_amplitude.x, max_amplitude.x), randf_range(-max_amplitude.y, max_amplitude.y)), duration)
	
	await _shaking.finished
	
	_shaking = null
	offset = ofs


#region == Setgets ==
func set_focus_characters(value: bool) -> void:
	focus_characters = value

## Returns a [Rect2] of [param cam]'s limitation borders.
func get_limit_rect(cam: Camera2D = self) -> Rect2i:
	return Rect2i(
		cam.limit_left, 
		cam.limit_top, 
		cam.limit_right - cam.limit_left, 
		cam.limit_bottom - cam.limit_top
	)
#endregion
