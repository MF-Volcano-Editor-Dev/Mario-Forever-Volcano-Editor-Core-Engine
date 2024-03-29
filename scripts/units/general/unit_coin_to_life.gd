extends Node

const _Lives := preload("res://engine/objects/uis/counters/lives_label.tscn")

@export_category("Coin to Lives")
## The amount of coins that can be converted to [member bonus_lives]
@export_range(1, 10000) var bonus_line: int = 100
## Lives given as bonus
@export_range(0, 100) var bonus_lives: int = 1
@export_group("Sounds", "sound_")
@export var sound_life_up_fallback: AudioStream = preload("res://engine/assets/sounds/life_up.wav")


func _ready() -> void:
	Character.Data.get_signals().data_updated.connect(func(type: Character.Data.DataSignal.Value, value: int) -> void:
		if type == Character.Data.DataSignal.Value.COINS:
			var coins := value
			var given_lives := 0
			
			if coins >= bonus_line:
				while coins >= bonus_line:
					coins -= bonus_line
					given_lives += bonus_lives
				
				Character.Data.coins = coins
			
				var character := Character.Getter.get_random(get_tree(), 1)[0]
				if is_instance_valid(character):
					var lives := _Lives.instantiate()
					lives.amount = given_lives
					lives.global_position = character.global_position
					character.add_sibling.call_deferred(lives)
				else:
					Character.Data.lives += given_lives
				
				Sound.play_1d(sound_life_up_fallback, self)
	)
