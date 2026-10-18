class_name MovingPlatform
extends AnimatableBody2D
## PLATAFORMA QUE SE MUEVE (horizontal o vertical), de ida y vuelta.
## Script: scripts/components/moving_platform.gd
## El origen es la esquina superior izquierda de la plataforma.
## move_tiles: hacia dónde y cuántos bloques se mueve.
##   Horizontal 5 a la derecha: (5, 0) · Vertical 4 hacia arriba: (0, -4)

const TILE := 135.0

@export var width_tiles := 3
@export var move_tiles := Vector2(5, 0)
@export var cycle_time := 4.0          # segundos en ir y volver
@export var start_offset := 0.0        # 0 a 1: en qué punto del recorrido empieza
@export var texture: Texture2D   # vacío = usa assets/art/environment/block.png
@export var tint := Color(1.0, 0.85, 0.6)       # blanco = sin tinte
@export var height_tiles := 1

var _start := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	sync_to_physics = true
	_start = position
	_t = start_offset * cycle_time
	var size := Vector2(width_tiles, height_tiles) * TILE
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = size / 2.0
	add_child(col)
	_make_look(size)


func _physics_process(delta: float) -> void:
	_t += delta
	var k := (1.0 - cos(_t / cycle_time * TAU)) / 2.0  # va de 0 a 1 y regresa, suave
	position = _start + move_tiles * TILE * k


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
