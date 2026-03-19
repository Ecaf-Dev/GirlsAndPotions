extends VBoxContainer

var id_do_item = ""

func configurar(item: Items.Item):
	id_do_item = item.id
	
	# 1. Nome do Item (Sempre tenta definir se existir no dicionário)
	$Label_Nome.text = str(item.nome)
	
	# 2. Preço (Verifica se o nó existe e se o dado está presente)
	var label_preco = get_node_or_null("Label_Preco")
	if label_preco:
		label_preco.text = str(item.valor_compra) + " G"
	elif label_preco:
		label_preco.hide() # Esconde se não houver preço nos dados
		
	# 3. Imagem/Ícone (Adaptado para o TextureRect da sua hierarquia)
	var texture_rect = get_node_or_null("TextureRect_Imagem")
	if texture_rect:
		var path = item.icon
		if ResourceLoader.exists(path):
			texture_rect.texture = load(path)
		else:
			# Opcional: define um ícone padrão se o caminho falhar
			# texture_rect.texture = load("res://icon_default.png")
			push_warning("Caminho de ícone não encontrado: " + path)
