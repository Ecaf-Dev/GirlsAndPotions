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

