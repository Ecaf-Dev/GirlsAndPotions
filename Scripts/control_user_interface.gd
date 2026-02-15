extends Control

@onready var painel_livro = $CanvasLayer/Control_Painel_Livro
@onready var label_moedas = $CanvasLayer/Control_HUD_Principal/HBoxContainer_Contador_Moedas/Label
@onready var label_pedidosentregues = $"CanvasLayer/Control_Painel_Livro/MarginContainer/Control_Glossário/VBoxContainer_PaginaEsquerda/Label_PedidosEntregues"
@onready var label_ourofaturado = $"CanvasLayer/Control_Painel_Livro/MarginContainer/Control_Glossário/VBoxContainer_PaginaEsquerda/Label_OuroFaturado"
@onready var label_prestigio = $"CanvasLayer/Control_Painel_Livro/MarginContainer/Control_Glossário/VBoxContainer_PaginaEsquerda/Label_Prestigio"

var livro_aberto = false
var moedas_atuais = 0

@onready var container_paginas = $CanvasLayer/Control_Painel_Livro/MarginContainer
@onready var tela_atual = $CanvasLayer/Control_Painel_Livro/MarginContainer/Control_Glossario

func _ready():
	Global.moedas_alteradas.connect(atualizar_ui_moedas)
	# Inicializa o painel invisível e pequeno para o efeito
	painel_livro.visible = false
	painel_livro.scale = Vector2.ZERO
	# Centraliza o pivot para o efeito de escala sair do meio do livro
	painel_livro.pivot_offset = painel_livro.size / 2
	
	atualizar_ui_moedas(Global.moedas)
	atualizar_ui_prestigio(Global.prestigio)
	trocar_de_tela('Glossário')

# Esta função será chamada pelo botão do livro (via sinal)
func _on_texture_button_livro_pressed():
	if not livro_aberto:
		_abrir_livro()
	else:
		_fechar_livro()

func _abrir_livro():
	livro_aberto = true
	painel_livro.visible = true # Isso agora mostra o painel e o ColorRect junto
	
	var tw = create_tween()
	# O Pivot Offset que ajustamos garante que o ColorRect cresça do centro
	tw.tween_property(painel_livro, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	label_pedidosentregues.text = "Pedidos entregues: " + str(Global.total_pedidos)
	label_ourofaturado.text = "Ouro faturado: " + str(Global.moedas)
	label_prestigio.text = "Prestigio: "+ str(Global.prestigio)

func _fechar_livro():
	var tw = create_tween()
	tw.tween_property(painel_livro, "scale", Vector2.ZERO, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.finished.connect(func(): 
		painel_livro.visible = false
		livro_aberto = false
	)

func adicionar_moedas(quantidade):
	moedas_atuais += quantidade
	atualizar_ui_moedas(quantidade)

func atualizar_ui_moedas(novo_valor):
	label_moedas.text = str(novo_valor).pad_zeros(4)

func atualizar_ui_prestigio(novo_valor):
	label_prestigio.text = str(novo_valor).pad_zeros(4)

func _on_button_receitas_pressed():
	pass

func _on_button_loja_pressed():
	trocar_de_tela("Loja")

func _on_button_2_sair_pressed():
	_fechar_livro()


func _on_button_3_tutoriais_pressed():
	pass

func _on_button_configurações_pressed():
	pass# Replace with function body.

func trocar_de_tela(nome_alvo: String):
	# 1. Monta o nome completo do nó que estamos procurando (ex: "Control_Loja")
	var nome_completo_no = "Control_" + nome_alvo
	
	# 2. Tenta encontrar esse nó dentro do container
	var tela_alvo = container_paginas.get_node_or_null(nome_completo_no)
	
	if tela_alvo:
		# 3. Desativa a tela que estava aberta
		if tela_atual:
			tela_atual.visible = false
		
		# 4. Ativa a nova tela e atualiza a referência da 'tela_atual'
		tela_alvo.visible = true
		tela_atual = tela_alvo
		
		print("Troca concluída para: ", nome_completo_no)
	else:
		push_error("Erro: A tela " + nome_completo_no + " não foi encontrada no container!")


func _on_button_voltar_pressed():
	trocar_de_tela('Glossário')


func _on_button_comprar_pressed():
	pass # Replace with function body.
