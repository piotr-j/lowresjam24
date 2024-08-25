extends Node2D

@export var player: PlayerCls

# https://opengameart.org/content/5-free-tracks-for-your-game-8-bit-style-0
# mysic by: pinknoisemusic
@onready var music: AudioStreamPlayer2D = $AudioMusic
@onready var music_combat: AudioStreamPlayer2D = $AudioMusicCombat
@onready var music_player: AnimationPlayer = $MusicPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if player:
		player.aggro_gained.connect(on_player_aggro_gained)
		player.aggro_lost.connect(on_player_aggro_lost)
	
	# play regular music?
	music_player.play("play_base_music")

#var is_in_combat := false
#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("jump"):
		#is_in_combat = !is_in_combat
		#if is_in_combat:
			#on_player_aggro_gained()
		#else:
			#on_player_aggro_lost()

func on_player_aggro_gained() -> void:
	#print('aggro gained!')
	music_player.play("play_aggro_music")
	
func on_player_aggro_lost() -> void:
	#print('aggro lost!')
	music_player.play("play_base_music")
