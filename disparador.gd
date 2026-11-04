class_name Disparador
extends Area3D

signal evento(posicion: Vector3)

@export var tecla := KEY_T
@export var que_representa := "una criatura oye un ruido"

var antes := false


func _enter_tree() -> void:
	add_to_group("disparadores")


func _ready() -> void:
	body_entered.connect(func(cuerpo: Node3D) -> void:
		if cuerpo is CharacterBody3D:
			evento.emit(global_position))


func _physics_process(_delta: float) -> void:
	var ahora := Input.is_key_pressed(tecla)
	if ahora and not antes:
		evento.emit(global_position)
	antes = ahora
