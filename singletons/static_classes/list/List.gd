class_name DataList

## Static class used to provide lists of data for other classes or codes.
##
## [b]Technical:[/b] Since enum is equal to [code]const Enum: Dictionary = {}[/code], you may try modify this property externally.

## Id of attack by [Attackers].[br]
enum AttackId {
	NONE,
	FORCED,
	HEAD,
	STARMAN,
	SHELL,
	FIREBALL,
	BEETROOT,
	HAMMER,
}

## The mode of playing a sound.[br]
## [br]
## [b]Note:[/b] Since the sounds are played via [AudioStreamPlayer]*, which is a kind of [Node],
## the position of the sound player decides the behavior of it. 
enum AudioMode {
	AS_CHILD, ## The sound player will be added as the child node of one that gets the sound wanted to play (The [b]owner[/b] of the sound player).[br][b]Note:[/b] If the owner gets removed or deleted, the sound player will be done so as well and the sound will break playing.
	SCENIAL, ## The sound player will be added as the child node of the [u]current scene[/u] of the scene tree. This won't break the playing of the sound even if the owner of the sound player gets removed or deleted.
	GLOBAL ## The sound player will be added as the child node of the [u]root[/u] of the scene tree. This won't break the playing of the sound even if the owner of the sound player gets removed or deleted, or the current scene gets changed.
}
