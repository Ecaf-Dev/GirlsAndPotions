extends StaticBody3D

@export var pedidos = []
@export var max_pedidos = 3
@export var objeto_visual : Node3D

var pedidos_viaveis = []
var pedidos_ativos = []
var fila_de_espera = [] # Pedidos que aguardam vaga no balcão

@export var pedidos_por_dia = 0.05
# --- CONFIGURAÇÃO DE MODELOS ---

@onready var posicoes = [$Marker3D_Esquerda, $Marker3D_Centro, $Marker3D_Direita]
var itens_exibidos = [] 
var _player_esta_perto = false

func _ready():
	# Limpa qualquer resquício e gera os primeiros pedidos
	_gerar_pedidos_por_populacao()
		
func _process(delta):
	# Percorre todos os hologramas que estão no balcão no momento
	for item in itens_exibidos:
		if is_instance_valid(item):
			# Gira o container no eixo Y (vertical)
			# 1.5 é a velocidade, você pode aumentar ou diminuir
			item.rotate_y(delta * 1.5)

func _on_area_3d_monitor_body_entered(body):
	if body.is_in_group("player"):
		_player_esta_perto = true
		_exibir_pedidos_magicos()
	
	if "nome_item" in body:
		_checarentrega(body)
	
func _on_area_3d_monitor_body_exited(body):
	if body.is_in_group("player"):
		_player_esta_perto = false
		
		# Espera 3 segundos antes de limpar
		# Se o jogador voltar antes disso, a variável _player_esta_perto volta a ser true
		await get_tree().create_timer(3.0).timeout
		
		# Verificamos se o jogador AINDA está longe antes de sumir com tudo
		if not _player_esta_perto:
			_limpar_exibicao()
# --- NOVA FUNÇÃO DE EXIBIÇÃO COM MOVIMENTO E MODELO ---
func _exibir_pedidos_magicos():
	_limpar_exibicao()
	
	for i in range(pedidos.size()):
		if i >= posicoes.size(): break
		
		var nome_da_pocao = pedidos[i]
		
		# 1. Criar um Container para o modelo e o texto
		var container = Node3D.new()
		add_child(container)
		
		# 2. Carregar e Instanciar o Modelo 3D via Receitas Global
		if Receitas.receitas.has(nome_da_pocao):
			var dados_receita = Receitas.receitas[nome_da_pocao]
			
			# Pegamos o caminho usando o próprio nome da poção como chave
			# como está definido no seu script Global
			var caminho_modelo = dados_receita.get(nome_da_pocao) 
			
			if caminho_modelo:
				var cena_modelo = load(caminho_modelo)
				if cena_modelo:
					var instancia = cena_modelo.instantiate()
					container.add_child(instancia)
					instancia.scale = Vector3(0.3, 0.3, 0.3) 
					instancia.position.y = 0.0 
					
					if instancia is RigidBody3D: 
						instancia.freeze = true
		
		# 3. Criar o Label ACIMA do modelo (Nome)
		var label_nome = Label3D.new()
		label_nome.text = nome_da_pocao
		label_nome.position.y = 0.8 
		label_nome.billboard = StandardMaterial3D.BILLBOARD_ENABLED
		label_nome.no_depth_test = true
		label_nome.font_size = 35
		label_nome.outline_size = 8
		container.add_child(label_nome)
		
		# 4. Criar o Label ABAIXO do modelo (Preço)
		var label_preco = Label3D.new()
		
		# Busca o valor no dicionário Items (Mantive como estava)
		var valor = 0
		if Items.itens.has(nome_da_pocao):
			valor = Items.itens[nome_da_pocao].valor_venda
			
		label_preco.text = str(valor) + " G"
		label_preco.position.y = -0.5 
		label_preco.billboard = StandardMaterial3D.BILLBOARD_ENABLED
		label_preco.no_depth_test = true
		label_preco.font_size = 45 
		label_preco.outline_size = 12
		label_preco.modulate = Color(1, 0.84, 0) 
		container.add_child(label_preco)
		
		# --- ANIMAÇÃO MÁGICA (Recuperada com os detalhes!) ---
		container.global_position = global_position + Vector3(0, 1, 0)
		container.scale = Vector3.ZERO
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(container, "global_position", posicoes[i].global_position, 0.6)\
			.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		
		tw.tween_property(container, "scale", Vector3.ONE, 0.8)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		itens_exibidos.append(container)		
		
func _limpar_exibicao():
	for item in itens_exibidos:
		if is_instance_valid(item):
			# Efeito de encolher antes de sumir
			var tw = create_tween()
			tw.tween_property(item, "scale", Vector3.ZERO, 0.2)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(item.queue_free)
	itens_exibidos.clear()

# --- RESTANTE DA SUA LÓGICA ---
func _checarentrega(objeto):
	if objeto.nome_item in pedidos:
		var nome_entregue = objeto.nome_item
		pedidos.erase(nome_entregue)
		objeto.queue_free()
		
		_recompensa(nome_entregue) 
		
		# Tenta puxar o próximo da fila automaticamente
		_repor_balcao()
		
		# (Opcional) Se você quiser que o balcão atualize visualmente 
		# mesmo sem reposição (caso a fila acabe), mantenha isso:
		if _player_esta_perto:
			_exibir_pedidos_magicos()
	else:
		_rejeitar_item(objeto)
		
func _recompensa(nome_da_pocao):
	elastico()
	
	# Buscamos os dados do item no seu script global Items
	if Items.itens.has(nome_da_pocao):
		var dados = Items.itens[nome_da_pocao]
		var valor = dados.valor_venda # Ex: 12 para Cura Maior
		
		# Adicionamos o valor real ao Global
		Global.adicionar_moedas(valor)
		print("RECOMPENSA: Você vendeu ", nome_da_pocao, " por ", valor, " G!")
	else:
		# Fallback caso o nome não esteja no dicionário
		Global.adicionar_moedas(5) 
		print("Aviso: Item não encontrado no catálogo, pago valor base de 5G")

	Global.registrar_pedido()
	Global.alterar_prestigio(1)

func _rejeitar_item(item):
	if item is RigidBody3D:
		var direcao = (item.global_position - global_position).normalized()
		item.apply_central_impulse(direcao * 4.0 + Vector3.UP * 3.0)
	elastico()

func elastico():
	if objeto_visual == null: return
	var tween = create_tween()
	tween.tween_property(objeto_visual, "scale", Vector3(0.35, 0.7, 0.35), 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(objeto_visual, "scale", Vector3(0.5, 0.5, 0.5), 0.3)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _gerar_pedidos_por_populacao():
	# 1. Filtra poções viáveis
	var todas_as_receitas = Receitas.receitas
	pedidos_viaveis.clear()
	for nome in todas_as_receitas:
		if todas_as_receitas[nome]["pode_fabricar"] == true:
			pedidos_viaveis.append(nome)

	if pedidos_viaveis.is_empty(): return

	# 2. Calcula a demanda total do dia baseada na população
	var total_pessoas = Populacao.get_total_populacao()
	var quantidade_total_dia = ceil(total_pessoas * pedidos_por_dia) 
	
	# 3. Preenche a FILA DE ESPERA primeiro
	fila_de_espera.clear()
	for i in range(quantidade_total_dia):
		fila_de_espera.append(pedidos_viaveis.pick_random())
	
	print("Pedidos totais gerados para hoje: ", fila_de_espera.size())

	# 4. Transfere da fila para o balcão (até o limite de 3)
	_repor_balcao()

func _repor_balcao():
	var mudou = false
	# Enquanto o balcão tiver espaço E a fila tiver pedidos...
	while pedidos.size() < max_pedidos and fila_de_espera.size() > 0:
		# Remove o primeiro da fila e coloca no balcão
		var proximo_pedido = fila_de_espera.pop_front() 
		pedidos.append(proximo_pedido)
		mudou = true
	
	# Se algo mudou e o player está vendo, atualiza os hologramas
	if mudou and _player_esta_perto:
		_exibir_pedidos_magicos()

