extends Control

@onready var painel_livro = $CanvasLayer/Control_Painel_Livro
@onready var label_moedas = $CanvasLayer/Control_HUD_Principal/HBoxContainer_Contador_Moedas/Label
@onready var label_pedidosentregues = $"CanvasLayer/Control_Painel_Livro/MarginContainer/ColorRect/TabContainer_ControleDeAbas/Control_Glossário/VBoxContainer_PaginaEsquerda/Label_PedidosEntregues"
@onready var label_ourofaturado = $"CanvasLayer/Control_Painel_Livro/MarginContainer/ColorRect/TabContainer_ControleDeAbas/Control_Glossário/VBoxContainer_PaginaEsquerda/Label_OuroFaturado"


var livro_aberto = false
var moedas_atuais = 0

func _ready():
	Global.moedas_alteradas.connect(atualizar_ui_moedas)
	# Inicializa o painel invisível e pequeno para o efeito
	painel_livro.visible = false
	painel_livro.scale = Vector2.ZERO
	# Centraliza o pivot para o efeito de escala sair do meio do livro
	painel_livro.pivot_offset = painel_livro.size / 2
	
	atualizar_ui_moedas(Global.moedas)

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
