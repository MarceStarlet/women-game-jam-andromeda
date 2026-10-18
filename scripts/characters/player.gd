class_name Player
extends CharacterBody2D
## Aelia: salto, doble salto, dash en 8 direcciones, vitali (brillo) y checkpoints.
## Hijos necesarios: CollisionShape2D (vacío), Camera2D y PointLight2D.
## Teclado: A/D mover · Espacio saltar (x2) · Shift dash (+ W/A/S/D para dirección)
## Mando:   stick/cruceta mover · A (Xbox) / X (PlayStation) saltar · B (Xbox) / Círculo o R1 (PS) dash

signal glow_changed(glow: float, max_glow: float)
signal died
signal faded_out
signal checkpoint_reached(pos: Vector2)

const TILE := 135.0
const BODY_SIZE := Vector2(0.8, 2.0) * TILE  # 2 unidades de alto (108 x 270 px)

@export var speed := 4.0 * TILE
@export var gravity := 20.0 * TILE
@export var jump_height := 2.5 * TILE
@export var max_jumps := 2
@export var dash_speed := 20.0 * TILE
@export var dash_time := 0.17
@export var max_glow := 100.0
@export var glow_per_tile_up := 4.0
@export var glow_per_tile_down := 8.0
@export var deadly_fall := 6.0 * TILE
@export var drain_zone := 3.0 * TILE   # zona baja desde el inicio donde se drena la vitali
@export var drain_rate := 0.2          # vitali por segundo (aumenta con la profundidad)
@export var kill_y := 100000.0      # red de seguridad: muy abajo de todo el mapa (10800 px)
@export var sprite_faces_right := true
@export var death_time := 0.8            # segundos que dura la animación de muerte antes de reaparecer
@export var debug_shortcuts := true      # teclas 1-7: ir a cada nivel (para probar; apágalo al publicar)
@export_group("Brillo")
@export var world_tint := Color(0.5, 0.55, 0.72)  # oscurece el mundo para que se note la luz (blanco = no oscurecer)
@export var min_energy := 0.6
@export var max_energy := 0.95
@export var min_light_scale := 1.5
@export var max_light_scale := 6.0
@export var light_color := Color(1.0, 0.95, 0.8)
@export var pulse := 0.08                          # latido suave de la luz
@export_group("")  # ¿tu dibujo mira a la derecha? si mira a la izquierda, desmárcalo

@onready var light: PointLight2D = get_node_or_null("PointLight2D")
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var glow := 20.0
var jumps := 0
var can_air_dash := true
var dash_left := 0.0
var dash_dir := Vector2.ZERO
var facing := 1.0
var was_on_floor := false
var takeoff_y := 0.0
var drain_line := 0.0
var checkpoint := Vector2.ZERO
var checkpoint_glow := 20.0
var _pulse_t := 0.0
var _dying := 0.0   # > 0 mientras se ve la animación de muerte


func _ready() -> void:
	if light == null:  # si no hay luz (o se borró), la creamos aquí
		push_warning("Player: no encontré el nodo PointLight2D; creo uno nuevo.")
		light = PointLight2D.new()
		light.name = "PointLight2D"
		add_child(light)
	if get_node_or_null("CollisionShape2D") == null:
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	var shape := RectangleShape2D.new()
	shape.size = BODY_SIZE
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position.y = -BODY_SIZE.y / 2.0  # origen en los pies
	light.position.y = -BODY_SIZE.y / 2.0
	if light.texture == null:
		var tex := GradientTexture2D.new()
		tex.width = 512
		tex.height = 512
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.gradient = Gradient.new()
		tex.gradient.set_color(0, Color.WHITE)
		tex.gradient.set_color(1, Color(1, 1, 1, 0))
		light.texture = tex
	light.color = light_color
	light.blend_mode = Light2D.BLEND_MODE_ADD
	_add_darkness.call_deferred()
	# Teclado + mando (cruceta, stick izquierdo y botones)
	_bind("move_left", [KEY_A, KEY_LEFT], JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_bind("move_right", [KEY_D, KEY_RIGHT], JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_bind("move_up", [KEY_W, KEY_UP], JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_bind("move_down", [KEY_S, KEY_DOWN], JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_bind("jump", [KEY_SPACE], JOY_BUTTON_A)
	_bind("dash", [KEY_SHIFT, KEY_K], JOY_BUTTON_B)             # Círculo (PS) / B (Xbox)
	_bind("dash", [], JOY_BUTTON_RIGHT_SHOULDER)                   # R1 también
	checkpoint = global_position
	takeoff_y = global_position.y
	drain_line = global_position.y - drain_zone
	add_glow(0.0)


func _unhandled_input(event: InputEvent) -> void:
	# Atajos de prueba: 1..7 lleva a Aelia al primer checkpoint de ese nivel
	if not debug_shortcuts or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode
	if key >= KEY_1 and key <= KEY_7:
		_go_to_level(key - KEY_1 + 1)


func _go_to_level(n: int) -> void:
	var level: Node2D = null
	for node in get_tree().root.find_children("*", "Node2D", true, false):
		var nm := str(node.name).to_lower().replace("_", "")
		if nm == "level%d" % n:
			level = node
			break
	if level == null:
		print("[Atajo] No encontré el nodo Level%d en esta escena." % n)
		return
	var target := level.global_position + Vector2(2.5, 7.0) * TILE
	for spot in ["Spawn", "Entry", "Checkpoint1"]:
		var m := level.get_node_or_null(spot) as Node2D
		if m:
			target = m.global_position
			break
	_dying = 0.0
	checkpoint = target
	checkpoint_glow = maxf(glow, 60.0)
	global_position = target
	velocity = Vector2.ZERO
	takeoff_y = target.y
	glow = checkpoint_glow
	add_glow(0.0)
	for cam in find_children("*", "Camera2D", true, false):
		if "_snap" in cam:
			cam.set("_snap", true)  # la cámara salta directo, sin deslizarse
	print("[Atajo] Nivel %d" % n)


func _physics_process(delta: float) -> void:
	if _dying > 0.0:  # animación de muerte: no se mueve ni recibe controles
		_dying -= delta
		_pulse_t += delta
		_update_light()
		if _dying <= 0.0:
			_respawn()
		return
	var on_floor := is_on_floor()
	var x := Input.get_axis("move_left", "move_right")
	if x != 0.0:
		facing = signf(x)
	if on_floor:
		jumps = max_jumps
		can_air_dash = true

	# Dash
	if Input.is_action_just_pressed("dash") and (on_floor or can_air_dash):
		var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# Con el stick, redondea a la dirección más cercana de las 8
		dash_dir = Vector2.from_angle(snappedf(dir.angle(), PI / 4.0)) \
				if dir != Vector2.ZERO else Vector2(facing, 0)
		dash_left = dash_time
		can_air_dash = on_floor

	if dash_left > 0.0:
		dash_left -= delta
		velocity = dash_dir * dash_speed
		if dash_left <= 0.0:
			velocity *= 0.3
	else:
		velocity.x = x * speed
		velocity.y += gravity * delta
		if Input.is_action_just_pressed("jump"):
			if not on_floor and jumps == max_jumps:
				jumps -= 1  # cayó de una orilla: solo queda el doble salto
			if jumps > 0:
				velocity.y = -sqrt(2.0 * gravity * jump_height)
				jumps -= 1
		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= 0.5  # salto corto si suelta antes

	move_and_slide()

	# Despegue y aterrizaje
	if was_on_floor and not is_on_floor():
		takeoff_y = global_position.y
	elif not was_on_floor and is_on_floor():
		_land()
	was_on_floor = is_on_floor()

	# Drenaje en la zona baja
	var depth := global_position.y - drain_line
	if depth > 0.0:
		add_glow(-drain_rate * (1.0 + depth / TILE) * delta)

	if global_position.y > kill_y:
		die()

	_animate()
	_pulse_t += delta
	_update_light()


## La luz de Aelia: tamaño y fuerza según su vitali, con un latido suave
func _update_light() -> void:
	var k := clampf(glow / max_glow, 0.0, 1.0)
	light.energy = lerpf(min_energy, max_energy, k) * (1.0 + sin(_pulse_t * 2.5) * pulse)
	light.texture_scale = lerpf(min_light_scale, max_light_scale, k)


## Oscurece un poco el mundo (CanvasModulate) para que el brillo se vea
func _add_darkness() -> void:
	if world_tint == Color.WHITE:
		return
	if get_tree().root.find_children("*", "CanvasModulate", true, false).size() > 0:
		return  # ya hay uno en la escena: se respeta
	var cm := CanvasModulate.new()
	cm.name = "WorldDarkness"
	cm.color = world_tint
	var scene := get_tree().current_scene
	(scene if scene else get_tree().root).add_child(cm)


## Voltea a Aelia y elige la animación (nombres de tu SpriteFrames)
func _animate() -> void:
	if sprite == null:
		return
	sprite.flip_h = (facing < 0.0) == sprite_faces_right
	var anim := "idle"
	if dash_left > 0.0:
		anim = "dash"
	elif not is_on_floor():
		anim = "caida" if velocity.y > 0.0 and _has_anim("caida") else "salto"
	elif absf(velocity.x) > 1.0:
		anim = "correr"
	if sprite.animation != anim and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)


func _land() -> void:
	var dy := global_position.y - takeoff_y  # positivo = cayó
	if dy >= deadly_fall:
		die()
	elif dy > TILE:
		add_glow(-dy / TILE * glow_per_tile_down)
	elif dy < -TILE * 0.25:
		add_glow(-dy / TILE * glow_per_tile_up)


func add_glow(amount: float) -> void:
	glow = clampf(glow + amount, 0.0, max_glow)
	_update_light()
	glow_changed.emit(glow, max_glow)
	if glow <= 0.0:
		faded_out.emit()
		die()


func _has_anim(anim_name: String) -> bool:
	return sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim_name)


func die() -> void:
	if _dying > 0.0:
		return  # ya está muriendo
	# Si hay animación "muerte" (o si no, "caida"), se ve antes de reaparecer
	var anim := "muerte" if _has_anim("muerte") else ("caida" if _has_anim("caida") else "")
	if anim != "" and death_time > 0.0:
		_dying = death_time
		velocity = Vector2.ZERO
		dash_left = 0.0
		sprite.play(anim)
		return
	_respawn()


func _respawn() -> void:
	_dying = 0.0
	died.emit()
	velocity = Vector2.ZERO
	dash_left = 0.0
	global_position = checkpoint
	takeoff_y = checkpoint.y
	was_on_floor = false
	glow = maxf(checkpoint_glow, 15.0)
	add_glow(0.0)


func _bind(action: StringName, keys: Array, button: JoyButton,
		axis: JoyAxis = JOY_AXIS_INVALID, axis_dir := 0.0) -> void:
	# Si la acción ya existe en Project Settings, se conserva y solo se le
	# agregan las teclas/botones que le falten (sin duplicar).
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)  # 0.3 = zona muerta del stick
	var events: Array[InputEvent] = []
	for key in keys:
		var k := InputEventKey.new()
		k.physical_keycode = key
		events.append(k)
	var b := InputEventJoypadButton.new()
	b.button_index = button
	events.append(b)
	if axis != JOY_AXIS_INVALID:
		var m := InputEventJoypadMotion.new()
		m.axis = axis
		m.axis_value = axis_dir
		events.append(m)
	for e in events:
		if not InputMap.action_has_event(action, e):
			InputMap.action_add_event(action, e)


func activate_checkpoint(pos: Vector2) -> void:
	if pos.y > checkpoint.y:
		return  # está más abajo que el actual: no cuenta
	checkpoint = pos
	checkpoint_glow = glow
	checkpoint_reached.emit(pos)
