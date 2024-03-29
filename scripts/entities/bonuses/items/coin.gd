extends Area2D

signal coin_got ## Emitted when the coin is got by a character.
signal coin_hit ## Emitted when the coin is hit (out).

@export_category("Coin")
@export_range(-9999, 9999) var amount: int = 1
@export_range(-1, 1, 1, "or_less", "or_greater") var scores: int = 200
@export_group("Sounds", "sound_")
@export var sound_coin: AudioStream = preload("res://engine/assets/sounds/coin.wav")

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body is Character:
			_coin()
			coin_got.emit()
	)


func _coin() -> void:
	Sound.play_2d(sound_coin, self)
	Character.Data.coins += amount
	Character.Data.scores += scores


## Called by [BumpBlock2D].
## @deprecated
func hit(_block: BumpBlock2D) -> void:
	_coin()
	
	_animated_sprite.play(&"hit")
	
	collision_layer = 0
	collision_mask = 0
	
	Sound.play_2d(sound_coin, self)
	
	var up := Vector2.UP.rotated(rotation)
	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, ^"position", position + 96 * up, 0.25)
	tw.tween_property(self, ^"position", position + 64 * up, 0.25).set_ease(Tween.EASE_IN)
	
	await tw.finished
	coin_hit.emit()
