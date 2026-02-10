extends StaticBody3D

# Lista que servirá como nossos slots
var slots = [] 
@export var MAX_SLOTS = 2

# Dicionário com todas as receitas possíveis
const RECEITAS = {
	"Poção Da Vida": ["Flor Da Vida", "Flor Da Vida"]
}

@export var cena_base_item: PackedScene # Arraste sua cena de objeto genérico aqui no Inspector
func _on_area_3d_monitor_body_entered(body):
	print("Corpo detectado: ", body.name)
	
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
	
	# Variável para controlar se achamos uma receita válida
	var sucesso = false
	var nome_da_receita_feita = ""

	# Criamos cópias para ordenar e garantir que a ordem dos itens não importe
	

	# Percorremos cada receita dentro do seu dicionário RECEITAS
	for nome_receita in RECEITAS:
		var ingredientes_receita = RECEITAS[nome_receita].duplicate()
		ingredientes_receita.sort()

		# Comparamos os itens no caldeirão com os ingredientes desta receita
		if slots == ingredientes_receita:
			sucesso = true
			nome_da_receita_feita = nome_receita
			break # Se achou, para de procurar

	# Resultado do cozimento baseado na busca acima
	if sucesso:
		print("RECEITA CRIADA: ", nome_da_receita_feita)
		_instanciarobjeto(nome_da_receita_feita)
		print("SUCESSO! Você criou uma Poção!")
	else:
		print("ERRO! A mistura falhou e virou lixo.")
	
	# Limpa os slots após a tentativa conforme você pediu
	slots.clear()

func _instanciarobjeto(nome_do_item):
	if cena_base_item == null: return

	var novo_item = cena_base_item.instantiate()
	
	# 1. Antes de adicionar ao mundo, limpamos as camadas de colisão
	# Isso faz com que ele não seja detectado por NENHUMA Area3D ou Raycast
	var camada_original = novo_item.collision_layer
	var mascara_original = novo_item.collision_mask
	
	novo_item.collision_layer = 0
	novo_item.collision_mask = 0
	
	# Se tiver a Area3D_Monitor, limpamos a dela também por segurança
	var area_detecao = novo_item.get_node_or_null("Area3D_Monitor")
	if area_detecao:
		area_detecao.collision_layer = 0
		area_detecao.collision_mask = 0

	# 2. Agora adicionamos ao mundo (ele está "fantasma" agora)
	get_tree().root.add_child(novo_item)
	
	novo_item.nome_item = nome_do_item
	novo_item.global_position = global_position + Vector3(0, 1.5, 0)
	
	# 3. Aplicamos o impulso (mesmo sem colisão, a física de movimento funciona)
	if novo_item is RigidBody3D:
		var direcao = Vector3(randf_range(-1, 1), 2.0, randf_range(-1, 1)).normalized()
		novo_item.apply_central_impulse(direcao * 6.0) # Aumentei um pouco a força

	# 4. Esperamos o objeto sair de perto do caldeirão
	await get_tree().create_timer(1.2).timeout
	
	# 5. Devolvemos a existência física ao objeto
	if is_instance_valid(novo_item):
		novo_item.collision_layer = camada_original
		novo_item.collision_mask = mascara_original
		if area_detecao:
			area_detecao.collision_layer = 1 # Ou a camada que você usa
			area_detecao.collision_mask = 1
		print("Objeto '", nome_do_item, "' agora é sólido e coletável!")
