extends Node3D

@export_group("Configurações do Grid")
@export var colunas: int = 5      # Largura (X)
@export var linhas: int = 5       # Profundidade (Z)
@export var tamanho_tile: float = 2.0 

@export_group("Recursos")
@export var cena_tile: PackedScene

@export_group("Cenas de Mobília")
@export var mobilia_automatica: bool = false
#Observação, precisa-se ajustar a arquitetura de mobilias, indico criar uma variavel global que gerencie todas as mobilias, por hora não criei pois estou implementando a mecanica de instancia via configuração da fase
#@export var catalogo_mobilias: Dictionary = {
	#"caldeirao": preload("res://GirlsAndPotions/Cenas/static_body_3d_caldeirao.tscn"),
	#"tabua_de_corte": preload("res://GirlsAndPotions/Cenas/static_body_3d_tabua_de_corte.tscn"), # ajuste o caminho
	#"balcao": preload("res://GirlsAndPotions/Cenas/static_body_3d_balcao.tscn"),
	#"caixa_de_correio": preload("res://GirlsAndPotions/Cenas/static_body_3d_caixa_de_correio.tscn")
#}

func _ready():
	var fase_ativa = Fases.pegar_fase("Fase 1")
	if fase_ativa:
		self.colunas = fase_ativa.largura
		self.linhas = fase_ativa.profundidade
		gerar_grid_centralizado()
		# CHAMADA NOVA:
		instanciar_mobilias_da_fase(fase_ativa)

func gerar_grid_centralizado():
	# Limpeza
	for child in get_children():
		child.queue_free()
	
	if not cena_tile: return

	# CÁLCULO DO OFFSET (O SEGREDO DO CENTRO)
	# Subtraímos 1 do total para que o centro do grid fique exatamente no (0,0)
	# Ex: Se colunas for 10 e tamanho for 2, a largura total é 20.
	# O centro será (10 - 1) * 2 / 2 = 9.0 de deslocamento.
	var offset_x = (float(colunas - 1) * tamanho_tile) / 2.0
	var offset_z = (float(linhas - 1) * tamanho_tile) / 2.0

	for x in range(colunas):
		for z in range(linhas):
			var novo_tile = cena_tile.instantiate()
			
			# Posição original multiplicada pelo tamanho, menos o deslocamento central
			var pos_x = (x * tamanho_tile) - offset_x
			var pos_z = (z * tamanho_tile) - offset_z
			
			novo_tile.position = Vector3(pos_x, 0, pos_z)
			novo_tile.name = "Tile_%d_%d" % [x, z]
			
			add_child(novo_tile)
			
	print("✅ Grid Centralizado Gerado: ", colunas, "x", linhas)

# Ajuste nas funções de conversão para respeitar o novo centro:
func mundo_para_grid(posicao_mundo: Vector3) -> Vector2i:
	var offset_x = (float(colunas - 1) * tamanho_tile) / 2.0
	var offset_z = (float(linhas - 1) * tamanho_tile) / 2.0
	
	var x = round((posicao_mundo.x + offset_x) / tamanho_tile)
	var z = round((posicao_mundo.z + offset_z) / tamanho_tile)
	return Vector2i(x, z)

func instanciar_mobilias_da_fase(fase: Fases.Fase):
	if !mobilia_automatica:
		return
		
	var offset_x = (float(colunas - 1) * tamanho_tile) / 2.0
	var offset_z = (float(linhas - 1) * tamanho_tile) / 2.0

	for id_mobilia in fase.dados_mobilias:
		# 1. Busca os dados lógicos e o CAMINHO da cena na Global
		# Se você padronizou tudo para snake_case, remova o .capitalize()
		var info_logica = Mobilias.pegar_mobilia(id_mobilia) 
		
		if not info_logica:
			print("❌ ERRO: A mobília '%s' não existe na Global Mobilias.gd!" % id_mobilia)
			continue

		# 2. Verifica se o caminho da cena foi definido
		if info_logica.cena_path == "":
			print("⚠️ AVISO: A mobília '%s' está na Global, mas o 'cena_path' está vazio!" % id_mobilia)
			continue

		# 3. Carrega e Instancia a cena dinamicamente
		var recurso_cena = load(info_logica.cena_path)
		if not recurso_cena:
			print("❌ ERRO: Não foi possível carregar o arquivo em: %s" % info_logica.cena_path)
			continue
			
		var objeto = recurso_cena.instantiate()
		add_child(objeto)
		
		# --- TRANSFERÊNCIA DE INFORMAÇÕES (O CHEQUE) ---
		objeto.set("nome_display", info_logica.nome)
		objeto.set("descricao", info_logica.descricao)

		for chave in info_logica.particularidades:
			var valor = info_logica.particularidades[chave]
			if chave in objeto:
				objeto.set(chave, valor)
			else:
				print("⚠️ AVISO: Variável '%s' não existe no script de '%s'!" % [chave, id_mobilia])

		# --- CONFIGURAÇÕES FÍSICAS ---
		var escala_final = info_logica.minha_scala
		objeto.scale = Vector3.ONE * escala_final

		# Posicionamento Grid
		var dados_fase = fase.dados_mobilias[id_mobilia]
		var pos_x = (dados_fase.x * tamanho_tile) - offset_x
		var pos_z = (dados_fase.y * tamanho_tile) - offset_z

		# Ajuste de altura baseado no seu divisor 1.5
		var altura_y = escala_final / 1.5
		objeto.position = Vector3(pos_x, altura_y, pos_z)

		objeto.name = "Mobilia_" + id_mobilia
		print("✅ %s (ID: %s) instanciado via Path!" % [info_logica.nome, id_mobilia])
