extends CanvasLayer

@export_category("LevelHUD")
@export_group("Sounds", "sound_")
@export var sound_game_over: AudioStream = preload("res://engine/assets/sounds/game_over.ogg")

@onready var frame: Control = $Frame
@onready var player_name: Label = $Frame/PlayerName
@onready var lives: Label = $Frame/PlayerName/X/Lives
@onready var scores: Label = $Frame/PlayerName/X/Lives/Scores
@onready var coins: Label = $Frame/CoinX/Coins
@onready var game_over: Label = $GameOver


func _ready() -> void:
	Character.Data.get_signals().data_updated.connect(func(type: Character.Data.DataSignal.Value, value: Variant) -> void:
		match type:
			Character.Data.DataSignal.Value.LIVES:
				const DEFAULT: StringName = &"PLAYER"
				
				@warning_ignore("incompatible_ternary")
				player_name.text = (DEFAULT if Character.Getter.get_characters(get_tree()).is_empty() else Character.Getter.get_character(get_tree(), 0).nickname.to_upper()).left(8)
				
				lives.text = str(value)
			Character.Data.DataSignal.Value.SCORES:
				scores.text = str(value)
			Character.Data.DataSignal.Value.COINS:
				coins.text = str(value)
	, CONNECT_DEFERRED)
	
	Events.EventCharacter.get_signals().game_over.connect(func() -> void:
		game_over.visible = true
		
		await Sound.play_1d(sound_game_over, self).finished
		await get_tree().create_timer(1, false).timeout
		
		# TODO: After-game-over executions
	)
	
	Character.Data.init_data()
