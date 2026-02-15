extends Node

# Sinais servem para avisar outros scripts que algo mudou
signal moedas_alteradas(quantidade)
signal pedido_entregue(total_pedidos)
signal prestigio_alterado(prestigio)

var moedas = 0
var total_pedidos = 0
var prestigio = 0

var caixa_correio = null

func adicionar_moedas(qtd):
	moedas += qtd
	moedas_alteradas.emit(moedas) # Avisa todo mundo!

func registrar_pedido():
	total_pedidos += 1
	pedido_entregue.emit(total_pedidos)

func alterar_prestigio(valor):
	prestigio = prestigio + valor
	prestigio_alterado.emit(prestigio)

func comprar_recurso(item_path, preco, quantidade):
	if moedas >= (preco * quantidade):
		moedas -= (preco * quantidade)
		moedas_alteradas.emit(moedas)
		
		# Faz o spawn para cada unidade comprada
		for i in range(quantidade):
			spawnar_item(item_path)
		return true
	return false

func spawnar_item(path):
	var item_cena = load(path)
	var item_instancia = item_cena.instantiate()
	
	# Adiciona o item na cena principal (para não sumir se a caixa sumir)
	get_tree().current_scene.add_child(item_instancia)
	
	# Define a posição para o Marker3D que você criou
	var spawner = caixa_correio.get_node("Marker3D_Spawner")
	item_instancia.global_position = spawner.global_position
