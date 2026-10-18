class_name LevelCamera
extends Camera2D
## CÁMARA DEL JUEGO (va en el Camera2D dentro de Player; una sola para todo el juego)
## Script: scripts/components/level_camera.gd
##
## Siempre se ve un área de 1920 x 1080 px del mundo (8 bloques de alto),
## en cualquier tamaño de ventana.
##
## Modos (se eligen en el Inspector, propiedad "Mode"):
##   FOLLOW_LEVEL (por defecto): sigue a Aelia de izquierda a derecha y siempre
##       muestra la altura completa del nivel donde está (los 8 bloques).
##   SCREENS: el nivel se parte en 3 tercios de 14 bloques; la cámara se queda
##       quieta en el tercio de Aelia y se desliza cuando cruza al siguiente.
##   FOLLOW: sigue a Aelia libremente (también en vertical).

enum Mode { FOLLOW_LEVEL, SCREENS, FOLLOW }

const TILE := 135.0

@export var mode := Mode.FOLLOW_LEVEL
@export var level_tiles := Vector2(42, 8)     # tamaño de cada nivel, en bloques
@export var screen_tiles := Vector2(14, 8)    # tamaño de cada tercio, en bloques
@export var map_origin := Vector2.ZERO        # esquina superior izquierda del mapa
@export var auto_align := true                # alinea los niveles con el piso donde Aelia aterriza al empezar
@export var clamp_x := false                  # no pasar de la orilla izq/der del nivel (necesita map_origin.x correcto)
@export var transition_speed := 8.0           # qué tan rápido cambia de nivel / tercio
@export var follow_speed := 8.0               # qué tan rápido sigue a Aelia en horizontal
@export var disable_other_cameras := true     # apaga cualquier otra Camera2D de la escena
@export var print_info := true                # escribe en "Salida" lo que hace la cámara

@export_group("Modo FOLLOW")
@export var ground_margin_tiles := 1.0
@export var use_limits := false
@export var map_rect := Rect2(0, 0, 42 * TILE, 80 * TILE)

var target: CharacterBody2D
var _ground_y := 0.0
var _snap := false   # al reaparecer, la cámara salta directo en vez de deslizarse
var _last_band := Vector2i(999999, 999999)
var _aligned := false
var _levels: Array[Node2D] = []   # nodos Level1, Level2... encontrados en la escena
var _cur_level: Node2D
var _start_y := 0.0
var _fall_warned := false


func _ready() -> void:
	top_level = true  # no hereda el movimiento del jugador; lo controlamos aquí
	enabled = true
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false
	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000
	target = _find_target()
	if target == null:
		push_warning("LevelCamera: no encontré a Aelia. Pon este Camera2D dentro del nodo Player.")
		return
	get_viewport().size_changed.connect(_fit_zoom)
	_fit_zoom()
	_ground_y = target.global_position.y
	if target.has_signal("died"):
		target.died.connect(func() -> void: _snap = true)
	global_position = _goal()
	make_current()
	_disable_others.call_deferred()
	_find_levels.call_deferred()
	_check_window()
	_start_y = target.global_position.y
	_log("lista. Sigue a '%s', modo %s, ventana %s, zoom %.2f" % [
			target.name, Mode.keys()[mode], get_viewport_rect().size, zoom.x])


## Busca los niveles de la escena: nodos llamados Level1, Level2, level_3... o instancias
## de scenes/levels/level_X.tscn. Su posición es la esquina superior izquierda del nivel.
func _find_levels() -> void:
	_levels.clear()
	var re := RegEx.create_from_string("^(?i)level[ _]?\\d+$")
	for n in get_tree().root.find_children("*", "Node2D", true, false):
		var n2 := n as Node2D
		if n2.is_ancestor_of(self):
			continue
		var by_name := re.search(str(n2.name)) != null
		var by_file := n2.scene_file_path.get_file().begins_with("level_")
		if by_name or by_file:
			_levels.append(n2)
	if _levels.size() > 0:
		_log("encontré %d niveles: %s" % [_levels.size(), ", ".join(_levels.map(func(l: Node2D) -> String: return "%s (y=%.0f)" % [l.name, l.global_position.y]))])
	else:
		_log("no encontré nodos Level: uso el piso donde empieza Aelia para alinear.")


func _level_rect(l: Node2D) -> Rect2:
	return Rect2(l.global_position, level_tiles * TILE * l.global_scale)


func _level_of_target() -> Node2D:
	var c := _body_center()
	var best: Node2D = null
	var best_d := INF
	for l in _levels:
		if not is_instance_valid(l):
			continue
		var r := _level_rect(l)
		var d := 0.0 if (c.y >= r.position.y and c.y < r.end.y) else minf(absf(c.y - r.position.y), absf(c.y - r.end.y))
		if d == 0.0 and (c.x < r.position.x - TILE or c.x > r.end.x + TILE):
			d = 0.5  # misma altura pero fuera a los lados: preferir otro si lo hay
		if d < best_d:
			best_d = d
			best = l
	return best


func _check_window() -> void:
	var v := get_viewport_rect().size
	if absf(v.x / v.y - 16.0 / 9.0) > 0.05:
		push_warning("LevelCamera: la ventana mide %s y debería ser 16:9 (1920 x 1080). Ve a Proyecto > Configuración del Proyecto > Display > Window y pon Viewport Width = 1920, Viewport Height = 1080." % v)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	if not is_current():
		var other := get_viewport().get_camera_2d()
		_log("otra cámara estaba activa: %s. La apago." % (str(other.get_path()) if other else "ninguna"))
		if other and other != self and disable_other_cameras:
			other.enabled = false
		make_current()
	var feet := target.global_position.y
	if not _aligned and not _fall_warned and target.global_position.y > _start_y + 3000.0:
		_fall_warned = true
		push_warning("LevelCamera: Aelia cayó más de 3000 px sin tocar piso. ¿Empieza dentro o debajo del piso? Súbela para que sus pies queden ARRIBA del primer bloque.")
	if auto_align and not _aligned and target.is_on_floor():
		# Aelia empieza parada en el piso (fila de abajo) de un nivel: de ahí sale la cuadrícula
		_aligned = true
		map_origin.y = fposmod(feet + TILE, level_tiles.y * TILE)
		_log("alineada al piso de inicio (y = %.0f). Cada nivel mide %.0f px de alto." % [feet, level_tiles.y * TILE])
	if target.is_on_floor() or feet > _ground_y + TILE:
		_ground_y = feet
	if _snap:
		_snap = false
		_ground_y = target.global_position.y
		global_position = _goal()  # reaparición: salta directo al checkpoint
		return
	var goal := _goal()
	var k_x := clampf((follow_speed if mode != Mode.SCREENS else transition_speed) * delta, 0.0, 1.0)
	var k_y := clampf((follow_speed if mode == Mode.FOLLOW else transition_speed) * delta, 0.0, 1.0)
	global_position.x = lerpf(global_position.x, goal.x, k_x)
	global_position.y = lerpf(global_position.y, goal.y, k_y)


## Nivel (y tercio) donde está Aelia, contando desde map_origin
func current_screen() -> Vector2i:
	var cell := screen_tiles * TILE
	var rel := _body_center() - map_origin
	return Vector2i(floori(rel.x / cell.x), floori(rel.y / cell.y))


func current_level_row() -> int:
	return floori((_body_center().y - map_origin.y) / (level_tiles.y * TILE))


func _body_center() -> Vector2:
	return target.global_position - Vector2(0, TILE)  # centro del cuerpo, no los pies


func _goal() -> Vector2:
	var view := get_viewport_rect().size / zoom
	if mode == Mode.FOLLOW_LEVEL and _levels.size() > 0:
		var l := _level_of_target()
		if l != null:
			if l != _cur_level:
				_cur_level = l
				_log("nivel: %s" % l.name)
			var r := _level_rect(l)
			var lx := _clamp_axis(target.global_position.x, r.position.x, r.end.x, view.x / 2.0)
			return Vector2(lx, r.get_center().y)
	if auto_align and not _aligned and mode != Mode.FOLLOW:
		return _body_center()  # mientras no ha tocado el piso, solo la sigue
	match mode:
		Mode.SCREENS:
			var cell := screen_tiles * TILE
			var s := current_screen()
			if s != _last_band:
				_last_band = s
				_log("tercio %d, fila %d" % [s.x, s.y])
			return map_origin + Vector2(s.x, s.y) * cell + cell / 2.0
		Mode.FOLLOW_LEVEL:
			var size := level_tiles * TILE
			var row := current_level_row()
			if row != _last_band.y:
				_last_band = Vector2i(0, row)
				_log("nivel en la fila %d del mapa (y = %.0f)" % [row, map_origin.y + row * size.y])
			var x := target.global_position.x
			if clamp_x:
				x = _clamp_axis(x, map_origin.x, map_origin.x + size.x, view.x / 2.0)
			return Vector2(x, map_origin.y + (row + 0.5) * size.y)
	var goal := Vector2(target.global_position.x,
			_ground_y + ground_margin_tiles * TILE - view.y / 2.0)
	if use_limits:
		goal.x = _clamp_axis(goal.x, map_rect.position.x, map_rect.end.x, view.x / 2.0)
		goal.y = _clamp_axis(goal.y, map_rect.position.y, map_rect.end.y, view.y / 2.0)
	return goal


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


func _disable_others() -> void:
	if not disable_other_cameras:
		return
	for cam in get_tree().root.find_children("*", "Camera2D", true, false):
		if cam != self and (cam as Camera2D).enabled:
			(cam as Camera2D).enabled = false
			_log("apagué otra cámara: %s" % cam.get_path())
	make_current()


func _clamp_axis(v: float, lo: float, hi: float, half: float) -> float:
	if hi - lo <= half * 2.0:
		return (lo + hi) / 2.0
	return clampf(v, lo + half, hi - half)


func _fit_zoom() -> void:
	var h := get_viewport_rect().size.y
	zoom = Vector2.ONE * (h / (screen_tiles.y * TILE))


func _log(msg: String) -> void:
	if print_info:
		print("[Cámara] ", msg)
