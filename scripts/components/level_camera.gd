class_name LevelCamera
extends Camera2D
## CÁMARA QUE SIGUE A AELIA
## Script: scripts/components/level_camera.gd  (va en el Camera2D dentro de Player)
## - Siempre se ven 8 bloques de alto, en cualquier tamaño de pantalla.
## - Sigue a Aelia a lo ancho y a lo alto.
## - El piso donde está parada queda abajo de la pantalla, con 1 bloque de margen.
## - Al saltar no se mueve de arriba a abajo; solo cuando llega a otro piso o cae.
## - Opcional: use_limits + map_rect para no mostrar nada fuera del mapa.

const TILE := 135.0

@export var view_height_tiles := 8.0      # bloques de alto visibles
@export var ground_margin_tiles := 1.0    # bloques visibles debajo de los pies
@export var follow_speed := 6.0
@export var use_limits := false
@export var map_rect := Rect2(0, 0, 42 * TILE, 80 * TILE)  # x, y, ancho, alto del mapa
@export var force_current := true         # si otra cámara intenta ganar, esta la recupera

var target: CharacterBody2D
var _ground_y := 0.0


func _ready() -> void:
	top_level = true  # no hereda el movimiento del jugador; lo controlamos aquí
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false
	target = _find_target()
	if target == null:
		push_warning("LevelCamera: no encontré a Aelia. Pon este Camera2D dentro del nodo Player.")
		return
	get_viewport().size_changed.connect(_fit_zoom)
	_fit_zoom()
	_ground_y = target.global_position.y
	global_position = _goal()
	make_current()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	if force_current and not is_current():
		make_current()
	var feet := target.global_position.y
	if target.is_on_floor() or feet > _ground_y + TILE:
		_ground_y = feet  # nuevo piso, o va cayendo por debajo del anterior
	var goal := _goal()
	if global_position.distance_to(goal) > view_height_tiles * TILE * 1.5:
		global_position = goal  # reaparición: salta directo, sin barrido largo
		return
	var k := clampf(follow_speed * delta, 0.0, 1.0)
	global_position.x = lerpf(global_position.x, goal.x, clampf(k * 2.0, 0.0, 1.0))
	global_position.y = lerpf(global_position.y, goal.y, k)


## Busca al personaje: primero hacia arriba (padre, abuelo...), luego en toda la escena
func _find_target() -> CharacterBody2D:
	var n := get_parent()
	while n != null:
		if n is CharacterBody2D:
			return n
		n = n.get_parent()
	for node in get_tree().get_nodes_in_group("player"):
		if node is CharacterBody2D:
			return node
	var found := get_tree().root.find_children("*", "CharacterBody2D", true, false)
	return found[0] as CharacterBody2D if found.size() > 0 else null


func _goal() -> Vector2:
	var view := get_viewport_rect().size / zoom
	var goal := Vector2(target.global_position.x,
			_ground_y + ground_margin_tiles * TILE - view.y / 2.0)
	if use_limits:
		goal.x = _clamp_axis(goal.x, map_rect.position.x, map_rect.end.x, view.x / 2.0)
		goal.y = _clamp_axis(goal.y, map_rect.position.y, map_rect.end.y, view.y / 2.0)
	return goal


func _clamp_axis(v: float, lo: float, hi: float, half: float) -> float:
	if hi - lo <= half * 2.0:
		return (lo + hi) / 2.0
	return clampf(v, lo + half, hi - half)


func _fit_zoom() -> void:
	var h := get_viewport_rect().size.y
	zoom = Vector2.ONE * (h / (view_height_tiles * TILE))
