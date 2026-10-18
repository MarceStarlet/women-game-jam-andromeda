extends Label
## Panel de diagnóstico para test_player.tscn (no se sube a GitHub).

var player: Player


func _ready() -> void:
	player = get_node_or_null("../../Player")


func _process(_delta: float) -> void:
	if player == null:
		text = "No encuentro el nodo Player"
		return
	var keys := []
	for a in ["move_left", "move_right", "move_up", "move_down", "jump", "dash"]:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			keys.append(a)
	var pads := Input.get_connected_joypads()
	var pad_name := Input.get_joy_name(pads[0]) if pads.size() > 0 else "(ninguno)"
	text = "Posición: %s\nVelocidad: %s\nEn el piso: %s\nVitali: %.1f\nTeclas/botones: %s\nMando: %s\nFPS: %d" % [
		player.global_position.round(), player.velocity.round(),
		"sí" if player.is_on_floor() else "no", player.glow,
		", ".join(keys) if keys.size() > 0 else "(ninguna)",
		pad_name, Engine.get_frames_per_second()]
