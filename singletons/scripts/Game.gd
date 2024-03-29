extends Node


func _init() -> void:
	if ProjectSettings.get_setting("game/performance/use_double_fps", true):
		print("[Performance] Double FPS system is activated!")
		
		var fps := ceili(DisplayServer.screen_get_refresh_rate())
		if fps < 119:
			print("[Performance] Your device is run in low rate! Double FPS mode is now on to ensure your smooth gameplay!")
			Engine.physics_ticks_per_second = 120
		else:
			Engine.physics_ticks_per_second = fps
	
	# Minimum window dimensions
	DisplayServer.window_set_min_size(Vector2i(640, 480))
	
	# Default background in-game to solid black
	RenderingServer.set_default_clear_color(Color.BLACK)
