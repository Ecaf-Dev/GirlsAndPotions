extends StaticBody3D

# Lista que servirá como nossos slots
var slots = [] 
@export var MAX_SLOTS = 2
@export var objeto_visual : Node3D

# Dicionário com todas as receitas possíveis
const RECEITAS = {
	"Poção De Cura": ["Flor Da Vida", "Flor Da Vida"],
	"Poção Da Determinação" : ["Flor Da Vida", "Poção De Cura"],
	"Poção De Cura Maior" : ["Poção De Cura", "Poção De Cura"],
	"Poção De Mana" : ["Flor Magica", "Flor Magica"],
	
}

@export var cena_base_item: PackedScene # Arraste sua cena de objeto genérico aqui no Inspector
func _on_area_3d_monitor_body_entered(body):
	print("Corpo detectado: ", body.name)
	
	if "nome_item" in body :
		if slots.size() < MAX_SLOTS && body.quantidade_atual == 1:
			slots.append(body.nome_item)
			print("Item adicionado ao slot: ", body.nome_item)
			print("Estado atual dos slots: ", slots)
			body.queue_free()
			elastico()
		elif (body.quantidade_atual >= 2):
			_rejeitar_item(body)
			print("Isso n é ingrediente")
		else:
			_rejeitar_item(body)
			print("Caldeirão cheio!")

func cozinhar():
	if slots.is_empty():
		print("O caldeirão está vazio!")
		elastico()
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
		elastico()
		print("ERRO! A mistura falhou e virou lixo.")
	
	# Limpa os slots após a tentativa conforme você pediu
	slots.clear()

func _instanciarobjeto(nome_do_item):
	elastico()
	if cena_base_item == null: return

	var novo_item = cena_base_item.instantiate()
	
	# --- PASSO 1: CAPTURAR A IDENTIDADE ORIGINAL ---
	# Guardamos os layers do RigidBody (O objeto em si)
	var corpo_layer = novo_item.collision_layer
	var corpo_mask = novo_item.collision_mask
	
	# Guardamos os layers da Area3D (O monitor de proximidade)
	var area_monitor = novo_item.get_node_or_null("Area3D_Monitor")
	var area_layer = 0
	var area_mask = 0
	
	if area_monitor:
		area_layer = area_monitor.collision_layer
		area_mask = area_monitor.collision_mask
		# Desativamos a área para ela não ser "engolida" de volta
		area_monitor.collision_layer = 0
		area_monitor.collision_mask = 0

	# Desativamos o corpo para ele não colidir com a borda do caldeirão ao sair
	novo_item.collision_layer = 0
	novo_item.collision_mask = 0
	
	# --- PASSO 2: NASCIMENTO E IMPULSO ---
	get_tree().root.add_child(novo_item)
	novo_item.nome_item = nome_do_item
	novo_item.global_position = global_position + Vector3(0, 1.8, 0)
	
	if novo_item is RigidBody3D:
		var direcao = Vector3(randf_range(-1, 1), 1.5, randf_range(-1, 1)).normalized()
		novo_item.apply_central_impulse(direcao * 7.0)

	# --- PASSO 3: A ESPERA SEGURA ---
	# Passamos todos os dados originais para a função de espera
	_esperar_saida_segura(novo_item, corpo_layer, corpo_mask, area_layer, area_mask)

func _esperar_saida_segura(item, c_layer, c_mask, a_layer, a_mask):
	var distancia_minima = 2.0 
	
	while is_instance_valid(item) and item.global_position.distance_to(self.global_position) < distancia_minima:
		await get_tree().physics_frame
	
	# --- PASSO 4: RESTAURAR TUDO AO ORIGINAL ---
	if is_instance_valid(item):
		# Restaura o corpo (RigidBody)
		item.collision_layer = c_layer
		item.collision_mask = c_mask
		
		# Restaura a área (Area3D)
		var area = item.get_node_or_null("Area3D_Monitor")
		if area:
			area.collision_layer = a_layer
			area.collision_mask = a_mask
		
		print("Poção liberada com camadas originais: Corpo(", c_layer, ") Area(", a_layer, ")")	
func elastico():
	if objeto_visual == null:
		print("Aviso: objeto_visual não definido no Inspector!")
		return

	# Criamos o Tween para manipulação estética
	var tween = create_tween()
	
	# 1. ESTICAR (Squash): Fica fino e alto
	# Vector3(X, Y, Z) -> Diminuímos X e Z, aumentamos Y
	tween.tween_property(objeto_visual, "scale", Vector3(0.6, 2.6, 0.8), 0.1)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	# 2. VOLTAR (Stretch): Volta ao normal com um balanço elástico
	tween.tween_property(objeto_visual, "scale", Vector3(0.8, 2.9, 1.0), 0.3)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)
		
	
func _rejeitar_item(item):
	if item is RigidBody3D:
		# Empurra o item para longe do balcão (em arco)
		var direcao = (item.global_position - global_position).normalized()
		item.apply_central_impulse(direcao * 4.0 + Vector3.UP * 3.0)
	elastico()
