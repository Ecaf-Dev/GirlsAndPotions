extends Node

# Sinais servem para avisar outros scripts que algo mudou
signal moedas_alteradas(quantidade)
signal pedido_entregue(total_pedidos)
signal prestigio_alterado(prestigio)

var pedidos_ativos_globais = []

var moedas = 10
var total_pedidos = 0
var prestigio = 0

var correio_referencia = null
var cena_objeto_universal = preload("res://GirlsAndPotions/Cenas/rigid_body_3d_objeto.tscn")

func adicionar_moedas(qtd):
	moedas += qtd
	moedas_alteradas.emit(moedas) # Avisa todo mundo!

func registrar_pedido():
	total_pedidos += 1
	pedido_entregue.emit(total_pedidos)

func alterar_prestigio(valor):
	prestigio = prestigio + valor
	prestigio_alterado.emit(prestigio)

# No Global.gd

func realizar_entrega_correio(pacotes: Array, valor_total: int) -> bool:
	if valor_total <= moedas:
		if correio_referencia == null:
			print("Erro: Correio não registrado!")
			return false
			
		moedas -= valor_total
		print("Pagamento recebido, preparando entrega...")
		
		# Pegamos a posição do Marker3D que vimos na sua imagem
		var spawn_pos = correio_referencia.get_node("Marker3D_Spawner").global_position
		
		# --- LOOP DE INSTANCIAÇÃO ---
		for item_dados in pacotes:
			# item_dados contém: {"nome": "Flor Da Vida", "qtd": 10, "item_no": ...}
			
			# 1. Instanciamos a sua cena universal
			var novo_objeto = cena_objeto_universal.instantiate()
			
			# 2. Injetamos as variáveis @export ANTES de adicionar na árvore
			# Assim, quando o _ready() dela rodar, ela já terá os dados certos!
			novo_objeto.nome_item = item_dados.nome
			novo_objeto.quantidade_atual = item_dados.qtd
			
			# 3. Adicionamos o item à cena principal (para não sumir se o HUD fechar)
			get_tree().current_scene.add_child(novo_objeto)
			
			# 4. Posicionamos no Correio
			novo_objeto.global_position = spawn_pos
			
			# Opcional: Pequeno intervalo para os itens não saírem colados
			await get_tree().create_timer(0.1).timeout
			
		return true
	return false
