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
	_adicionar_items_a_loja()

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
	var grids = [
		$CanvasLayer/Control_Painel_Livro/MarginContainer/Control_Loja/GridContainer_PaginaEsquerda,
		$CanvasLayer/Control_Painel_Livro/MarginContainer/Control_Loja/GridContainer_PaginaDireita
	]
	
	var valor_total_da_compra = 0
	var lista_de_itens_validados = [] 
	
	for grid in grids:
		for item_ui in grid.get_children():
			var spinbox = item_ui.get_node("SpinBox_Quantidade")
			var qtd = spinbox.value
			
			if qtd > 0:
				var preco_unitario = item_ui.get_node("Label_Preco").text.to_int()
				valor_total_da_compra += (preco_unitario * qtd)
				
				lista_de_itens_validados.append({
					"item_no": item_ui,
					"nome": item_ui.get_node("Label_Nome").text,
					"qtd": qtd
				})

	if valor_total_da_compra == 0:
		print("Carrinho vazio!")
		return

	# CHAMADA DA GLOBAL: Enviamos e recebemos um "true" ou "false"
	var compra_foi_feita = await Global.realizar_entrega_correio(lista_de_itens_validados, valor_total_da_compra)

	if compra_foi_feita:
		# --- SUCESSO NA COMPRA (O Global já tirou o ouro) ---
		print("HUD: Compra autorizada. Zerando quantidades.")
		for pedido in lista_de_itens_validados:
			pedido.item_no.get_node("SpinBox_Quantidade").value = 0
	
	# Atualiza o contador de moedas na tela
	atualizar_ui_moedas(Global.moedas)

func _adicionar_items_a_loja():
	# 1. Referências aos Grids e a Cena do Item
	var grid_esquerda = $CanvasLayer/Control_Painel_Livro/MarginContainer/Control_Loja/GridContainer_PaginaEsquerda
	var grid_direita = $CanvasLayer/Control_Painel_Livro/MarginContainer/Control_Loja/GridContainer_PaginaDireita
	var cena_item = preload("res://GirlsAndPotions/Cenas/v_box_container_item.tscn")
	
	for n in grid_esquerda.get_children(): n.queue_free()
	for n in grid_direita.get_children(): n.queue_free()
	
	var contador = 0
	
	# 2. Loop pelo dicionário global
	for id in Items.itens:
		var dados = Items.itens[id]
		
		# --- O FILTRO DE COMPRAVÉL ---
		# Se o item não tiver a chave 'compravel' ou se ela for 'false', pulamos ele.
		if dados.has("compravel") and dados.compravel == false:
			print("Item ignorado (não é comprável): ", id)
			continue # Vai direto para o próximo 'id' do loop
		
		var novo_item = cena_item.instantiate()
		
		# Configura o item com os dados do Global
		novo_item.configurar(id, dados)
		
		# 3. Lógica de distribuição (4 por grid)
		if contador < 4:
			grid_esquerda.add_child(novo_item)
		elif contador < 8:
			grid_direita.add_child(novo_item)
		else:
			print("Loja cheia! Item não adicionado: ", id)
			break
			
		contador += 1
