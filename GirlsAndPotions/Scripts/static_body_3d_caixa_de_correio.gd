class_name CaixaDeCorreio
extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	Global.correio_referencia = self # Replace with function body.
	print("Correio: Registrado e pronto para spawnar itens no Marker3D.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
