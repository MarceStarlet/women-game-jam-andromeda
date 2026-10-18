class_name Crusher
extends AnimatableBody2D
## PLATAFORMA QUE APLASTA: baja de golpe, espera, y sube despacio.
## Script: scripts/components/crusher.gd
## El origen es la esquina superior izquierda en su posición de arriba.
## Si cae sobre Aelia, ella muere y reaparece en el último checkpoint.
## Para hacer patrones, den distinto start_delay a cada una.

const TILE := 135.0

enum State { WAIT_UP, FALL, WAIT_DOWN, RISE }

@export var width_tiles := 1
@export var height_tiles := 1
@export var drop_tiles := 3.0
@export var wait_up := 1.5
@export var wait_down := 0.6
@export var fall_speed := 12.0 * TILE
@export var rise_speed := 3.0 * TILE
@export var start_delay := 0.0
@export var texture: Texture2D   # vacío = usa assets/art/environment/block.png
@export var tint := Color(0.85, 0.7, 1.0)       # blanco = sin tinte

var state := State.WAIT_UP
var _timer := 0.0
var _top := Vector2.ZERO
var _kill: Area2D
var _killed := false  # para matar una sola vez por caída


func _ready() -> void:
	sync_to_physics = true
	_top = position
	_timer = wait_up + start_delay
	var size := Vector2(width_tiles, height_tiles) * TILE
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = size / 2.0
	add_child(col)
	_make_look(size)
	# Zona mortal justo debajo
	_kill = Area2D.new()
	var kc := CollisionShape2D.new()
	var ks := RectangleShape2D.new()
	ks.size = Vector2(size.x - 16.0, 24.0)
	kc.shape = ks
	kc.position = Vector2(size.x / 2.0, size.y + 8.0)
	_kill.add_child(kc)
	add_child(_kill)


func _physics_process(delta: float) -> void:
	var bottom := _top + Vector2(0, drop_tiles * TILE)
	match state:
		State.WAIT_UP:
			_timer -= delta
			if _timer <= 0.0:
				state = State.FALL
				_killed = false
		State.FALL:
			position.y = move_toward(position.y, bottom.y, fall_speed * delta)
			if not _killed:
				for body in _kill.get_overlapping_bodies():
					if body.has_method("die"):
						_killed = true
						body.die()
						break
			if is_equal_approx(position.y, bottom.y):
				state = State.WAIT_DOWN
				_timer = wait_down
		State.WAIT_DOWN:
			_timer -= delta
			if _timer <= 0.0:
				state = State.RISE
		State.RISE:
			position.y = move_toward(position.y, _top.y, rise_speed * delta)
			if is_equal_approx(position.y, _top.y):
				state = State.WAIT_UP
				_timer = wait_up


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
