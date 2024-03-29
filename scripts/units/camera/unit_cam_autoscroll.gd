@tool
class_name AutoScrollCamera2D extends GameCamera2D

## Path to [PathFollow2D] to which the camera is going to track the global position.
@export_node_path("PathFollow2D") var camera_follower_path: NodePath = ^".."
## Margin to push the character at the edge of the screen.
@export_range(-32, 32, 0.001, "suffix:px") var margin: float = 16
## If [code]false[/code], the autoscrolling camera will not push the character when he/she touches the edge of screen
@export var push_character_at_the_edge_of_screen: bool = true

var _no_characters: bool # When all characters are dead, this will be turned on to stop camera tracking null player

@onready var _camera_follower: PathFollow2D = get_node_or_null(camera_follower_path) as PathFollow2D


#region == Property Overriders ==
func _init_overridden_properties() -> void:
	super()
	focus_characters = false
#endregion


func _ready() -> void:
	super()
	
	if Engine.is_editor_hint():
		return
	
	Events.EventCharacter.get_signals().all_characters_dead.connect(func() -> void:
		_no_characters = true
	)
	Events.EventGame.get_signals().completed_level.connect(func() -> void:
		push_character_at_the_edge_of_screen = false
	)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _no_characters:
		return
	if focus_process_mode != CAMERA2D_PROCESS_IDLE:
		return
	if _camera_follower:
		global_position = _camera_follower.global_position
	_character_edgeblock.call_deferred()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _no_characters:
		return
	if focus_process_mode != CAMERA2D_PROCESS_PHYSICS:
		return
	if _camera_follower:
		global_position = _camera_follower.global_position
	_character_edgeblock.call_deferred()


func _character_edgeblock() -> void:
	var width := get_viewport_rect().size.x # Viewport width
	var canvas_rot := get_viewport_transform().get_rotation() # Canvas rotation
	var characters: Array[Character] = Character.Getter.get_characters(get_tree())
	
	if push_character_at_the_edge_of_screen:
		for i in characters:
			if !get_limit_rect().has_point(i.global_position):
				continue
			
			var edge: bool = false
			var kc: KinematicCollision2D
			while i.get_global_transform_with_canvas().get_origin().x < margin && !kc:
				kc = i.move_and_collide(Vector2.RIGHT.rotated(canvas_rot))
				edge = true
			while i.get_global_transform_with_canvas().get_origin().x > width - margin && !kc:
				kc = i.move_and_collide(Vector2.LEFT.rotated(canvas_rot))
				edge = true
			if edge:
				i.velocality.x = 0
			
			# Character being squeezed to death
			var pposx := i.get_global_transform_with_canvas().get_origin().x # X position in canvas
			if (pposx < margin || pposx > width - margin) && kc.get_collider():
				i.die()

#region == Setgets ==
func set_focus_characters(value: bool) -> void:
	if value:
		push_warning("AutoScrollCamera2D shouldn't get this value turned on! See the documentation of GameCamera2D.")
	focus_characters = false
#endregion
