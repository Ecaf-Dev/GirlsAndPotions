extends StaticBody3D

# Lista que servirá como nossos slots
var slots = [] 
@export var MAX_SLOTS = 2
const RECEITA_POCAO_VIDA = ["flor_da_vida", "flor_da_vida"]

func _on_area_3d_monitor_body_entered(body):
	print("Corpo detectado: ", body.name)
	
	# Agora checamos se a variável existe no corpo (RigidBody3D)
	if "nome_item" in body:
		if slots.size() < MAX_SLOTS:
			slots.append(body.nome_item)
			print("Item adicionado ao slot: ", body.nome_item)
			print("Estado atual dos slots: ", slots)
			
			body.queue_free()
		else:
			print("Caldeirão cheio!")
func cozinhar():
	if slots.is_empty():
		print("O caldeirão está vazio!")
		return

	# Ordenamos as listas para garantir que a ordem que você jogou não importe
	var slots_ordenados = slots.duplicate()
	slots_ordenados.sort()
	
	var receita_ordenada = RECEITA_POCAO_VIDA.duplicate()
	receita_ordenada.sort()

	if slots_ordenados == receita_ordenada:
		print("SUCESSO! Você criou uma Poção de Vida!")
		# Aqui você instanciaria o objeto da poção depois
	else:
		print("ERRO! A mistura falhou e virou lixo.")
	
	# Limpa os slots após a tentativa
	slots.clear()
