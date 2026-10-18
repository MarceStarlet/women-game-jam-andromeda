class_name DisappearingPlatform
extends StaticBody2D
## PLATAFORMA QUE DESAPARECE después de pisarla una vez.
## Script: scripts/components/disappearing_platform.gd
## El origen es la esquina superior izquierda. Reaparece si Aelia muere,
## para que nunca se quede atorada.

const TILE := 135.0

@export var width_tiles := 2
@export var delay := 0.5               # segundos entre pisarla y desaparecer
@export var texture: Texture2D   # vacío = usa assets/art/environment/block.png
@export var tint := Color(0.7, 1.0, 0.8)        # blanco = sin tinte
@export var height_tiles := 1

var _used := false
var _token := 0
var _col: CollisionShape2D
var _rect: Control


func _ready() -> void:
	var size := Vector2(width_tiles, height_tiles) * TILE
	_col = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	_col.shape = shape
	_col.position = size / 2.0
	add_child(_col)
	_rect = _make_look(size)
	# Sensor delgado sobre la plataforma para saber cuándo la pisan
	var sensor := Area2D.new()
	var sc := CollisionShape2D.new()
	var ss := RectangleShape2D.new()
	ss.size = Vector2(size.x - 10.0, 12.0)
	sc.shape = ss
	sc.position = Vector2(size.x / 2.0, -6.0)
	sensor.add_child(sc)
	add_child(sensor)
	sensor.body_entered.connect(_on_stepped)


func _on_stepped(body: Node2D) -> void:
	if _used or not body.has_signal("died"):
		return
	if not body.died.is_connected(_reset):
		body.died.connect(_reset)
	_used = true
	_token += 1
	var my_token := _token
	var tw := create_tween().set_loops(3)  # parpadea como aviso
	tw.tween_property(_rect, "modulate:a", 0.3, delay / 6.0)
	tw.tween_property(_rect, "modulate:a", 1.0, delay / 6.0)
	await get_tree().create_timer(delay).timeout
	if my_token == _token and _used:
		_set_solid(false)


func _set_solid(on: bool) -> void:
	_col.set_deferred("disabled", not on)
	_rect.visible = on
	_rect.modulate.a = 1.0


func _reset() -> void:
	_used = false
	_token += 1
	_set_solid(true)


const BLOCK_PATH := "res://assets/art/environment/block.png"


## Crea el dibujo: tu bloque repetido por unidad, o un color si no encuentra la imagen
func _make_look(size: Vector2) -> Control:
	if texture == null and ResourceLoader.exists(BLOCK_PATH):
		texture = load(BLOCK_PATH)
	var look: Control
	if texture:
		var tex_rect := TextureRect.new()
		tex_rect.texture = texture
		tex_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tex_rect.stretch_mode = TextureRect.STRETCH_TILE
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.self_modulate = tint
		look = tex_rect
	else:
		var cr := ColorRect.new()
		cr.color = tint
		look = cr
	look.size = size
	add_child(look)
	return look
