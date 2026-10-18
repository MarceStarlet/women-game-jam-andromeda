class_name Checkpoint
extends Area2D
## CHECKPOINT
## Script: scripts/components/checkpoint.gd
## Escena: scenes/levels/checkpoint.tscn
##
## Para usarlo en el mapa: arrastren checkpoint.tscn al nivel, con el origen
## (la base del banderín) a la altura del PISO. Ahí reaparece Aelia.
## Solo cuenta si está más arriba que el último checkpoint tocado.

signal activated

@export var inactive_color := Color(0.5, 0.5, 0.6)
@export var active_color := Color(1.0, 0.85, 0.3)

var is_active := false

@onready var flag: ColorRect = get_node_or_null("Flag")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if flag:
		flag.color = inactive_color


func _on_body_entered(body: Node2D) -> void:
	if is_active or not body.has_method("activate_checkpoint"):
		return
	body.activate_checkpoint(global_position)
	is_active = true
	if flag:
		flag.color = active_color  # cambia de color al activarse
	activated.emit()  # para sonido, partículas o diálogo
