class_name DialogueTrigger
extends Area2D
## TRIGGER DE DIÁLOGO CON IMÁGENES
## Script: scripts/components/dialogue_trigger.gd
## Cuando Aelia entra a la zona, muestra las imágenes del diálogo una por una.
## Se avanza con saltar (Espacio / X en PlayStation / A en Xbox).
##
## Uso en el nivel:
##   1. Agrega un Area2D a la altura del piso (la forma de colisión se crea sola).
##   2. Arrástrale este script.
##   3. En el Inspector, en "Images", agrega las imágenes en orden.

signal triggered(dialogue_id: String)
signal ended(dialogue_id: String)

@export var images: Array[Texture2D] = []   # las imágenes del diálogo, en orden
@export var dialogue_id := "dialogo_1"
@export var once := true                    # solo se muestra la primera vez
@export var pause_player := true            # Aelia no se mueve mientras se ve el diálogo
@export var size_tiles := Vector2(1, 8)     # tamaño de la zona en bloques (1 x 8 = toda la altura)
@export_range(0.3, 1.0) var screen_fill := 0.9   # qué tanto de la pantalla ocupa la imagen
@export var dim_background := 0.45          # oscurece el juego detrás (0 = nada)
@export var fade_time := 0.25

const TILE := 135.0

var _used := false
var _player: Node
var _layer: CanvasLayer
var _image: TextureRect
var _index := 0
var _active := false
var _can_advance := false


func _ready() -> void:
	add_to_group("dialogue_trigger")
	if find_children("*", "CollisionShape2D", false, false).is_empty():
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = size_tiles * TILE
		col.shape = shape
		col.position = Vector2(size_tiles.x * TILE / 2.0, -size_tiles.y * TILE / 2.0)
		add_child(col)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _active or (once and _used) or not body.has_method("activate_checkpoint"):
		return
	_used = true
	_player = body
	print("[Diálogo] Aelia activó: ", dialogue_id)
	triggered.emit(dialogue_id)
	get_tree().call_group("dialogue", "start_dialogue", dialogue_id)
	if images.is_empty():
		return  # sin imágenes: solo avisa
	if pause_player:
		body.set_physics_process(false)
		var spr := body.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if spr and spr.sprite_frames and spr.sprite_frames.has_animation("idle"):
			spr.play("idle")
	_open()


func _open() -> void:
	_active = true
	_index = 0
	_layer = CanvasLayer.new()
	_layer.layer = 10
	add_child(_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, dim_background)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(dim)
	_image = TextureRect.new()
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var m := (1.0 - screen_fill) / 2.0
	_image.anchor_left = m
	_image.anchor_top = m
	_image.anchor_right = 1.0 - m
	_image.anchor_bottom = 1.0 - m
	_layer.add_child(_image)
	_show_image()


func _show_image() -> void:
	_image.texture = images[_index]
	_image.modulate.a = 0.0
	_can_advance = false
	var tw := create_tween()
	tw.tween_property(_image, "modulate:a", 1.0, fade_time)
	tw.tween_callback(func() -> void: _can_advance = true)


func _process(_delta: float) -> void:
	if not _active or not _can_advance:
		return
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		if _index + 1 < images.size():
			_index += 1
			_show_image()
		else:
			_close()


func _close() -> void:
	_active = false
	var tw := create_tween()
	tw.tween_property(_image, "modulate:a", 0.0, fade_time)
	await tw.finished
	_layer.queue_free()
	# espera a que suelte el botón para que Aelia no salte sola al terminar
	while Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept"):
		await get_tree().process_frame
	end_dialogue()


## Libera a Aelia (también lo puede llamar otro sistema si no usa imágenes)
func end_dialogue() -> void:
	if _player and is_instance_valid(_player) and not _player.is_physics_processing():
		_player.set_physics_process(true)
	ended.emit(dialogue_id)
