@tool
class_name AreaSection extends Control

## A rectangle area used as a section for a scene. Musics and sections are managed by this object.
##
##

## If [code]true[/code], the whole scene belongs to this section.
@export var section_full_screen: bool = true
## Title of the section
@export_placeholder("Section name...") var section_title: String
## Color of rectangle sides in preview mode
@export var section_color: Color = Color.DEEP_PINK
@export_group("Music", "music_")
## Music of the section
@export var music: AudioStream
## Channel of [member music]
@export_range(0, 1, 1, "or_greater") var music_channel: int
## Basic volume of [member music]
@export_range(-50, 50, 0.001, "suffix:dB") var music_volume: float
## Flags that decides which behavior may trigger music fading.
@export_flags("On Entering", "On Exiting") var music_fadable: int = 0b11
## Volume of [member music] faded out.
@export_range(-50, 50, 0.001, "suffix:dB") var music_volume_faded: float = -50
## Fading duration of [member music]
@export_range(0, 30, 0.001, "suffix:s") var music_fading_duration: float = 1
## If [code]true[/code], the music will stop after fading out/in.
@export var music_stops_after_fading: bool
## If [code]true[/code], the music may play globally.[br]
## [br]
## [b]Caution:[/b] You may need to manually control the global music. See [Music] for more details.
@export var music_global: bool

var _initial_delay: int = 6
var _music_player: AudioStreamPlayer

var _average_character_gpos: Vector2
var _has_characters: bool:
	set = set_has_characters


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if section_full_screen:
		_has_characters = true
	
	while _initial_delay > 0:
		_initial_delay -= 1
		await get_tree().process_frame

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), section_color, false, 4)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if section_full_screen:
		return
	
	var tree := get_tree()
	var no_characters := Character.Getter.get_characters(tree).is_empty()
	_average_character_gpos = Character.Getter.get_average_global_position(tree, _average_character_gpos)
	_has_characters = !no_characters && get_rect().has_point(_average_character_gpos)


func set_has_characters(value: bool) -> void:
	if Engine.is_editor_hint():
		return
	
	var old := _has_characters
	_has_characters = value
	
	if old != _has_characters:
		# On Entering
		if _has_characters:
			if music:
				# Initialization for new music player
				if !is_instance_valid(_music_player):
					_music_player = Music.play(get_tree(), music, music_channel, DataList.AudioMode.GLOBAL if music_global else DataList.AudioMode.SCENIAL)
				
				if !_initial_delay && music_fadable & 1:
					_music_player.volume_db = music_volume_faded
					Music.fade(_music_player, music_volume, music_fading_duration, music_stops_after_fading)
				else:
					_music_player.volume_db = music_volume
		# On Exiting
		elif is_instance_valid(_music_player):
			if !_initial_delay && (music_fadable >> 1) & 1:
				Music.fade(_music_player, music_volume_faded, music_fading_duration, music_stops_after_fading)
			else:
				_music_player.volume_db = music_volume_faded
