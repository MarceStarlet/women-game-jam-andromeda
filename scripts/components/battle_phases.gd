class_name BattlePhases
extends Node
## FASES DE LA BATALLA FINAL
## Script: scripts/components/battle_phases.gd (en el nodo "BattlePhases" del nivel 7)
## - Al empezar, solo está activa la fase 1; la fase 2 está oculta y sin colisiones.
## - Cuando Aelia pisa la plataforma del "trigger", la fase 1 se desvanece
##   y la fase 2 aparece. Emite phase_changed(2) para música, diálogo o UI.

signal phase_changed(phase: int)

@export var phase1: NodePath
@export var phase2: NodePath
@export var trigger: NodePath   # Area2D que detecta a Aelia
@export var fade_time := 0.6

var phase := 1


func _ready() -> void:
	_set_active(get_node(phase2), false)
	(get_node(phase2) as CanvasItem).visible = false
	var t := get_node(trigger) as Area2D
	t.body_entered.connect(_on_trigger)


func _on_trigger(body: Node2D) -> void:
	if phase != 1 or not body.has_method("activate_checkpoint"):
		return
	phase = 2
	var p1 := get_node(phase1) as CanvasItem
	var p2 := get_node(phase2) as CanvasItem
	_set_active(p1, false)  # la luna deja de atacar y sus bloques ya no chocan
	var out := create_tween()
	out.tween_property(p1, "modulate:a", 0.0, fade_time)
	out.tween_callback(func() -> void: p1.visible = false)
	_set_active(p2, true)
	p2.visible = true
	p2.modulate.a = 0.0
	create_tween().tween_property(p2, "modulate:a", 1.0, fade_time)
	phase_changed.emit(2)


func _set_active(n: Node, on: bool) -> void:
	# Al desactivar un nodo, Godot también quita del mundo las colisiones de sus hijos
	n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
