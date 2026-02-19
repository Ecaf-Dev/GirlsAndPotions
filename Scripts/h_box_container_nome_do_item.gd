extends HBoxContainer

# Caminho para uma imagem de interrogação quando o item for secreto
const ICONE_DESCONHECIDO = "res://GirlsAndPotions/Arts/Icones/shadow_icon.png"

func _ready():
	# Chamamos a configuração assim que o objeto entra na cena
	_conectarareceitaeitensglobal()

func _conectarareceitaeitensglobal():
	# 1. Identificar qual poção este HBox representa através do nome do nó
	# Exemplo: de "HBoxContainer_Poção De Cura" extraímos "Poção De Cura"
	var nome_da_pocao = name.replace("HBoxContainer_", "")
	
	if not Receitas.receitas.has(nome_da_pocao):
		print("Erro: Receita não encontrada para o nó: ", name)
		return
		
	var dados_receita = Receitas.receitas[nome_da_pocao]
	var pode_exibir = dados_receita["pode_fabricar"]
	
	# 2. Limpar qualquer lixo que esteja no HBox (caso você tenha feito placeholders no editor)
	for child in get_children():
		child.queue_free()

	# 3. Montar a sequência de ingredientes dinamicamente
	# Vamos percorrer as chaves do dicionário procurando por "item1", "item2", etc.
	var index_item = 1
	while dados_receita.has("item" + str(index_item)):
		var nome_ingrediente = dados_receita["item" + str(index_item)]
		
		# Se for o segundo item em diante, adicionamos um Label de "+"
		if index_item > 1:
			_criar_label_simbolo("+")
		
		# Criar o ícone do ingrediente
		_criar_texture_rect(nome_ingrediente, pode_exibir)
		
		index_item += 1
	
	# 4. Adicionar o símbolo de "="
	_criar_label_simbolo("=")
	
	# 5. Adicionar o resultado final (a própria poção)
	_criar_texture_rect(nome_da_pocao, pode_exibir, true) # true para destacar o resultado

# --- FUNÇÕES AUXILIARES DE CRIAÇÃO ---

func _criar_texture_rect(nome_item: String, liberado: bool, eh_resultado: bool = false):
	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(64, 64)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if liberado:
		# Busca o ícone no script de Itens
		if Items.itens.has(nome_item):
			var caminho_icon = Items.itens[nome_item]["icon"]
			if caminho_icon != "":
				tex_rect.texture = load(caminho_icon)
			else:
				# Caso o item exista mas não tenha ícone ainda
				tex_rect.modulate = Color(0.2, 0.2, 0.2) # Silhueta escura
		
		# Adiciona um Tooltip (Dica ao passar o mouse) com o nome do item
		tex_rect.tooltip_text = nome_item
	else:
		# Se estiver bloqueado, mostra o ícone de desconhecido ou silhueta
		tex_rect.texture = load(ICONE_DESCONHECIDO)
		tex_rect.modulate = Color(0.4, 0.4, 0.4) # Bem escuro
		tex_rect.tooltip_text = "???"

	if eh_resultado:
		tex_rect.custom_minimum_size = Vector2(80, 80) # Resultado um pouco maior
		
	add_child(tex_rect)

func _criar_label_simbolo(texto: String):
	var label = Label.new()
	label.text = texto
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Alterando a cor para um Marrom Café (combina com o estilo antigo/grimório)
	# Você pode usar Color.BLACK, Color.BROWN ou um código Hexadecimal
	label.add_theme_color_override("font_color", Color("4b2c20")) 
	
	# Se quiser um contorno para destacar mais:
	# label.add_theme_color_override("font_outline_color", Color.WHITE)
	# label.add_theme_constant_override("outline_size", 4)

	label.add_theme_font_size_override("font_size", 40)
	add_child(label)
