class_name BricksBlock2D extends QuestionBlock2D

## A special type of [QuestionBlock2D] which is breakable when it gets hit
##
## [b]Note:[/b] For non-[Mario] objects, their [Bumper2D]s should be grouped in [code]bricks_breakable[/code] node group to break the bricks block.

@export_group("Particles")
## Path to a [GPUParticles2D] that emits scraps of the bricks block.
@export_node_path("GPUParticles2D") var particles_path: NodePath
## Gravity scale of the brick scraps
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:x") var particles_gravity_scale: float = 0.25
@export_group("Character Bumping")
## If [member MarioPowerup.powerup_level] is lower than this value, the brick cannot be broken.
@export_range(-5, 5) var required_powerup_level: int = 1
@export_group("Sounds", "sound_")
@export var sound_bump: AudioStream = preload("res://engine/assets/sounds/bump.wav")
@export var sound_break: AudioStream = preload("res://engine/assets/sounds/break.wav")

@onready var _particles: GPUParticles2D = get_node_or_null(particles_path)


func _ready() -> void:
	super()
	
	# Independentify the process materials
	if _has_particles_plus_material():
		_particles.process_material = _particles.process_material.duplicate(true)


func _bump_process(bumper: Bumper2D, _touch_spot: Vector2) -> void:
	if !items.is_empty():
		super(bumper, _touch_spot) # If containing item, then act as a question block
	elif !block_visible || \
		(bumper.body is Mario && bumper.body.get_current_powerup().powerup_level < required_powerup_level) || \
		(!bumper.body is Mario && !bumper.is_in_group(&"bricks_breakable")):
			_bump()
	else:
		_break()


func _bump() -> void:
	Sound.play_2d(sound_bump, self)
	bumped.emit()
	restore_bump()

func _break() -> void:
	Sound.play_2d(sound_break, self)
	
	if _has_particles_plus_material():
		var g := PhysicsServer2D.body_get_direct_state(get_rid()).total_gravity
		
		(_particles.process_material as ParticleProcessMaterial).gravity = particles_gravity_scale * Vector3(g.x, g.y, 0)
		_particles.global_rotation = g.angle() - PI/2
		
		_particles.finished.connect(_particles.queue_free)
		(func() -> void:
			_particles.reparent(get_parent())
			_particles.emitting = true
		).call_deferred()
	
	queue_free()


func _has_particles_plus_material() -> bool:
	return _particles && _particles.process_material
