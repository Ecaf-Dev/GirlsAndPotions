extends StaticBody3D

# Lista que servirá como nossos slots
var slots = [] 
@export var MAX_SLOTS = 2
@export var objeto_visual : Node3D

# Dicionário com todas as receitas possíveis
const RECEITAS = {
	"Poção De Cura": ["Flor Da Vida", "Flor Da Vida"]
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
			elastico()
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
		print("ERRO! A mistura falhou e virou lixo.")
	
	# Limpa os slots após a tentativa conforme você pediu
	slots.clear()

func _instanciarobjeto(nome_do_item):
	elastico()
	if cena_base_item == null: return

	var novo_item = cena_base_item.instantiate()
	
	# 1. Guardamos as camadas originais
	var camada_original = 1 # Geralmente 1, ou pegue do seu projeto
	var mascara_original = 1 
	
	# Deixamos ele "fantasma" inicialmente
	novo_item.collision_layer = 0
	novo_item.collision_mask = 0
	
	var area_detecao = novo_item.get_node_or_null("Area3D_Monitor")
	if area_detecao:
		area_detecao.collision_layer = 0
		area_detecao.collision_mask = 0

	get_tree().root.add_child(novo_item)
	
	novo_item.nome_item = nome_do_item
	# Nasce um pouco mais alto para garantir que não prenda no fundo
	novo_item.global_position = global_position + Vector3(0, 1.8, 0)
	
	if novo_item is RigidBody3D:
		# Um impulso lateral mais garantido para tirar ele de cima do caldeirão
		var direcao = Vector3(randf_range(-1, 1), 1.5, randf_range(-1, 1)).normalized()
		novo_item.apply_central_impulse(direcao * 7.0)

	# 2. A MÁGICA: Em vez de um Timer fixo, vamos monitorar a distância
	_esperar_saida_segura(novo_item, camada_original, mascara_original)

# Nova função auxiliar para monitorar a saída
func _esperar_saida_segura(item, camada, mascara):
	var distancia_minima = 2.0 # Se estiver a mais de 2 metros, é seguro
	
	# Criamos um loop que roda enquanto o item estiver muito perto
	while is_instance_valid(item) and item.global_position.distance_to(self.global_position) < distancia_minima:
		# Espera um frame do servidor de física (muito eficiente)
		await get_tree().physics_frame
	
	# 3. Agora que ele se afastou, devolvemos a física
	if is_instance_valid(item):
		item.collision_layer = camada
		item.collision_mask = mascara
		var area = item.get_node_or_null("Area3D_Monitor")
		if area:
			area.collision_layer = 1
			area.collision_mask = 1
		print("Poção liberada: Longe o suficiente do caldeirão!")
		
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
