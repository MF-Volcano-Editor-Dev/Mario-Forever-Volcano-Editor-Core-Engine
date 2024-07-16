class_name CircularMovementObject2D extends Node2D

## A 2D object that moves in a circle or an ellipse.
##
## This object is driven by [Ellipse] which contains basic methods and properties for construction of a circle or an ellipse.[br]
## [br]
## [member amplitude] equals to the two axises of an ellipse. [member frequency], or [u]angle_speed[/u], determines how fast the object will move on the circle or ellipse. And [member phase] decides the point of the object on the route.[br]
## Besides, the ellipse itself have ability to rotate as well. As long as [member amplitude] constructs an ellipse whose x-axis is not equal to y-axis, the route will rotate if [member track_rotation_speed]
## is set over zero.[br]
## [br]
## Amplitude can change, too. With [member amplitude_changing_speed] adjusted, the amplitude of the route will vary from [member amplitude] to [member amplitude_max].
## Developer can modify [member amplitude_changing_mode] to define the transition of changing speed of amplitude.

@export_subgroup("Basic")
@export_group("Tracks and Speed")
## Amplitude (X-axis and Y-axis) of the route
@export var amplitude: Vector2 = Vector2.ONE * 150
## Frequency of chaning phase (Angular speed of the object)
@export_range(-18000, 18000, 0.1, "radians_as_degrees", "suffix:°/s") var frequency: float = 0.872665
## Phase of the route (Angle between the position of the object to the center and the positive X-axis)
@export_range(-180, 180, 0.1, "radians_as_degrees") var phase: float
## If [code]true[/code], then the [member phase] will be automatically initialized from -180° to 180°
@export var random_phase: bool
@export_subgroup("Track Rotation")
## Rotation speed of the route
@export_range(-18000, 18000, 0.1, "radians_as_degrees", "suffix:°/s") var track_rotation_speed: float
## Rotation of the route
@export_range(-180, 180, 0.1, "radians_as_degrees") var track_angle: float
@export_subgroup("Special Radius")
## Maximum of amplitude. [b]Only works when [member amplitude_changing_speed] is greater than zero![/b]
@export var amplitude_max: Vector2 = Vector2.ONE * 200
## Changing speed of [member amplitude]. This is an [b]average[/b] value!
@export_range(0, 2500, 0.1, "or_greater", "hide_slider", "suffix:px/s") var amplitude_changing_speed: float
## Mode of changing amplitude. See [enum Tween.TransitionType]
@export var amplitude_changing_mode := Tween.TRANS_LINEAR
@export_group("Facing")
## Facing method of the object. Useful for objects that have facings.
@export_enum("None", "Sine", "Cosine", "Look at Player", "Back against Player") var facing_mode: int

var _tw: Tween
var _ellipse: Ellipse = Ellipse.new()


func _ready() -> void:
	_ellipse.center = position
	_update_amplitude_changing()
	
	if random_phase:
		phase = randf_range(-PI, PI)

func _process(delta: float) -> void:
	_update()
	
	phase = wrapf(phase + frequency * delta, -PI, PI)
	track_angle = wrapf(track_angle + track_rotation_speed * delta, -PI, PI)
	
	var arc_phase := phase
	position = _ellipse.get_point(arc_phase)
	
	match facing_mode:
		1:
			set_meta(&"facing", signf(sin(arc_phase)))
		2:
			set_meta(&"facing", signf(cos(arc_phase)))
		3, 4:
			var np := Character.Getter.get_nearest(get_tree(), global_position)
			if !np:
				return
			set_meta(&"facing", Transform2DAlgo.get_direction_to_regardless_transform(global_position, np.global_position, global_transform) * (1 if facing_mode == 3 else -1))


func _update() -> void:
	_ellipse.amplitude = amplitude
	_ellipse.rotation = track_angle

func _update_amplitude_changing() -> void:
	if amplitude_changing_speed > 0:
		# Average values
		var avr_amplitude := (absf(amplitude_max.x - amplitude.x) + absf(amplitude_max.y - amplitude.y)) / 2
		# Tween (Using average values)
		_tw = create_tween().set_trans(amplitude_changing_mode).set_loops()
		_tw.tween_property(self, ^"amplitude", amplitude_max, avr_amplitude / amplitude_changing_speed)
		_tw.tween_property(self, ^"amplitude", amplitude, avr_amplitude / amplitude_changing_speed)
