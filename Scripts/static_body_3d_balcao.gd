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
				
				# --- AJUSTE DE ESCALA AQUI ---
				# Se as poções estiverem gigantes, diminua esse valor (ex: 0.2)
				# Se estiverem pequenas, aumente (ex: 1.5 ou 2.0)
				instancia.scale = Vector3(0.3, 0.3, 0.3) 
				
				# Opcional: Se o modelo estiver "enterrado" no balcão,
				# você pode ajustar a posição local dele aqui também:
				instancia.position.y = 0.0 # Ajuste conforme necessário
				
				if instancia is RigidBody3D: 
					instancia.freeze = true
		
		# 3. Criar o Label acima do modelo
		var label = Label3D.new()
		label.text = nome_da_pocao
		label.position.y = 1 # Altura acima da garrafinha
		label.billboard = StandardMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font_size = 40
		label.outline_size = 10
		container.add_child(label)
		
		# --- ANIMAÇÃO MÁGICA ---
		# Começa no centro do balcão e invisível
		container.global_position = global_position + Vector3(0, 1, 0)
		container.scale = Vector3.ZERO
		
		var tw = create_tween().set_parallel(true) # Roda as animações juntas
		
		# Move do centro para a posição do Marker correspondente
		tw.tween_property(container, "global_position", posicoes[i].global_position, 0.6)\
			.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		
		# Cresce com efeito elástico
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
		pedidos.erase(objeto.nome_item)
		objeto.queue_free()
		_recompensa()
		_gerarpedidos()
		if _player_esta_perto:
			_exibir_pedidos_magicos()
	else:
		_rejeitar_item(objeto)

func _recompensa():
	elastico()
	print("RECOMPENSA: Você ganhou 10 moedas de ouro!")

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
