extends Combo

@export_category("Mario Starman")
@export_node_path("MarioPowerup") var powerup_path: NodePath = ^"../.."
@export_node_path("AnimatedSprite2D") var animated_sprite_path: NodePath = ^"../../AnimatedSprite2D"
@export_node_path("Attacker") var attacker_path: NodePath = ^"../Attacker"
@export var sprite_shader: Shader = preload("res://engine/shaders/hsv.gdshader")

var _shader_material: ShaderMaterial

var _hue_v: float:
	set(value):
		_hue_v = wrapf(value, -1, 1)

@onready var _powerup: MarioPowerup = get_node(powerup_path)
@onready var _character: Mario = _powerup.get_character()
@onready var _animated_sprite: AnimatedSprite2D = get_node(animated_sprite_path)
@onready var _attacker: Attacker = get_node(attacker_path)

@onready var _sprite_shader: Shader = sprite_shader.duplicate()

func _ready() -> void:
	set_process(enabled)
	
	_character.on_starman.connect(func(duration: float) -> void:
		enabled = true
		_animated_sprite.material = ShaderMaterial.new()
		_attacker.id = DataList.AttackId.STARMAN
		set_process(enabled)
		
		_shader_material = _animated_sprite.material as ShaderMaterial # Shader material
		_shader_material.shader = _sprite_shader
		
		await get_tree().create_timer(duration, false).timeout
		
		enabled = false
		_animated_sprite.material = null
		_attacker.id = DataList.AttackId.NONE
		set_process(enabled)
	)

func _process(delta: float) -> void:
	_hue_v += 2.5 * delta
	_shader_material.set_shader_parameter(&"hue", _hue_v)
