To keep the consistence of the code, the following guides hereby should obey in order to maintain a good coding environment.

## `class_name`-d classes
You can use `class_name` to assign a global-accessible class; however, when this keyword is applied in a script inheriting `Node` or `Resource`, especially the former, you will see a new optioned selectable in their creating dialog. As such situation piles up, the dialog will be polluted; thus, we recommend not to overdepend on such keyword unless necessary, and it will give you an tidy and clean dialog to view.
We prefer to assign a `class_name` for such node that have significant application on general aspects, and omit it when a script is used only for few nodes.

## Type specification
To insist typed coding, we here requires that the typed coding should be always used, even if it comes a situation where the untyped should go into application:
- For variables assignment: use ```var a: TypeName = value```
- For functions assignment: use ```func method() -> TypeName/void```
- For parameters, see "for variables", without `var`
It's NOT RECOMMENDED to remove any spaces in previous examples.

However, as the typed coding gets taken, in some situation the type specification is not required:
- For local variables in a function, you can use ":=" if the right value is type-inferrable by the first sight of human.
- For arrays, misuse of the feature will cause error. For example, an array assigned with [] will throw an error when it is prefixed with ":=".
- When assigning a for loop, you needn't speficy the type for the loop variable `i`, `j`, `k`, etc..

The type specification can also be done by interring with ":=" plus for variables, and in such circumstance, a value should be given so that the inferring may work. However, we do not recommend to use such form since it may sometimes cause trouble with tracking issues.

## Private member
Since Godot does not support access attributes, we, according to what Godot advise us, here require each developer to use a underline "_" as the prefix of private member's name.

## Assignment order
In order to make a script clean and clear, here is a template about how to write a tidy script:
```GDScript
@icon/@tool/@static_unload
class_name <ClassName> extends <ParentClass>

enum SomeEnum {
	...,
	...,
	...
}

const A: Type = ...
const B: Type = ...
const C: Type = ...

@export_category("Category Name") // This is optional, but better when no class_name is titled.
@export var a: Type
@export var b: Type
@export_group("Group Name") // Optional, but better if you have to classification
@export var c: Type
@export var d: Type

var _a: Type // Private
var _b: Type

var c: Type // Public or protected
var d: Type

@onready _e: Type // Private
@onready _f: Type

@onready g: Type // Public or protected
@onready h: Type

@onready i: NodeType // Node getting
@onready j: Type // Node-related variable


func _init() -> void: // Built-in virtual methods
	pass

func _process(delta: float) -> void:
	pass


func some_func() -> void: // Public methods
	pass

func other_func() -> void:
	pass


func _private() -> void: // Private methods
	pass

func _private_2() -> void:
	pass


func set_xxx() -> void: // Setters and getters
	...

func get_xxx() -> void:
	...

func set_xxx_2() -> void:
	...

func get_xxx_2() -> void:
	...
```
And, if possible, we recommend to use code region to quote your codes with a general title about how your codes work for. 

## Setters and getters
Since 4.0, we can now make inline setters and getters. However, if possible, we prefer to put a large chunk of codes into a setter function or a getter function. While sometimes we can only have a setter or a getter, which is not limited but should be tidy enough.

## Single-line code in flow controlling
Though we can put the signle-line code into the same line as the control flow, like this one,
```GDScript
	if expression: return value
It's not advised, to be honest, since your monitor will cut off the words, which will lead to inconvenience when reading codes. Thus, we'd like to resort to this form:
	if expression:
		return value
```
The structure is clearer and more obvious than the previous one and your monitor will have tiny chance to hide the words out of the edge of screen.
However, sometimes this structure will lead to another problem that the structure will become another factor to pollute your script. To avoid it as possible as we can, we do not recommend to overuse such forms.

## Class inheritance
A programmer will hate class inheritance when the extending chain is so long as a Chinese loong. As their common, we here do not suggest you to depend on `extends` too much. Instead, if you have some common behaviors, you can pack them into a node as a component of other one.
In the template is provided a `Component` class for such usage.

## Proper use of `if`
See the following examples:
```GDScript
	if !expression:
		return
	<codes>
```
compared with
```GDScript
	if expression:
		<codes>
```
The first one will break ALL THE REST OF FUNCTION when the expression is false, while the second one won't.
So, if you have got into such a situation:
```GDScript
	if expression:
		<codes>
	# then nothing
```
though it's the same as the first example, sometimes, however, this would break the tidiness of your code. So if a codeblock only contains one if-condition, then why not reverse its condition? Compare these two examples:
I.
```GDScript
	if expression:
		<code1>
		<code2>
		...
		if another_expression:
			<codeA1>
			<codeA2>
			...
			if third_expression:
				<codeN+1>
				<codeN+2>
				...
```
II.
```GDScript
	if !expression:
		return/continue/break # Choose one that fits your situation
	<code1>
	<code2>
	...
	if another_expression:
		<codeA1>
		<codeA2>
	if !third_expression:
		return/continue/break
	...
	<codeN+1>
	<codeN+2>
	...
```
In conclusion, we prefer the second style in order to keep the cleaness and tidiness of the code structure.

## Safe lambda functions
Lambda functions, or lambdas, introduced in Godot 4.0, is a powerful tool during your coding. However, there are some situations that this tool may lead to problems.
Suppose the following situation where `body` is being deleted or has been removed:
```GDScript
(func() -> void:
	body.position += Vector2.RIGHT * 500
).call() # or .call_deferred()
```
In this situation, the body is actually a `null` value being passed in, and an error will be thrown:  
`Lambda captured a null index at...`
Owing to the lambda catching the static environment of a piece of code, we recommend a safer method:
(func(p: Node2D) -> void:
	p.position += Vector2.RIGHT * 500
).call(body) # or.call_deferred(body)
This will tell the executor that we have a param body to be passed in, but it found your param is a null value and will not lead to any execution. Therefore, no errors will be thrown.
Apart from this situation, you can use the first version as it's more simple and direct.
