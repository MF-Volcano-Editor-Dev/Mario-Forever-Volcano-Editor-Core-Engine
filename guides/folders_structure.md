# The Folders Structure
Each folder stores certain files that takes key part in the composition of the editor. Before your beginning of developing your game based on this editor, you must know the folders structure so that it can help you clearify the make sense of where the files are placed and why.
Here are the folders and their usage:
* addons: required by Godot, used to store addons so that they can be imported by and into Godot.
* assets: to store resources such as audio, video, fonts, gfx, etc. If you need to store node-highly-related resources, please place them in the same directory as that node (see some of the following rules).
* gdextension: required by Godot, used to store plugins coded by C++ called "GDExtension", which provides extra custom classes without "(.gd)" suffix. The editor uses the following GDExtensions: Effects2D, EntityBody2D, LibOpenMPT and Mathorm.
* guides: to store guide books in ".md" format.
* icons: to store custom Godot-styled icons for custom classes.
* objects: to store the game objects (majorly nodes and their resources). The detailed rules about this folder will be mentioned in the following context.
* scenes: to store the rooms of the game, including the stages, maps, menus, etc.
* shaders: to store shader files. Shaders, providing graphical modifications, suffixes with ".gdshader" or ".tres"(VisualShader) files.
* singletons: to store globally-used scripts and classes.

## About the naming of each folder:
To make the folder easily and clearly express their usage, we hereby define the rules of their naming:
* "#" or "##" is used to sign that the folder stores objects that cannot be directly placed in the scene editor.
* "@" is used to raise up the order of the folder to make it appear at the top of the directory.

## About `assets`
* fonts: to store font files.
* sounds: to store sound files.
* musics: to store music files.
* gfx: to store global graphics. About ones that used for certain nodes, please see the following context.

## About `icons`
The folder stores icons in Godot style with a suffix ".svg" which is a format of vector graph. Please make sure that each icon in this folder ends with that suffix to maintain their consistence.

## About `objects`
This folder is the key part of the editor with 4 following subfolders:
* #attachments: to store components that are directly attached to (a) certain type(s) of game room. For those who are used for game obejcts, please see "#components"
* #components: to store components used for game objects. These nodes are flexible and pluggable in the editor, so that they can make your development go with couplinglessness. DO NOT place the components for the game room here!
* #scripts: to store scripts that are used for a generic kind of game objects. Classes are stored in this folder.
* #scripts/nodes/hidden: to store hidden global classes. Hidden global classes are used to prevent `class_name`-d classes from displaying in the node from creating dialog in order to keep it clean and tidy. More details about it can be viewed in "hidden_classes.md".
* entities: to store game objects, such as the characters, the enemies, the bonuses and so on.
* uis: to store UIs like GUI and HUD.

## About `scenes`
This folder is used to store game rooms, but in the editor, there is only one subfolder `template` that used to store game rooms as your templates for your game development.
There is also a `start.tscn` that is used as the entrance of the application, so DO NOT REMOVE THIS FILE; otherwise the game will not be able to run as expected.
More details about the level files construction, please see "levels_building.md".

## About `singletons`
This folder is used to store the files of global classes.
* scripts: to store autoloaded scripts. About the autoloaded nodes and scripts, please see ["Singletons" in Godot Doc](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
* static_classes: as its name displays, it is used to store static classes. Currently you cannot declare a class as static; instead, you can assign the variables and methods as static to make the class seem to be static. Signals are not supported to be static yet.

## About format and structure of folders that stores nodes
Though you have learnt how the structure is formed, the more important thing is how to understand and maintain the structure of folders that contain nodes. Here we have some formats to achieve it:
> <folder_name> // This is usually the name of the key object
>> textures // Textures used for the key object and other related objects
>> scripts // Scripts used for the key object and other related objects
>> <resource_name>/resources // Resources, other than textures and scripts, used for the key object and other related objects
>> <key_node_name>.tscn // Key object
>> <related_node_name> // Folder to store related objects
>>> <related_node_name>.tscn // Related object
