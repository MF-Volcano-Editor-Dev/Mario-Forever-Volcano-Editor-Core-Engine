extends Area2D

@export_category("Whirlpool")
@export var enabled: bool = true:
	set(value):
		enabled = true
		
		if !is_node_ready():
			await ready
		
		_particles.emitting = enabled
@export_enum("Rectangle", "Center-orinted") var suction_mode: int
@export_group("Physics")
@export_subgroup("Rectangle")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var suction_horizontal: float = 100
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var suction_vertical: float = 50
@export_subgroup("Center-oriented")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var suction_centralized: float = 75
@export_group("References")
@export_node_path("GPUParticles2D") var particles_path: NodePath = ^"GPUParticles2D"
@export_group("Particles")
@export var particles_material_rect: ParticleProcessMaterial = preload("res://engine/assets/particles/bubble_whirlpool_rect.tres")
@export var particles_material_center_oriented: ParticleProcessMaterial = preload("res://engine/assets/particles/bubble_whirlpool_radial.tres")

@onready var _particles: GPUParticles2D = get_node(particles_path)


func _ready() -> void:
	_particles.visibility_rect = shape_owner_get_shape(0, 0).get_rect()
	
	var mt: ParticleProcessMaterial = (particles_material_rect if suction_mode == 0 else particles_material_center_oriented).duplicate(true) as ParticleProcessMaterial
	var rect := shape_owner_get_shape(0, 0).get_rect()
	var half_size := rect.size / 2
	
	match suction_mode:
		0:
			mt.initial_velocity_min = suction_vertical * 2.5
			mt.initial_velocity_max = suction_vertical * 3
			mt.emission_box_extents = Vector3(half_size.x, half_size.y, 0)
			mt.emission_shape_offset.y = -32
			
			# t = x/v
			var v := (mt.initial_velocity_min + mt.initial_velocity_max) / 2
			var x := rect.size.y
			_particles.lifetime = x / v
		1:
			mt.emission_sphere_radius = (rect.size.x + rect.size.y) / 4
			mt.radial_velocity_min = -suction_centralized * 1.5
			mt.radial_velocity_max = -suction_centralized * 1.25
	
	_particles.amount = maxi(int(roundf(rect.get_area() / 640)), 12)
	_particles.position = (shape_owner_get_owner(0) as CollisionShape2D).position
	_particles.process_material = mt
	
	enabled = enabled

func _physics_process(delta: float) -> void:
	for i in get_overlapping_bodies():
		if suction_mode == 0:
			var trans := global_transform.affine_inverse()
			var iposx := trans.basis_xform(i.global_position).x
			var posx := trans.basis_xform(global_position).x
			var ax := signf(posx - iposx)
			i.global_position += Vector2(ax * suction_horizontal, suction_vertical).rotated(global_rotation) * delta
		else:
			var v := i.global_position.direction_to(global_position).normalized() * suction_centralized * delta
			i.global_position += v
