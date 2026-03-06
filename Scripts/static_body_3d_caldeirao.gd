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
@export var indice_surface_holograma : int = 2 # <-- NOVO: Altere aqui no Inspector!
@export var nome_no_bolhas : String = "GPUParticles3D_Bolhas"
var escala_original_total : Vector3

func _on_area_3d_monitor_body_entered(body):
	print("Corpo detectado: ", body.name)
	if pronto_para_coleta:
		# Ajuste dinâmico para o requisito de coleta
		if "nome_item" in body and body.nome_item != requisito_de_coleta:
			_rejeitar_item(body)
			return
			
	if "nome_item" in body:
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
	
	var corpo_layer = novo_item.collision_layer
	var corpo_mask = novo_item.collision_mask
	
	var area_monitor = novo_item.get_node_or_null("Area3D_Monitor")
	var area_layer = 0
	var area_mask = 0
	
	if area_monitor:
		area_layer = area_monitor.collision_layer
		area_mask = area_monitor.collision_mask
		area_monitor.collision_layer = 0
		area_monitor.collision_mask = 0

	novo_item.collision_layer = 0
	novo_item.collision_mask = 0
	
	get_tree().root.add_child(novo_item)
	novo_item.nome_item = nome_do_item
	novo_item.global_position = global_position + Vector3(0, 1.8, 0)
	
	if novo_item is RigidBody3D:
		var direcao = Vector3(randf_range(-1, 1), 1.5, randf_range(-1, 1)).normalized()
		novo_item.apply_central_impulse(direcao * 7.0)

	_esperar_saida_segura(novo_item, corpo_layer, corpo_mask, area_layer, area_mask)

func _esperar_saida_segura(item, c_layer, c_mask, a_layer, a_mask):
	var distancia_minima = 2.0 
	
	while is_instance_valid(item) and item.global_position.distance_to(self.global_position) < distancia_minima:
		await get_tree().physics_frame
	
	if is_instance_valid(item):
		item.collision_layer = c_layer
		item.collision_mask = c_mask
		
		var area = item.get_node_or_null("Area3D_Monitor")
		if area:
			area.collision_layer = a_layer
			area.collision_mask = a_mask
		
		print("Poção liberada com camadas originais: Corpo(", c_layer, ") Area(", a_layer, ")")	

func elastico():
	if objeto_visual == null: return

	var escala_squash = Vector3(
		escala_original_total.x * 0.7, 
		escala_original_total.y * 1.3, 
		escala_original_total.z * 0.7
	)
	
	var tween = create_tween()
	
	tween.tween_property(objeto_visual, "scale", escala_squash, 0.1)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(objeto_visual, "scale", escala_original_total, 0.3)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)	
	
func _rejeitar_item(item):
	if item is RigidBody3D:
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
		
		if dados.get("Mobilia", "") != meu_tipo_de_mobilia:
			continue 

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
	if not usar_holograma: return
	
	if holograma_atual != null:
		holograma_atual.queue_free()

	if cena_base_item == null or marker_holograma == null: return

	var holo = cena_base_item.instantiate()
	holograma_atual = holo
	
	var escala_desejada = 0.6
	holo.scale = Vector3(escala_desejada, 1.3, escala_desejada)
	
	marker_holograma.add_child(holo)
	holo.nome_item = nome_do_item
	holo.quantidade_atual = 1
	
	if holo is RigidBody3D:
		holo.freeze = true 
		holo.collision_layer = 0
		holo.collision_mask = 0
	
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
		barra_fundo = MeshInstance3D.new()
		var mesh_fundo = CylinderMesh.new()
		mesh_fundo.top_radius = 0.1
		mesh_fundo.bottom_radius = 0.1
		mesh_fundo.height = 1.3
		barra_fundo.mesh = mesh_fundo
		barra_fundo.rotation.z = deg_to_rad(90)
		
		var mat_fundo = StandardMaterial3D.new()
		mat_fundo.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mat_fundo.albedo_color = Color(0.1, 0.1, 0.2, 0.4) 
		mat_fundo.roughness = 0.0 
		mat_fundo.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED 
		barra_fundo.material_override = mat_fundo
		marker_barra.add_child(barra_fundo)

		barra_progresso = MeshInstance3D.new()
		var mesh_prog = CylinderMesh.new()
		mesh_prog.top_radius = 0.05 
		mesh_prog.bottom_radius = 0.05
		mesh_prog.height = 1.25
		barra_progresso.mesh = mesh_prog
		
		var mat_prog = StandardMaterial3D.new()
		mat_prog.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat_prog.blend_mode = StandardMaterial3D.BLEND_MODE_ADD 
		
		mat_prog.albedo_color = Color("#00f2ff")
		mat_prog.emission_enabled = true
		mat_prog.emission = Color("#00f2ff")
		mat_prog.emission_energy_multiplier = 4.0 
		
		barra_progresso.material_override = mat_prog
		barra_fundo.add_child(barra_progresso)
		
		barra_fundo.scale = Vector3.ZERO
		create_tween().tween_property(barra_fundo, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC)

	var cor_energia = Color("#00f2ff").lerp(Color("#2eff8c"), porcentagem)
	barra_progresso.material_override.albedo_color = cor_energia
	barra_progresso.material_override.emission = cor_energia

	var alvo_height = 1.25 * porcentagem
	var alvo_pos_y = -0.625 * (1.0 - porcentagem) 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(barra_progresso.mesh, "height", alvo_height, 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(barra_progresso, "position:y", alvo_pos_y, 0.15).set_trans(Tween.TRANS_QUAD)

	var tempo = Time.get_ticks_msec() / 1000.0
	var oscilacao = (sin(tempo * 5.0) * 0.1) + 1.0
	barra_progresso.scale.x = oscilacao
	barra_progresso.scale.z = oscilacao	
	
func alterar_cor_liquido(cor_especifica = null):
	if malha_caldeirao == null: return

	var material_liquido = malha_caldeirao.get_surface_override_material(indice_surface_liquido)
	if material_liquido == null:
		var mat_original = malha_caldeirao.mesh.surface_get_material(indice_surface_liquido)
		if mat_original:
			material_liquido = mat_original.duplicate()
			malha_caldeirao.set_surface_override_material(indice_surface_liquido, material_liquido)
		else:
			return 

	var alpha_original = material_liquido.albedo_color.a
	var cor_alvo: Color = cor_especifica if cor_especifica != null else Color(randf(), randf(), randf(), alpha_original)
	cor_alvo.a = alpha_original

	var tween = create_tween().set_parallel(true)
	tween.tween_property(material_liquido, "albedo_color", cor_alvo, 0.6)

	var particles = get_node_or_null(nome_no_bolhas)
	if particles and particles.draw_pass_1:
		var material_bolha = particles.draw_pass_1.surface_get_material(indice_surface_bolha)
		if material_bolha:
			tween.tween_property(material_bolha, "albedo_color", cor_alvo, 0.6)
			
func _somitemadicionado():
	if $"Soms/AudioStreamPlayer3D_ItemAdicionadoNoCaldeirão":
		$"Soms/AudioStreamPlayer3D_ItemAdicionadoNoCaldeirão".play()

func _sompuff():
	if $Soms/AudioStreamPlayer3D_Puff:
		$Soms/AudioStreamPlayer3D_Puff.play()
	
func coletarliquido(nomedoobjetocarregado) -> Array:
	var requisito_atendido = (requisito_de_coleta == "") or (nomedoobjetocarregado == requisito_de_coleta)
	
	if pronto_para_coleta == true and requisito_atendido:
		var nome_para_enviar = liquidodocaldeirão
		
		if holograma_atual != null:
			holograma_atual.queue_free()
			holograma_atual = null

		liquidodocaldeirão = ""
		pronto_para_coleta = false
		alternar_estado_pronto()
		alterar_cor_liquido(cor_original) 
		
		return [true, nome_para_enviar]
	else:
		return [false, nomedoobjetocarregado]
		
func alternar_estado_pronto():
	if particula_de_luz != null:
		particula_de_luz.visible = !particula_de_luz.visible

func _pegar_cor_do_holograma(holo: Node3D) -> Color:
	# 1. Damos um tempo para o sistema de 'Visual Automático' carregar o modelo 3D
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout 
	
	if not is_instance_valid(holo): return cor_original

	# 2. Busca flexível: Procura por 'Pocao', 'TabuaDePo' ou QUALQUER MeshInstance3D
	var alvo = holo.find_child("Pocao", true, false)
	if alvo == null:
		alvo = holo.find_child("TabuaDePo", true, false)
	
	# Se ainda não achou pelo nome, pega a primeira malha que encontrar lá dentro
	if alvo == null:
		var meshes = holo.find_children("*", "MeshInstance3D", true, false)
		if meshes.size() > 0:
			alvo = meshes[0]

	if alvo and (alvo is MeshInstance3D or alvo is GeometryInstance3D):
		# 3. Tenta pegar o material ativo (override ou da malha)
		var mat = alvo.get_active_material(indice_surface_holograma)
		
		# Se o active_material falhar, tentamos direto na malha (Mesh)
		if mat == null:
			mat = alvo.mesh.surface_get_material(indice_surface_holograma)
		
		if mat is StandardMaterial3D:
			print("🎯 SUCESSO! Cor extraída de: ", alvo.name, " (Surface ", indice_surface_holograma, ")")
			return mat.albedo_color
	
	print("❌ Falha: Não encontrei a Surface ", indice_surface_holograma, " no holograma ", holo.name)
	return cor_original

func _disparar_puff_colorido(cor: Color):
	_sompuff()
	if particulas_puff == null: return
	
	var mat_processo = particulas_puff.process_material
	if mat_processo is ParticleProcessMaterial:
		particulas_puff.process_material = mat_processo.duplicate()
		particulas_puff.process_material.color = cor

	particulas_puff.restart()
	particulas_puff.emitting = true
	
func _falha_na_cozinha():
	var player = get_tree().get_first_node_in_group("player") 
	if player and player.has_method("liberar_movimento"):
		player.liberar_movimento()
	
	_disparar_puff_colorido(Color(0.2, 0.2, 0.2))
	
	tempo_da_receita = 1
	cor_da_pocao = Color.WHITE
	receita_validada = false
	
	alterar_cor_liquido(cor_original)
	elastico()
	slots.clear()
	
	if holograma_atual:
		holograma_atual.queue_free()
		holograma_atual = null

func iniciar_minigame_mistura():
	mexendo_liquido = true
	indice_da_sequencia = 0
	_renderizar_setas_visuais()
	
func _unhandled_input(event):
	if not mexendo_liquido: return
	if icone_coleta: icone_coleta.visible = false
	
	for direcao in tradutor_setas.keys():
		if event.is_action_pressed(tradutor_setas[direcao]):
			_checar_passo_minigame(direcao)

func _checar_passo_minigame(direcao_apertada):
	var direcao_correta = sequencia_alvo[indice_da_sequencia]
	
	if direcao_apertada == direcao_correta:
		if indice_da_sequencia < setas_visuais.size():
			setas_visuais[indice_da_sequencia].marcar_como_acerto()
		
		indice_da_sequencia += 1
		elastico()
		
		if indice_da_sequencia >= sequencia_alvo.size():
			mexendo_liquido = false
			_limpar_setas()
			_finalizar_preparo_com_sucesso()
	else:
		mexendo_liquido = false
		_limpar_setas()
		_falha_na_cozinha()

func _limpar_setas():
	for s in setas_visuais:
		if is_instance_valid(s):
			s.queue_free()
	setas_visuais.clear()
	
func _finalizar_preparo_com_sucesso():
	if usar_puff_fumaça:
		_disparar_puff_colorido(cor_da_pocao)
	cozinhar()
	
	var player = get_tree().get_first_node_in_group("player") 
	if player and player.has_method("liberar_movimento"):
		player.liberar_movimento()
	
func interagindo_com_mobilia():
	if esperando_jogador:
		esperando_jogador = false
		iniciar_minigame_mistura()
		return
	
	if pronto_para_coleta:
		print("Tentando coletar poção pronta...")

func _animar_icone_pulsante():
	if icone_coleta == null: return
	var escala_original = icone_coleta.scale
	var escala_pulo = escala_original + Vector3(0.08, 0.08, 0.08)
	var pos_original_y = icone_coleta.position.y
	
	var tween = create_tween().set_loops()
	tween.tween_property(icone_coleta, "position:y", pos_original_y + 0.15, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(icone_coleta, "scale", escala_pulo, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(icone_coleta, "position:y", pos_original_y, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(icone_coleta, "scale", escala_original, 0.8).set_trans(Tween.TRANS_SINE)

func _renderizar_setas_visuais():
	_limpar_setas()
	var espacamento = 0.45
	var total = sequencia_alvo.size()
	var offset_inicial = -((total - 1) * espacamento) / 2.0

	for i in range(total):
		var nova_seta = cena_seta.instantiate()
		nova_seta.direcao_da_seta = sequencia_alvo[i]
		marker_setas.add_child(nova_seta)
		nova_seta.position.x = offset_inicial + (i * espacamento)
		nova_seta.position.z = 0.2 
		setas_visuais.append(nova_seta)
