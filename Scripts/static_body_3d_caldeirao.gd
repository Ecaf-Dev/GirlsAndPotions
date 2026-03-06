extends StaticBody3D

# Lista que servirá como nossos slots
var slots = [] 
@export var MAX_SLOTS = 2
@export var objeto_visual : Node3D

@export var marker_holograma : Marker3D
var holograma_atual : Node3D = null # Para podermos apagar depois

@export var marker_barra : Marker3D
var barra_fundo : MeshInstance3D = null
var barra_progresso : MeshInstance3D = null

@onready var malha_caldeirao = $"Caldeirão"
var cor_original = Color(0.0, 0.4, 0.9)

var tempo_da_receita = 1
var receita_validada = false
var cozinhando = false

var liquidodocaldeirão: String = ""
var pronto_para_coleta: bool = false
@export var icone_coleta : Sprite3D # Arraste um ícone de "mão" ou "seta" aqui

@onready var particula_de_luz = $GPUParticles3D_Sucesso
# Dicionário com todas as receitas possíveis, está obsoleto!

@onready var particulas_puff = $GPUParticles3D_Puff
var cor_da_pocao : Color = Color.WHITE

var meu_tipo_de_mobilia : String = ""

@export var cena_base_item: PackedScene # Arraste sua cena de objeto genérico aqui no Inspector

var mexendo_liquido : bool = false
var indice_da_sequencia : int = 0
var sequencia_alvo : Array = []
var nome_receita_atual : String = ""
var esperando_jogador: bool = false
# Tradutor para o Godot entender suas palavras do Receitas.gd
var tradutor_setas = {
	"Cima": "ui_up",
	"Baixo": "ui_down",
	"Esquerda": "ui_left",
	"Direita": "ui_right"
}

@export var sprite_z : Sprite3D

@export_group("Minigame de Mistura")
@export var cena_seta : PackedScene # Arraste aqui o Node3D_Seta.tscn
@onready var marker_setas = $Marker3D_Setas # Certifique-se que o nome no nó é exatamente este
var setas_visuais : Array = [] # Guardará as instâncias para podermos trocar a cor ou deletar

@export_group("Configurações de Feedback")
@export var usar_puff_fumaça : bool = true
@export var usar_holograma : bool = true
@export var usar_barra_progresso : bool = true

@export var requisito_de_coleta : String = "Flor Da Vida"

@export_group("Configurações de Malha")
@export var indice_surface_liquido : int = 1
@export var indice_surface_bolha : int = 0
@export var nome_no_bolhas : String = "GPUParticles3D_Bolhas"
var escala_original_total : Vector3

func _on_area_3d_monitor_body_entered(body):
	print("Corpo detectado: ", body.name)
	if pronto_para_coleta:
		if "nome_item" in body and body.nome_item != "Frasco Vazio" :
			_rejeitar_item(body)
			return
			
	if "nome_item" in body :
		if slots.size() < MAX_SLOTS && body.quantidade_atual == 1 && cozinhando == false:
			slots.append(body.nome_item)
			print("Item adicionado ao slot: ", body.nome_item)
			print("Estado atual dos slots: ", slots)
			_somitemadicionado()
			_receita_compativel(slots)
			body.queue_free()
			elastico()
		elif (body.quantidade_atual >= 2) && cozinhando == false:
			_rejeitar_item(body)
			print("Isso n é ingrediente")
		else:
			_rejeitar_item(body)
			print("Caldeirão cheio!")

func cozinhar():
	if slots.is_empty(): return
	
	var todas = Receitas.receitas
	var receita_feita = null

	for id in todas:
		if slots == _pegar_ingredientes_da_config(todas[id]) and todas[id]["pode_fabricar"]:
			receita_feita = todas[id]
			break

	if receita_feita:
		liquidodocaldeirão = receita_feita["nome"]
		pronto_para_coleta = true
		alternar_estado_pronto()
		if holograma_atual:
			var cor = await _pegar_cor_do_holograma(holograma_atual)
			alterar_cor_liquido(cor)
	else:
		_falha_na_cozinha()
	
	slots.clear()
	
func _instanciarobjeto(nome_do_item):
	elastico()
	if cena_base_item == null: return

	var novo_item = cena_base_item.instantiate()
	
	# --- PASSO 1: CAPTURAR A IDENTIDADE ORIGINAL ---
	# Guardamos os layers do RigidBody (O objeto em si)
	var corpo_layer = novo_item.collision_layer
	var corpo_mask = novo_item.collision_mask
	
	# Guardamos os layers da Area3D (O monitor de proximidade)
	var area_monitor = novo_item.get_node_or_null("Area3D_Monitor")
	var area_layer = 0
	var area_mask = 0
	
	if area_monitor:
		area_layer = area_monitor.collision_layer
		area_mask = area_monitor.collision_mask
		# Desativamos a área para ela não ser "engolida" de volta
		area_monitor.collision_layer = 0
		area_monitor.collision_mask = 0

	# Desativamos o corpo para ele não colidir com a borda do caldeirão ao sair
	novo_item.collision_layer = 0
	novo_item.collision_mask = 0
	
	# --- PASSO 2: NASCIMENTO E IMPULSO ---
	get_tree().root.add_child(novo_item)
	novo_item.nome_item = nome_do_item
	novo_item.global_position = global_position + Vector3(0, 1.8, 0)
	
	if novo_item is RigidBody3D:
		var direcao = Vector3(randf_range(-1, 1), 1.5, randf_range(-1, 1)).normalized()
		novo_item.apply_central_impulse(direcao * 7.0)

	# --- PASSO 3: A ESPERA SEGURA ---
	# Passamos todos os dados originais para a função de espera
	_esperar_saida_segura(novo_item, corpo_layer, corpo_mask, area_layer, area_mask)

func _esperar_saida_segura(item, c_layer, c_mask, a_layer, a_mask):
	var distancia_minima = 2.0 
	
	while is_instance_valid(item) and item.global_position.distance_to(self.global_position) < distancia_minima:
		await get_tree().physics_frame
	
	# --- PASSO 4: RESTAURAR TUDO AO ORIGINAL ---
	if is_instance_valid(item):
		# Restaura o corpo (RigidBody)
		item.collision_layer = c_layer
		item.collision_mask = c_mask
		
		# Restaura a área (Area3D)
		var area = item.get_node_or_null("Area3D_Monitor")
		if area:
			area.collision_layer = a_layer
			area.collision_mask = a_mask
		
		print("Poção liberada com camadas originais: Corpo(", c_layer, ") Area(", a_layer, ")")	

func elastico():
	if objeto_visual == null: return

	# 2. Usamos a escala salva no _ready para calcular a deformação de 30%
	var escala_squash = Vector3(
		escala_original_total.x * 0.7, 
		escala_original_total.y * 1.3, 
		escala_original_total.z * 0.7
	)
	
	var tween = create_tween()
	
	# ESTICAR (Squash)
	tween.tween_property(objeto_visual, "scale", escala_squash, 0.1)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	# VOLTAR (Stretch) - Retorna para a escala salva no início
	tween.tween_property(objeto_visual, "scale", escala_original_total, 0.3)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)	
	
func _rejeitar_item(item):
	if item is RigidBody3D:
		# Empurra o item para longe do balcão (em arco)
		var direcao = (item.global_position - global_position).normalized()
		item.apply_central_impulse(direcao * 4.0 + Vector3.UP * 3.0)
	elastico()

func _conectar_as_receitas():
	print("--- LISTA DE RECEITAS PARA ", meu_tipo_de_mobilia, " ---")
	var todas = Receitas.receitas 
	for id in todas:
		if todas[id].get("Mobilia") == meu_tipo_de_mobilia:
			var ing = _pegar_ingredientes_da_config(todas[id])
			print("-> ", id, " Ingredientes: ", ing)

func _ready():
	if objeto_visual:
		escala_original_total = objeto_visual.scale
	meu_tipo_de_mobilia = name.replace("StaticBody3D_", "")
	print("Eu sou uma mobília do tipo: ", meu_tipo_de_mobilia)
	_conectar_as_receitas()
	
func _pegar_ingredientes_da_config(dados_da_receita: Dictionary) -> Array:
	var lista_resultante = []
	for i in range(1, 9):
		var chave = "item" + str(i)
		if dados_da_receita.has(chave):
			lista_resultante.append(dados_da_receita[chave])
	return lista_resultante
	
func _receita_compativel(itens: Array):
	alterar_cor_liquido()
	if itens.is_empty(): return null

	var todas_as_receitas = Receitas.receitas
	var receita_encontrada = null

	for nome_id in todas_as_receitas:
		var dados = todas_as_receitas[nome_id]
		
		# Filtro de Mobília
		if dados.get("Mobilia", "") != meu_tipo_de_mobilia:
			continue 

		# Comparação dinâmica (independente de ser 1 ou 8 itens)
		if itens == _pegar_ingredientes_da_config(dados):
			receita_encontrada = dados
			break
	
	if receita_encontrada != null:
		if receita_encontrada.get("pode_fabricar", false):
			print("✅ Receita Identificada: ", receita_encontrada["nome"])
			tempo_da_receita = receita_encontrada.get("tempo_de_cozinha", 1)
			receita_validada = true
			
			if usar_holograma:
				_mostrarHolograma(receita_encontrada["nome"])
				await get_tree().process_frame
				if holograma_atual:
					cor_da_pocao = await _pegar_cor_do_holograma(holograma_atual)
					alterar_cor_liquido(cor_da_pocao)
			return receita_encontrada
	
	receita_validada = false
	return null
				
func cozinhando_pocao():
	if cozinhando or mexendo_liquido: return 

	if not slots.is_empty() and receita_validada:
		var todas = Receitas.receitas
		for id in todas:
			if slots == _pegar_ingredientes_da_config(todas[id]):
				sequencia_alvo = todas[id].get("Sequencia", [])
				nome_receita_atual = id
				break

	cozinhando = true
	# Só mostra a barra se houver tempo de espera (Mortar com tempo 0 pula isso)
	if usar_barra_progresso and tempo_da_receita > 0:
		for segundo in range(tempo_da_receita + 1):
			_gerenciar_barra_visual(float(segundo) / float(tempo_da_receita))
			if segundo < tempo_da_receita: await get_tree().create_timer(1.0).timeout
	
	_gerenciar_barra_visual(0)
	cozinhando = false

	if receita_validada and not slots.is_empty():
		if sequencia_alvo.is_empty():
			_finalizar_preparo_com_sucesso()
		else:
			esperando_jogador = true
			if icone_coleta:
				icone_coleta.visible = true
				_animar_icone_pulsante()
	else:
		_falha_na_cozinha()		
func _mostrarHolograma(nome_do_item):
	# Se já existir um holograma (talvez de uma tentativa anterior), removemos
	if not usar_holograma: return
	
	if holograma_atual != null:
		holograma_atual.queue_free()

	if cena_base_item == null or marker_holograma == null: return

	# Instanciamos a base
	var holo = cena_base_item.instantiate()
	holograma_atual = holo
	
	# Aqui você define o tamanho (ex: 0.5 é metade do tamanho original)
	var escala_desejada = 0.6
	holo.scale = Vector3(escala_desejada, 1.3, escala_desejada)
	
	# Adicionamos ao Marker
	marker_holograma.add_child(holo)
	
	# Definimos a identidade para carregar a malha/modelo correto
	holo.nome_item = nome_do_item
	holo.quantidade_atual = 1
	
	# --- TORNANDO-O UM HOLOGRAMA (VISUAL APENAS) ---
	# 1. Desativa a gravidade e colisões se for RigidBody
	if holo is RigidBody3D:
		holo.freeze = true # Congela no lugar
		holo.collision_layer = 0
		holo.collision_mask = 0
	
	# 2. Desativa o monitor de proximidade dele
	var area = holo.get_node_or_null("Area3D_Monitor")
	if area:
		area.collision_layer = 0
		area.collision_mask = 0

	
	print("Holograma de ", nome_do_item, " projetado!")

func _gerenciar_barra_visual(porcentagem: float):
	if porcentagem <= 0 or porcentagem >= 1.0:
		if barra_fundo:
			var t = create_tween().set_parallel(true)
			t.tween_property(barra_fundo, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
			t.finished.connect(func(): 
				if barra_fundo: barra_fundo.queue_free()
				barra_fundo = null
				barra_progresso = null
			)
		return

	if barra_fundo == null:
		# --- O RECEPTÁCULO (Vidro Místico) ---
		barra_fundo = MeshInstance3D.new()
		var mesh_fundo = CylinderMesh.new()
		mesh_fundo.top_radius = 0.1
		mesh_fundo.bottom_radius = 0.1
		mesh_fundo.height = 1.3
		barra_fundo.mesh = mesh_fundo
		barra_fundo.rotation.z = deg_to_rad(90)
		
		var mat_fundo = StandardMaterial3D.new()
		mat_fundo.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mat_fundo.albedo_color = Color(0.1, 0.1, 0.2, 0.4) # Azul escuro "etéreo"
		mat_fundo.roughness = 0.0 # Reflexo de vidro
		mat_fundo.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED # Fundo que não recebe sombra
		barra_fundo.material_override = mat_fundo
		marker_barra.add_child(barra_fundo)

		# --- O NÚCLEO MÁGICO (Energia) ---
		barra_progresso = MeshInstance3D.new()
		var mesh_prog = CylinderMesh.new()
		mesh_prog.top_radius = 0.05 
		mesh_prog.bottom_radius = 0.05
		mesh_prog.height = 1.25
		barra_progresso.mesh = mesh_prog
		
		var mat_prog = StandardMaterial3D.new()
		mat_prog.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat_prog.blend_mode = StandardMaterial3D.BLEND_MODE_ADD # MODO ADITIVO: Brilha intensamente!
		
		# Cor de Energia Mágica (Cyan/Neon)
		mat_prog.albedo_color = Color("#00f2ff")
		mat_prog.emission_enabled = true
		mat_prog.emission = Color("#00f2ff")
		mat_prog.emission_energy_multiplier = 4.0 # Brilho muito forte
		
		barra_progresso.material_override = mat_prog
		barra_fundo.add_child(barra_progresso)
		
		# Animação de entrada Estelar
		barra_fundo.scale = Vector3.ZERO
		create_tween().tween_property(barra_fundo, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC)

	# --- Lógica de Cor "Alquímica" ---
	# A energia muda de Azul Neon para Verde Esmeralda quando completa
	var cor_energia = Color("#00f2ff").lerp(Color("#2eff8c"), porcentagem)
	barra_progresso.material_override.albedo_color = cor_energia
	barra_progresso.material_override.emission = cor_energia

	# --- Atualização do Tamanho (Com Suavidade) ---
	var alvo_height = 1.25 * porcentagem
	var alvo_pos_y = -0.625 * (1.0 - porcentagem) 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(barra_progresso.mesh, "height", alvo_height, 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(barra_progresso, "position:y", alvo_pos_y, 0.15).set_trans(Tween.TRANS_QUAD)

	# --- EFEITO DE PULSAÇÃO "VIVA" ---
	# Faz o brilho oscilar levemente como se estivesse respirando
	var tempo = Time.get_ticks_msec() / 1000.0
	var oscilacao = (sin(tempo * 5.0) * 0.1) + 1.0
	barra_progresso.scale.x = oscilacao
	barra_progresso.scale.z = oscilacao	
	
func alterar_cor_liquido(cor_especifica = null):
	if malha_caldeirao == null: return

	# 1. Acessa a Surface correta do líquido baseada no Inspector
	var material_liquido = malha_caldeirao.get_surface_override_material(indice_surface_liquido)
	if material_liquido == null:
		# Se não houver override, duplicamos o material da malha para não afetar outros objetos
		var mat_original = malha_caldeirao.mesh.surface_get_material(indice_surface_liquido)
		if mat_original:
			material_liquido = mat_original.duplicate()
			malha_caldeirao.set_surface_override_material(indice_surface_liquido, material_liquido)
		else:
			return # Caso o índice esteja errado e não encontre material

	var alpha_original = material_liquido.albedo_color.a
	var cor_alvo: Color
	
	if cor_especifica != null:
		cor_alvo = cor_especifica
	else:
		# Cor aleatória mantendo a transparência original
		cor_alvo = Color(randf(), randf(), randf(), alpha_original)
	
	cor_alvo.a = alpha_original

	# 2. TWEEN para transição suave da cor
	var tween = create_tween().set_parallel(true)
	tween.tween_property(material_liquido, "albedo_color", cor_alvo, 0.6)

	# 3. SINCRONIZAR AS BOLHAS (Se existirem)
	var particles = get_node_or_null(nome_no_bolhas)
	if particles and particles.draw_pass_1:
		# Acessamos o material da malha das bolhas baseado no índice do Inspector
		var malha_bolha = particles.draw_pass_1
		var material_bolha = malha_bolha.surface_get_material(indice_surface_bolha)
		
		if material_bolha:
			# Se o material não for único, criamos um override local para as partículas
			# Nota: No Godot 4, para partículas, às vezes é melhor usar o material_override do nó
			tween.tween_property(material_bolha, "albedo_color", cor_alvo, 0.6)
			
func _somitemadicionado():
	$"Soms/AudioStreamPlayer3D_ItemAdicionadoNoCaldeirão".play()

func _sompuff():
	$Soms/AudioStreamPlayer3D_Puff.play()
	
func coletarliquido(nomedoobjetocarregado) -> Array:
	# 1. Verificamos se a coleta atende ao requisito configurado no Inspector
	# Se requisito_de_coleta for "", qualquer coisa (inclusive mão vazia) coleta.
	var requisito_atendido = (requisito_de_coleta == "") or (nomedoobjetocarregado == requisito_de_coleta)
	
	if pronto_para_coleta == true and requisito_atendido:
		print("✅ Coleta permitida! Item usado: ", nomedoobjetocarregado if nomedoobjetocarregado != "" else "Mão Vazia")
		
		# Guardamos o nome do resultado (Ex: "Flor Da Vida")
		var nome_para_enviar = liquidodocaldeirão
		
		# --- LIMPEZA E RESET ---
		if holograma_atual != null:
			holograma_atual.queue_free()
			holograma_atual = null

		liquidodocaldeirão = ""
		pronto_para_coleta = false
		alternar_estado_pronto()
		alterar_cor_liquido(cor_original) 
		
		return [true, nome_para_enviar]
		
	else:
		# Feedback de erro no console para sabermos por que falhou
		if not pronto_para_coleta:
			print("❌ Erro: O item ainda não está pronto para coleta.")
		elif not requisito_atendido:
			print("❌ Erro: Item errado. Esperado: '", requisito_de_coleta, "' mas recebeu: '", nomedoobjetocarregado, "'")
			
		return [false, nomedoobjetocarregado]
		
func alternar_estado_pronto():
	if particula_de_luz != null:
		if particula_de_luz.visible == true :
			particula_de_luz.visible = false
		else:
			particula_de_luz.visible = true

func _pegar_cor_do_holograma(holo: Node3D) -> Color:
	# 1. Espera a montagem completa dos nós
	await get_tree().process_frame
	await get_tree().process_frame
	
	if not is_instance_valid(holo): return cor_original

	# 2. Busca recursiva (true) por QUALQUER nó que se chame "Pocao"
	# Usamos find_child porque ele varre todos os níveis abaixo do holograma
	var alvo = holo.find_child("Pocao", true, false)
	
	print("Alvo 'Pocao' encontrado: ", alvo)

	if alvo and (alvo is MeshInstance3D or alvo is GeometryInstance3D):
		# 3. Verificamos se ele tem a Surface 2 (o seu 3º albedo)
		# No Godot: 0 = vidro, 1 = detalhe, 2 = LÍQUIDO
		var mat = alvo.get_active_material(2)
		
		if mat is StandardMaterial3D:
			print("🎯 SUCESSO! Cor extraída do albedo 2 do nó Pocao: ", mat.albedo_color)
			return mat.albedo_color
		else:
			print("⚠️ O nó 'Pocao' foi achado, mas o material não é StandardMaterial3D.")
	
	print("❌ Falha: Não encontrei o nó 'Pocao' com as surfaces necessárias.")
	return cor_original
	print("⚠️ Não achei a Surface 2 nas malhas do holograma.")
	return cor_original

func _disparar_puff_colorido(cor: Color):
	print("puff")
	_sompuff()
	if particulas_puff == null: return
	
	
	# 1. Pegamos o material das partículas para mudar a cor
	var mat_processo = particulas_puff.process_material
	if mat_processo is ParticleProcessMaterial:
		# Criamos uma cópia única para não afetar outros caldeirões
		particulas_puff.process_material = mat_processo.duplicate()
		
		# Ajustamos a cor base (Albedo) do material de processo
		particulas_puff.process_material.color = cor

	# 2. Reiniciamos e emitimos as partículas (Efeito One Shot)
	particulas_puff.restart() # Garante que comece do zero
	particulas_puff.emitting = true
	
	# 3. Som opcional do "Puff"
	# if $Soms/Som_Puff: $Soms/Som_Puff.play()
func _falha_na_cozinha():
	print("🔥 FALHA: A mistura explodiu!")
	
	var player = get_tree().get_first_node_in_group("player") # Certifique-se que o Player está no grupo "player"
	if player and player.has_method("liberar_movimento"):
		player.liberar_movimento()
	
	# 1. Puff Cinza (Forçado)
	var cor_fuligem = Color(0.2, 0.2, 0.2) 
	_disparar_puff_colorido(cor_fuligem)
	
	# 2. RESET TOTAL DE VARIÁVEIS
	tempo_da_receita = 1     # Reseta o tempo para o padrão de erro
	cor_da_pocao = Color.WHITE # Limpa a cor antiga
	receita_validada = false
	
	# 3. Restante do reset visual
	alterar_cor_liquido(cor_original)
	elastico()
	slots.clear()
	
	if holograma_atual:
		holograma_atual.queue_free()
		holograma_atual = null

func iniciar_minigame_mistura():
	print("🌀 MISTURE AGORA!")
	mexendo_liquido = true
	indice_da_sequencia = 0
	_renderizar_setas_visuais() # Chama a sua nova lógica de rotação
	
func _unhandled_input(event):
	if not mexendo_liquido: return
	icone_coleta.visible = false
	
	for direcao in tradutor_setas.keys():
		if event.is_action_pressed(tradutor_setas[direcao]):
			_checar_passo_minigame(direcao)

func _checar_passo_minigame(direcao_apertada):
	var direcao_correta = sequencia_alvo[indice_da_sequencia]
	
	if direcao_apertada == direcao_correta:
		# Feedback na seta visual específica
		if indice_da_sequencia < setas_visuais.size():
			setas_visuais[indice_da_sequencia].marcar_como_acerto()
		
		indice_da_sequencia += 1
		print("✅ Movimento correto!")
		elastico()
		
		if indice_da_sequencia >= sequencia_alvo.size():
			print("✨ Sucesso total!")
			mexendo_liquido = false
			_limpar_setas() # Função de limpeza
			_finalizar_preparo_com_sucesso()
	else:
		print("❌ Errou a sequência!")
		mexendo_liquido = false
		_limpar_setas() # Limpa mesmo no erro
		_falha_na_cozinha()

func _limpar_setas():
	for s in setas_visuais:
		if is_instance_valid(s):
			s.queue_free()
	setas_visuais.clear()
	
func _finalizar_preparo_com_sucesso():
	if usar_puff_fumaça:
		_disparar_puff_colorido(cor_da_pocao)
	cozinhar() # Aqui ele chama a sua função original que spawna a poção
	
	
	var player = get_tree().get_first_node_in_group("player") # Certifique-se que o Player está no grupo "player"
	if player and player.has_method("liberar_movimento"):
		player.liberar_movimento()
	
# --- INTEGRAÇÃO NA SUA FUNÇÃO EXISTENTE ---
func interagindo_com_mobilia():
	# Caso 1: O cozimento terminou e está esperando o jogador mexer
	if esperando_jogador:
		print("🌀 Jogador começou a mexer!")
		esperando_jogador = false
		iniciar_minigame_mistura()
		return
	
	# Caso 2: A poção já está pronta e o jogador quer coletar no frasco
	if pronto_para_coleta:
		# Aqui você chama sua lógica de coletar que já existe (coletarliquido)
		print("Tentando coletar poção pronta...")

func _animar_icone_pulsante():
	if icone_coleta == null: return
	
	# 1. Capturamos a escala que você definiu no Inspector
	var escala_original = icone_coleta.scale
	var escala_pulo = escala_original + Vector3(0.08, 0.08, 0.08)
	
	# 2. Capturamos a posição Y original
	var pos_original_y = icone_coleta.position.y
	
	var tween = create_tween().set_loops()
	
	# --- FASE 1: SUBIR E AUMENTAR ---
	# Usamos parallel() para as duas coisas acontecerem ao mesmo tempo
	tween.tween_property(icone_coleta, "position:y", pos_original_y + 0.15, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(icone_coleta, "scale", escala_pulo, 0.8).set_trans(Tween.TRANS_SINE)
	
	# --- FASE 2: DESCER E VOLTAR AO NORMAL ---
	tween.tween_property(icone_coleta, "position:y", pos_original_y, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(icone_coleta, "scale", escala_original, 0.8).set_trans(Tween.TRANS_SINE)

func _renderizar_setas_visuais():
	# 1. Limpa setas antigas
	_limpar_setas()

	# 2. Configurações de exibição
	var espacamento = 0.45
	var total = sequencia_alvo.size()
	var offset_inicial = -((total - 1) * espacamento) / 2.0

	for i in range(total):
		var nova_seta = cena_seta.instantiate()
		
		# PASSO CRUCIAL: Passar a direção ANTES do add_child
		nova_seta.direcao_da_seta = sequencia_alvo[i]
		
		# Adiciona ao marcador
		marker_setas.add_child(nova_seta)
		
		# Posiciona apenas no eixo X para criar a fila
		nova_seta.position.x = offset_inicial + (i * espacamento)
		
		# Garante que as setas fiquem um pouco à frente do caldeirão
		nova_seta.position.z = 0.2 
		
		setas_visuais.append(nova_seta)
