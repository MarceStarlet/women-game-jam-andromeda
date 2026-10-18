class_name Goal
extends Area2D
## META FINAL (el sol): al tocarla, Aelia gana.
## Script: scripts/components/goal.gd
## Escena: scenes/levels/goal.tscn
## El origen va a la altura del piso donde se para Aelia.
## Emite "reached" para que UI muestre la pantalla de victoria.

signal reached

const TILE := 135.0

@export var show_test_message := true   # texto temporal hasta que UI haga la pantalla final

var done := false


func _ready() -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE, 2.0 * TILE)
	col.shape = shape
	col.position = Vector2(0, -TILE)
	add_child(col)
	var sun := ColorRect.new()  # sol temporal hasta tener arte
	sun.size = Vector2(TILE, TILE)
	sun.position = Vector2(-TILE / 2.0, -3.0 * TILE)
	sun.color = Color(1.0, 0.85, 0.3)
	add_child(sun)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if done or not body.has_method("activate_checkpoint"):
		return
	done = true
	reached.emit()
	if show_test_message:
		var layer := CanvasLayer.new()
		var label := Label.new()
		label.text = "Decir no también es decirte sí a ti misma."
		label.add_theme_font_size_override("font_size", 40)
		label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		layer.add_child(label)
		add_child(layer)
