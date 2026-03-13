extends StaticBody3D

# --- CONFIGURAÇÕES ---
@export var MAX_SLOTS = 2
@export var objeto_visual : Node3D
@export var cena_base_item: PackedScene
@export var mobilia_automatica: bool = false

@export_group("Interface")
@export var marker_holograma : Marker3D
@export var marker_barra : Marker3D
@export var icone_coleta : Sprite3D

@export_group("Efeitos")
@onready var malha_caldeirao = $"Caldeirão"
@onready var particula_de_luz = $GPUParticles3D_Sucesso
@onready var particulas_puff = $GPUParticles3D_Puff
@onready var particulas_bolhas = $GPUParticles3D_Bolhas

# --- VARIÁVEIS DE ESTADO ---
var slots = [] 
var meu_tipo_de_mobilia : String = ""
var liquidodocaldeirão: String = ""
var cor_original = Color(0.0, 0.4, 0.9)
var cor_da_pocao : Color = Color.WHITE

var tempo_da_receita = 1
var receita_validada = false
var cozinhando = false
var pronto_para_coleta: bool = false
var holograma_atual : Node3D = null

var barra_fundo : MeshInstance3D = null
var barra_progresso : MeshInstance3D = null

# --- CICLO DE VIDA ---

func _ready():
	meu_tipo_de_mobilia = name.replace("StaticBody3D_", "")
	_conectar_as_receitas()

# --- INTERAÇÕES E SLOTS ---

func _on_area_3d_monitor_body_entered(body):
	if pronto_para_coleta:
		if "nome_item" in body and body.nome_item != "Frasco Vazio":
			_rejeitar_item(body)
		return
			
	if "nome_item" in body and !cozinhando:
		if slots.size() < MAX_SLOTS and body.quantidade_atual == 1:
			slots.append(body.nome_item)
			_somitemadicionado()
			_receita_compativel(slots)
			body.queue_free()
			elastico()
		else:
			_rejeitar_item(body)

func _receita_compativel(itens: Array):
	alterar_cor_liquido()
	if itens.size() < MAX_SLOTS: return null

	var todas_as_receitas = Receitas.receitas
	var receita_encontrada = null

	for nome_id in todas_as_receitas:
		var dados = todas_as_receitas[nome_id]
		if dados.get("Mobilia", "") != meu_tipo_de_mobilia: continue

		var ingredientes_receita = [dados["item1"], dados["item2"]]
		if itens == ingredientes_receita:
			receita_encontrada = dados
			break
	
	if receita_encontrada and receita_encontrada["pode_fabricar"]:
		receita_validada = true
		tempo_da_receita = receita_encontrada["tempo_de_cozinha"]
		_mostrarHolograma(receita_encontrada["nome"])
		if holograma_atual:
			cor_da_pocao = await _pegar_cor_do_holograma(holograma_atual)
			alterar_cor_liquido(cor_da_pocao)
		return receita_encontrada
	
	receita_validada = false
	return null

# --- LÓGICA DE PREPARO ---

func cozinhando_pocao():
	if cozinhando: return 
	
	if slots.is_empty() or !receita_validada:
		tempo_da_receita = 1 

	cozinhando = true
	for segundo in range(tempo_da_receita + 1):
		_gerenciar_barra_visual(float(segundo) / float(tempo_da_receita))
		if segundo < tempo_da_receita:
			await get_tree().create_timer(1.0).timeout
	
	_gerenciar_barra_visual(0) 

	if receita_validada and !slots.is_empty():
		_disparar_puff_colorido(cor_da_pocao)
		cozinhar()
		if icone_coleta: icone_coleta.visible = true
	else:
		_falha_na_cozinha()
	
	cozinhando = false

func cozinhar():
	var todas_as_receitas = Receitas.receitas
	var sucesso = false

	for nome_id in todas_as_receitas:
		var dados = todas_as_receitas[nome_id]
		if slots == [dados["item1"], dados["item2"]] and dados["pode_fabricar"]:
			sucesso = true
			liquidodocaldeirão = dados["nome"]
			pronto_para_coleta = true
			alternar_estado_pronto()
			break

	if sucesso and holograma_atual:
		var cor = await _pegar_cor_do_holograma(holograma_atual)
		_disparar_puff_colorido(cor)
		alterar_cor_liquido(cor)
	elif !sucesso:
		elastico()
	
	slots.clear()

# --- VISUAL E FEEDBACK ---

func _mostrarHolograma(nome_do_item):
	if holograma_atual: holograma_atual.queue_free()
	if !cena_base_item or !marker_holograma: return

	var holo = cena_base_item.instantiate()
	holograma_atual = holo
	holo.scale = Vector3(0.6, 1.3, 0.6)
	marker_holograma.add_child(holo)
	
	holo.nome_item = nome_do_item
	if holo is RigidBody3D:
		holo.freeze = true
		holo.collision_layer = 0
		holo.collision_mask = 0
	
	var area = holo.get_node_or_null("Area3D_Monitor")
	if area: area.collision_layer = 0; area.collision_mask = 0

func _gerenciar_barra_visual(porcentagem: float):
	if porcentagem <= 0 or porcentagem >= 1.0:
		if barra_fundo:
			var t = create_tween()
			t.tween_property(barra_fundo, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
			t.finished.connect(func(): 
				if barra_fundo: barra_fundo.queue_free()
				barra_fundo = null
			)
		return

	if !barra_fundo: _criar_barra_progresso()

	var cor_energia = Color("#00f2ff").lerp(Color("#2eff8c"), porcentagem)
	barra_progresso.material_override.albedo_color = cor_energia
	barra_progresso.mesh.height = 1.25 * porcentagem
	barra_progresso.position.y = -0.625 * (1.0 - porcentagem)

func _criar_barra_progresso():
	barra_fundo = MeshInstance3D.new()
	barra_fundo.mesh = CylinderMesh.new()
	barra_fundo.mesh.top_radius = 0.1; barra_fundo.mesh.bottom_radius = 0.1; barra_fundo.mesh.height = 1.3
	barra_fundo.rotation.z = deg_to_rad(90)
	
	var mat_fundo = StandardMaterial3D.new()
	mat_fundo.transparency = 1
	mat_fundo.albedo_color = Color(0.1, 0.1, 0.2, 0.4)
	barra_fundo.material_override = mat_fundo
	marker_barra.add_child(barra_fundo)

	barra_progresso = MeshInstance3D.new()
	barra_progresso.mesh = CylinderMesh.new()
	barra_progresso.mesh.top_radius = 0.05; barra_progresso.mesh.bottom_radius = 0.05
	
	var mat_prog = StandardMaterial3D.new()
	mat_prog.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_prog.albedo_color = Color("#00f2ff")
	barra_progresso.material_override = mat_prog
	barra_fundo.add_child(barra_progresso)

func alterar_cor_liquido(cor_especifica = null):
	if !malha_caldeirao: return
	var mat = malha_caldeirao.get_surface_override_material(1)
	if !mat:
		mat = malha_caldeirao.mesh.surface_get_material(1).duplicate()
		malha_caldeirao.set_surface_override_material(1, mat)
	
	var cor_alvo = cor_especifica if cor_especifica else Color(randf(), randf(), randf(), mat.albedo_color.a)
	cor_alvo.a = mat.albedo_color.a

	var tween = create_tween().set_parallel(true)
	tween.tween_property(mat, "albedo_color", cor_alvo, 0.6)

	if particulas_bolhas:
		var mat_bolha = particulas_bolhas.draw_pass_1.surface_get_material(0)
		if mat_bolha: tween.tween_property(mat_bolha, "albedo_color", cor_alvo, 0.6)

func _pegar_cor_do_holograma(holo: Node3D) -> Color:
	await get_tree().process_frame
	await get_tree().process_frame
	if !is_instance_valid(holo): return cor_original
	var alvo = holo.find_child("Pocao", true, false)
	if alvo and alvo is MeshInstance3D:
		var mat = alvo.get_active_material(2)
		if mat is StandardMaterial3D: return mat.albedo_color
	return cor_original

# --- COLETA E UTILITÁRIOS ---

func coletarliquido(nomedoobjetocarregado) -> Array:
	if nomedoobjetocarregado == "Frasco Vazio" and pronto_para_coleta:
		var nome_para_enviar = liquidodocaldeirão
		if holograma_atual: holograma_atual.queue_free(); holograma_atual = null
		if icone_coleta: icone_coleta.visible = false
		
		liquidodocaldeirão = ""
		pronto_para_coleta = false
		alternar_estado_pronto()
		alterar_cor_liquido(cor_original)
		return [true, nome_para_enviar]
	return [false, "Frasco Vazio"]

func _disparar_puff_colorido(cor: Color):
	_sompuff()
	if !particulas_puff: return
	var mat_processo = particulas_puff.process_material.duplicate()
	mat_processo.color = cor
	particulas_puff.process_material = mat_processo
	particulas_puff.restart()
	particulas_puff.emitting = true

func _falha_na_cozinha():
	_disparar_puff_colorido(Color(0.2, 0.2, 0.2))
	tempo_da_receita = 1
	receita_validada = false
	alterar_cor_liquido(cor_original)
	elastico()
	slots.clear()
	if holograma_atual: holograma_atual.queue_free(); holograma_atual = null

func elastico():
	if !objeto_visual: return
	var tween = create_tween()
	tween.tween_property(objeto_visual, "scale", Vector3(0.6, 2.6, 0.8), 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(objeto_visual, "scale", Vector3(0.8, 2.9, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)

func _rejeitar_item(item):
	if item is RigidBody3D:
		var dir = (item.global_position - global_position).normalized()
		item.apply_central_impulse(dir * 4.0 + Vector3.UP * 3.0)
	elastico()

func _conectar_as_receitas():
	var todas = Receitas.receitas 
	for id in todas:
		print("Poção: ", id, " | Ingredientes: ", [todas[id]["item1"], todas[id]["item2"]])

func alternar_estado_pronto():
	if particula_de_luz: particula_de_luz.visible = !particula_de_luz.visible

func _somitemadicionado():
	if get_node_or_null("Soms/AudioStreamPlayer3D_ItemAdicionadoNoCaldeirão"):
		$"Soms/AudioStreamPlayer3D_ItemAdicionadoNoCaldeirão".play()

func _sompuff():
	if get_node_or_null("Soms/AudioStreamPlayer3D_Puff"):
		$Soms/AudioStreamPlayer3D_Puff.play()
