extends Node

# Sinais servem para avisar outros scripts que algo mudou
signal moedas_alteradas(quantidade)
signal pedido_entregue(total_pedidos)

var moedas = 0
var total_pedidos = 0

func adicionar_moedas(qtd):
	moedas += qtd
	moedas_alteradas.emit(moedas) # Avisa todo mundo!

func registrar_pedido():
	total_pedidos += 1
	pedido_entregue.emit(total_pedidos)
