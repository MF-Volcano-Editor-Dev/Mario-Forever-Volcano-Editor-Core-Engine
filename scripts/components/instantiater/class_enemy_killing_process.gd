class_name EnemyAttackProcess2D extends Instantiater2D

## Used together with [EnemyStompable] and/or [Attackee] to provide instances creation for it.[br]
## 
## This component will instantiate objects based on [member root]. When a character stomps on
## [br]
## [b]Note:[/b] This works only when [signal Attackee.on_hit_by_attacker] is connected to [method killing_process].[br]

signal stomp_processed ## Emitted when the stomp is processed.
signal killing_processed ## Emitted when the killing is processed.
signal killing_succeeded ## Emitted when the killing process is successful.
signal killing_defended ## Emitted when the killing process is defended.

const _FilteringGroups: Dictionary = {
	NO_STOMP = &"instantiate_no_stomp",
	NO_ATTACK = &"instantiate_no_attack",
	ATTACK_NO_FAILURE = &"instantiate_no_failure",
	ATTACK_NO_SUCCESS = &"instantiate_no_success",
	ATTACK_SUCCESS_NO_COMBO = &"instantiate_no_success_combo"
}

@export_group("Stomp")
## Jumping speed of the character stomping onto the enemy without the jumping key being held.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var stomp_jumping_speed_min: float = 400
## Jumping speed of the character stomping onto the enemy with the jumping key being held.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var stomp_jumping_speed_max: float = 700
## Make the enemy immune to the attackers with given ids in the list.[br]
## When an attacker in the list try damaging the enemy, the attack will be defended and [signal killing_defended] will be emitted.
@export_group("Attack")
## [Attacker]s with [mmeber Attacker.id] in this list will be blocked and the attack fails.
@export var immune_to_ids: Array[DataList.AttackId]
## Lower than this value, the damage by an [Attacker] will be regarded as failed one.
@export_range(0, 20) var defense_damage_level: int
@export_group("Sounds", "sound_")
@export var sound_killed: AudioStream = preload("res://engine/assets/sounds/kick.wav")
@export var sound_killing_defended: AudioStream = preload("res://engine/assets/sounds/bump.wav")


## Called to process stomp and instantiate relevant objects.[br]
## [br]
## [b]Note 1:[/b] Please connect [signal EnemyStompable.on_stomp_succeeded] to this call.
## [b]Note 2:[/b] For instances not to be created on failed attack, please merge them in the group [code]instantiate_no_stomp[/code].
func stomp_process(body: PhysicsBody2D) -> void:
	if !is_instance_valid(body):
		return
	
	if body is Character:
		var jumping_speed: float = stomp_jumping_speed_max if body.get_input_pressed(&"jump") else stomp_jumping_speed_min
		body.jump(jumping_speed)
	
	instantiate_all(false, [_FilteringGroups.NO_STOMP])
	
	stomp_processed.emit()

## Called to process killing and instantiate relevant objects.[br]
## [br]
## [b]Note 1:[/b] Please connect [signal EnemyStompable.on_stomp_succeeded] to this call.[br]
## [b]Note 2:[/b][br]
## For instances not to be created on failed attack, please merge them in the group [code]instantiate_no_success[/code].[br]
## And for ones not to be created on successful attack, please merge them in the group [code]instantiate_no_failure[/code].[br]
## For ones not to be created on successful attack by attacker who is in the group [code]combo[/code], please merge them in the group [code]instantiate_no_success_combo[/code].[br]
## Meanwhile, for ones not to be created on stomping, please merge them in the group [code]instantiate_no_attack[/code].
func killing_process(attacker: Attacker) -> void:
	killing_processed.emit()
	
	var filters: Array[StringName] = [_FilteringGroups.NO_ATTACK]
	var instances: Array[CanvasItem] = []
	
	if attacker.id == DataList.AttackId.NONE || \
		(attacker.id != DataList.AttackId.FORCED && (attacker.id in immune_to_ids || attacker.damage_level < defense_damage_level)):
			Sound.play_2d(sound_killing_defended, self)
			
			filters.append(_FilteringGroups.ATTACK_NO_FAILURE)
			instances = instantiate_all(false, filters)
			
			killing_defended.emit()
			attacker.attack_failed.emit()
	else:
		var is_combo: = false
		
		filters.append(_FilteringGroups.ATTACK_NO_SUCCESS)
		if attacker.is_in_group(&"combo"):
			is_combo = true
			filters.append(_FilteringGroups.ATTACK_SUCCESS_NO_COMBO)
		
		if !is_combo:
			Sound.play_2d(sound_killed, self)
		
		instances = instantiate_all(false, filters)
		
		killing_succeeded.emit()
		attacker.attack_succeeded.emit()
	
	# Removes filtering groups from the instances
	for i in instances:
		if !is_instance_valid(i): # Prevent from immediate deletion that caused unexpected `null` value
			continue
		for j in _FilteringGroups:
			i.remove_from_group(j)

## Forces the enemy to be killed.
func forced_kill(combo: bool = false) -> void:
	var attacker: Attacker = Attacker.new()
	attacker.id = DataList.AttackId.FORCED
	
	if combo:
		attacker.add_to_group(&"combo")
	
	killing_process(attacker)
	attacker.free()
