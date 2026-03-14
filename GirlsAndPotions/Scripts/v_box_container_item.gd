extends VBoxContainer

var id_do_item = ""

func configurar(id: String, dados: Dictionary):
	id_do_item = id
	
	# 1. Nome do Item (Sempre tenta definir se existir no dicionário)
	if dados.has("nome"):
		$Label_Nome.text = str(dados.nome)
	
	# 2. Preço (Verifica se o nó existe e se o dado está presente)
	var label_preco = get_node_or_null("Label_Preco")
	if label_preco and dados.has("valor_compra"):
		label_preco.text = str(dados.valor_compra) + " G"
	elif label_preco:
		label_preco.hide() # Esconde se não houver preço nos dados
		
	# 3. Imagem/Ícone (Adaptado para o TextureRect da sua hierarquia)
	var texture_rect = get_node_or_null("TextureRect_Imagem")
	if texture_rect and dados.has("icon"):
		var path = dados.icon
		if ResourceLoader.exists(path):
			texture_rect.texture = load(path)
		else:
			# Opcional: define um ícone padrão se o caminho falhar
			# texture_rect.texture = load("res://icon_default.png")
			push_warning("Caminho de ícone não encontrado: " + path)
			
	# 4. Quantidade (SpinBox)
	var spin_box = get_node_or_null("SpinBox_Quantidade")
	if spin_box and dados.has("quantidade_inicial"):
		spin_box.value = dados.quantidade_inicial
