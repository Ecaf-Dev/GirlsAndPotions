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



@export var cena_base_item: PackedScene # Arraste sua cena de objeto genérico aqui no Inspector
func _on_area_3d_monitor_body_entered(body):
	print("Corpo detectado: ", body.name)
	if pronto_para_coleta:
		if "nome_item" in body and body.nome_item != "Frasco Vazio":
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
	if slots.is_empty():
		print("O caldeirão está vazio!")
		elastico()
		return
	
	var todas_as_receitas = Receitas.receitas
	var nome_da_receita_feita = ""
	var sucesso = false

	for nome_id in todas_as_receitas:
		var dados = todas_as_receitas[nome_id]
		var ingredientes_receita = [dados["item1"], dados["item2"]]
		
		if slots == ingredientes_receita:
			if dados["pode_fabricar"]:
				sucesso = true
				nome_da_receita_feita = dados["nome"]
				liquidodocaldeirão = nome_da_receita_feita
				pronto_para_coleta = true
				alternar_estado_pronto()
				break

	if sucesso:
		print("RECEITA CRIADA VIA GLOBAL: ", nome_da_receita_feita)
		# --- AQUI ESTÁ A CHAMADA DO PUFF ---
		# 1. Primeiro, pegamos a cor atual do holograma (que já está azul ou vermelho)
		if holograma_atual:
			var cor_da_pocao = await _pegar_cor_do_holograma(holograma_atual)
			
			# 2. Passamos essa cor para o nosso efeito de fumaça
			_disparar_puff_colorido(cor_da_pocao)
			
			# 3. Aproveitamos para garantir que o líquido do caldeirão também use essa cor exata
			alterar_cor_liquido(cor_da_pocao)
		# ----------------------------------

	else:
		elastico()
		print("ERRO! A mistura não consta no registro global ou não está liberada.")
	
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
	if objeto_visual == null:
		print("Aviso: objeto_visual não definido no Inspector!")
		return

	# Criamos o Tween para manipulação estética
	var tween = create_tween()
	
	# 1. ESTICAR (Squash): Fica fino e alto
	# Vector3(X, Y, Z) -> Diminuímos X e Z, aumentamos Y
	tween.tween_property(objeto_visual, "scale", Vector3(0.6, 2.6, 0.8), 0.1)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	# 2. VOLTAR (Stretch): Volta ao normal com um balanço elástico
	tween.tween_property(objeto_visual, "scale", Vector3(0.8, 2.9, 1.0), 0.3)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)
		
	
func _rejeitar_item(item):
	if item is RigidBody3D:
		# Empurra o item para longe do balcão (em arco)
		var direcao = (item.global_position - global_position).normalized()
		item.apply_central_impulse(direcao * 4.0 + Vector3.UP * 3.0)
	elastico()

func _conectar_as_receitas():
	print("--- INICIANDO LEITURA DE RECEITAS ---")
	
	# Assumindo que seu AutoLoad se chama 'Receitas' e a variável lá dentro é 'receitas'
	var todas_as_receitas = Receitas.receitas 
	
	for nome_pocao in todas_as_receitas:
		var dados = todas_as_receitas[nome_pocao]
		
		# Pegamos os ingredientes e as condições
		var item1 = dados["item1"]
		var item2 = dados["item2"]
		var prestigio = dados["prestigio_minimo"]
		
		print("Poção: ", nome_pocao, " | Ingredientes: [", item1, ", ", item2, "] | Prestígio: ", prestigio)
	
	print("--- FIM DA LEITURA ---")

func _ready():
	_conectar_as_receitas()

func _receita_compativel(itens: Array):
	print("--- Caldeirão está analisando os itens atuais ---")
	alterar_cor_liquido()
	if itens.is_empty():
		print("Estado: Vazio")
		return null

	# 1. Monitoramento dos Slots (Mantido)
	for i in range(itens.size()):
		if i < MAX_SLOTS:
			print("Slot ", i, ": ", itens[i])
		else:
			print("ITEM EXCEDENTE: ", itens[i])
	
	print("Total de itens: ", itens.size(), "/", MAX_SLOTS)
	
	# 2. Checagem de Transbordamento (Mantido)
	if itens.size() > MAX_SLOTS:
		print("AVISO: Caldeirão transbordando!")
		return null 

	# 3. COMPARATIVO COM O GLOBAL (Ajustado para ORDEM RÍGIDA)
	# Não usamos mais o .sort(), pois a ordem importa!
	var itens_atuais = itens.duplicate() 
	
	var todas_as_receitas = Receitas.receitas
	var receita_encontrada = null

	for nome_id in todas_as_receitas:
		var dados = todas_as_receitas[nome_id]
		# Criamos a lista da receita na ordem exata definida no Global
		var ingredientes_receita = [dados["item1"], dados["item2"]]
		
		# A comparação agora só é verdadeira se os itens entrarem na mesma sequência
		if itens_atuais == ingredientes_receita:
			receita_encontrada = dados
			break
	
	# 4. VALIDAÇÃO DE PERMISSÃO E TEMPO
	if receita_encontrada != null:
		if receita_encontrada["pode_fabricar"] == true:
			print("SUCESSO: Ordem correta e receita liberada! -> ", receita_encontrada["nome"])
			tempo_da_receita = receita_encontrada["tempo_de_cozinha"]
			receita_validada = true
			_mostrarHolograma(receita_encontrada["nome"])
			if holograma_atual:
				cor_da_pocao = await _pegar_cor_do_holograma(holograma_atual)
				
				alterar_cor_liquido(cor_da_pocao)
			return receita_encontrada
		else:
			print("BLOQUEADO: Ordem correta para ", receita_encontrada["nome"], ", mas fabricação não permitida!")
			receita_validada = false
			return null
			
	else:
		if itens.size() == MAX_SLOTS:
			print("ERRO: Ingredientes na ordem errada ou receita inexistente.")
			receita_validada = false
		else:
			print("AGUARDANDO: Continue a sequência de ingredientes...")
		return null
		
func cozinhando_pocao():
	if cozinhando: return 

	# --- VERIFICAÇÃO DE SEGURANÇA ANTES DE COMEÇAR ---
	if slots.is_empty() or receita_validada == false:
		tempo_da_receita = 1 # Força 1 segundo se não for uma receita válida
	# ------------------------------------------------

	print("--- INICIANDO PREPARO --- Tempo:", tempo_da_receita)
	cozinhando = true
	
	# Agora o range vai usar o valor atualizado (1 para erro, ou X para sucesso)
	for segundo in range(tempo_da_receita + 1):
		var progresso = float(segundo) / float(tempo_da_receita)
		_gerenciar_barra_visual(progresso)
		
		if segundo < tempo_da_receita:
			await get_tree().create_timer(1.0).timeout
	
	_gerenciar_barra_visual(0) 

	# Decisão baseada na validação
	if receita_validada == true and not slots.is_empty():
		_disparar_puff_colorido(cor_da_pocao)
		cozinhar()
		if icone_coleta:
			icone_coleta.visible = true
	else:
		_falha_na_cozinha()
	
	cozinhando = false
	
func _mostrarHolograma(nome_do_item):
	# Se já existir um holograma (talvez de uma tentativa anterior), removemos
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

	# 1. Definir a cor alvo (mantendo sua lógica anterior)
	var material_liquido = malha_caldeirao.get_surface_override_material(1)
	if material_liquido == null:
		material_liquido = malha_caldeirao.mesh.surface_get_material(1).duplicate()
		malha_caldeirao.set_surface_override_material(1, material_liquido)
	
	var alpha_original = material_liquido.albedo_color.a
	var cor_alvo: Color
	
	if cor_especifica != null:
		cor_alvo = cor_especifica
	else:
		cor_alvo = Color(randf(), randf(), randf(), alpha_original)
	
	cor_alvo.a = alpha_original

	# 2. TWEEN para o Líquido
	var tween = create_tween().set_parallel(true) # .set_parallel faz as duas cores mudarem juntas
	tween.tween_property(material_liquido, "albedo_color", cor_alvo, 0.6)

	# 3. SINCRONIZAR AS BOLHAS
	var particles = $GPUParticles3D_Bolhas # Certifique-se que o nome está correto
	if particles:
		# Acessamos o material da esfera que está no Draw Pass 1
		# No Godot 4, precisamos pegar o material da malha do pass
		var material_bolha = particles.draw_pass_1.surface_get_material(0)
		
		# Se o material não for único, vamos torná-lo único para não afetar outros caldeirões
		if material_bolha:
			# Criamos um tween para a cor da bolha acompanhar
			tween.tween_property(material_bolha, "albedo_color", cor_alvo, 0.6)

func _somitemadicionado():
	$"Soms/AudioStreamPlayer3D_ItemAdicionadoNoCaldeirão".play()

func _sompuff():
	$Soms/AudioStreamPlayer3D_Puff.play()
	
func coletarliquido(nomedoobjetocarregado) -> Array:
	if nomedoobjetocarregado == "Frasco Vazio" and pronto_para_coleta == true:
		print("Coleta permitida!")
		
		# 1. Guardamos o nome da poção
		var nome_para_enviar = liquidodocaldeirão
		
		# --- LIMPEZA DOS VISUAIS (O que você queria na etapa 3) ---
		if holograma_atual != null:
			holograma_atual.queue_free()
			holograma_atual = null # Importante para não dar erro de instância inválida depois
		
		if icone_coleta != null:
			icone_coleta.visible = false
		# ---------------------------------------------------------
		
		# 2. Resetamos o estado do caldeirão
		liquidodocaldeirão = ""
		pronto_para_coleta = false
		alternar_estado_pronto()
		alterar_cor_liquido(cor_original) # Volta para a cor padrão
		
		return [true, nome_para_enviar]
		
	else:
		print("Não pode coletar!")
		return [false, "Frasco Vazio"]

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

# --- INTEGRAÇÃO NA SUA FUNÇÃO EXISTENTE ---
# Procure a função onde a poção fica pronta (cozinhando_pocao ou cozinhar)
