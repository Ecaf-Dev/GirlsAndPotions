extends StaticBody3D

@export var pedidos = []
@export var max_pedidos = 3
@export var objeto_visual : Node3D

# --- CONFIGURAÇÃO DE MODELOS ---
# Ajuste os caminhos abaixo para as suas cenas .tscn reais dentro da pasta Modelos
const MODELOS_POCOES = {
	"Poção De Cura": "res://GirlsAndPotions/Modelos/poção_de_cura.tscn",
	"Poção De Mana": "res://GirlsAndPotions/Modelos/poção_de_mana.tscn",
	"Poção Da Determinação": "res://GirlsAndPotions/Modelos/poção_da_determinação.tscn",
	"Poção De Cura Maior": "res://GirlsAndPotions/Modelos/poção_de_cura_maior.tscn"
}

@export var POCOES_POSSIVEIS = ["Poção De Cura", "Poção De Mana", "Poção Da Determinação", "Poção De Cura Maior"]

@onready var posicoes = [$Marker3D_Esquerda, $Marker3D_Centro, $Marker3D_Direita]
var itens_exibidos = [] 
var _player_esta_perto = false

func _ready():
	# Limpa qualquer resquício e gera os primeiros pedidos
	for i in range(max_pedidos):
		_gerarpedidos()
		
func _process(delta):
	# Percorre todos os hologramas que estão no balcão no momento
	for item in itens_exibidos:
		if is_instance_valid(item):
			# Gira o container no eixo Y (vertical)
			# 1.5 é a velocidade, você pode aumentar ou diminuir
			item.rotate_y(delta * 1.5)

func _gerarpedidos():
	if pedidos.size() < max_pedidos:
		var nova_pocao = POCOES_POSSIVEIS.pick_random()
		pedidos.append(nova_pocao)
		if _player_esta_perto: 
			_exibir_pedidos_magicos()

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
		
		# 2. Carregar e Instanciar o Modelo 3D
		if MODELOS_POCOES.has(nome_da_pocao):
			var cena_modelo = load(MODELOS_POCOES[nome_da_pocao])
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
		label_nome.position.y = 0.8 # Ajustado para ficar logo acima
		label_nome.billboard = StandardMaterial3D.BILLBOARD_ENABLED
		label_nome.no_depth_test = true
		label_nome.font_size = 35
		label_nome.outline_size = 8
		container.add_child(label_nome)
		
		# 4. Criar o Label ABAIXO do modelo (Preço)
		var label_preco = Label3D.new()
		
		# Busca o valor no dicionário Items
		var valor = 0
		if Items.itens.has(nome_da_pocao):
			valor = Items.itens[nome_da_pocao].valor_venda
			
		label_preco.text = str(valor) + " G"
		label_preco.position.y = -0.5 # Posicionado abaixo do modelo
		label_preco.billboard = StandardMaterial3D.BILLBOARD_ENABLED
		label_preco.no_depth_test = true
		label_preco.font_size = 45 # Preço um pouco maior para dar destaque
		label_preco.outline_size = 12
		label_preco.modulate = Color(1, 0.84, 0) # Cor Dourada para o ouro!
		container.add_child(label_preco)
		
		# --- ANIMAÇÃO MÁGICA ---
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
		var nome_entregue = objeto.nome_item # Guardamos o nome
		pedidos.erase(nome_entregue)
		objeto.queue_free()
		
		# Passamos o nome para a função de recompensa
		_recompensa(nome_entregue) 
		
		_gerarpedidos()
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

func _filtrarpedidos():
	#Aqui iremos filtrar quais pedidos estão elegiveis para serem gerados!
	pass
