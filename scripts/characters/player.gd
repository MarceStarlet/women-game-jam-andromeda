class_name Player
extends CharacterBody2D
## Aelia: salto, doble salto, dash en 8 direcciones, vitali (brillo) y checkpoints.
## Hijos necesarios: CollisionShape2D (vacío), Camera2D y PointLight2D.
## Teclado: A/D mover · Espacio saltar (x2) · Shift dash (+ W/A/S/D para dirección)
## Mando:   stick/cruceta mover · A (Xbox) / X (PlayStation) saltar · X (Xbox) / □ (PS) dash

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
@export var dash_time := 0.15
@export var max_glow := 100.0
@export var glow_per_tile_up := 4.0
@export var glow_per_tile_down := 8.0
@export var deadly_fall := 6.0 * TILE
@export var drain_zone := 3.0 * TILE   # zona baja desde el inicio donde se drena la vitali
@export var drain_rate := 0.3          # vitali por segundo (aumenta con la profundidad)
@export var kill_y := 5000.0

@onready var light: PointLight2D = $PointLight2D

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


func _ready() -> void:
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
	# Teclado + mando (cruceta, stick izquierdo y botones)
	_bind("move_left", [KEY_A, KEY_LEFT], JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_bind("move_right", [KEY_D, KEY_RIGHT], JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_bind("move_up", [KEY_W, KEY_UP], JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_bind("move_down", [KEY_S, KEY_DOWN], JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_bind("jump", [KEY_SPACE], JOY_BUTTON_A)
	_bind("dash", [KEY_SHIFT, KEY_K], JOY_BUTTON_X)
	checkpoint = global_position
	takeoff_y = global_position.y
	drain_line = global_position.y - drain_zone
	add_glow(0.0)


func _physics_process(delta: float) -> void:
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
	light.energy = lerpf(0.2, 1.6, glow / max_glow)
	light.texture_scale = lerpf(1.0, 6.0, glow / max_glow)
	glow_changed.emit(glow, max_glow)
	if glow <= 0.0:
		faded_out.emit()
		die()


func die() -> void:
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
