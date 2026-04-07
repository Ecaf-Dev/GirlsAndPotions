class_name Caldeirao
extends StaticBody3D

# --- CONFIGURAÇÕES ---
@export var max_slots = 2
@export var objeto_visual : Node3D
@export var cena_base_item: PackedScene
@export var mobilia_automatica: bool = true

@export_group("Interface")
@export var marker_holograma : Marker3D
@export var marker_barra : Marker3D
@export var icone_coleta : Sprite3D

@export_group("Efeitos")
@onready var malha_caldeirao = $"Caldeirão"
@onready var particula_de_luz = $GPUParticles3D_Sucesso
@onready var particulas_puff = $GPUParticles3D_Puff
@onready var particulas_bolhas = $GPUParticles3D_Bolhas

# CLASSES INTERNAS
class ReceitaConcluida:
	var nome: String
	var objeto_necessario
	
	func _init(p_nome: String, p_objeto_necessario):
		nome = p_nome
		objeto_necessario = p_objeto_necessario
	

# --- VARIÁVEIS DE ESTADO ---
var items_processando: Array[String] = [] 
var meu_tipo_de_mobilia : String = ""
var receita_concluida: ReceitaConcluida = null
var cor_original = Color(0.0, 0.4, 0.9)
var cor_da_pocao : Color = Color.WHITE

var tempo_da_receita = 1
var receita_validada = false
var cozinhando = false
var pronto_para_coleta: bool = false
var holograma_atual : Objeto = null
var querointeracao: bool = false
var interagindo: bool = false

var barra_fundo : MeshInstance3D = null
var barra_progresso : MeshInstance3D = null

var escala_original_objeto_visual: Vector3 = Vector3(1,1,1)

# --- CICLO DE VIDA ---

func _ready():
	meu_tipo_de_mobilia = name.replace("StaticBody3D_", "")
	escala_original_objeto_visual = objeto_visual.scale
	_conectar_as_receitas()
# --- INTERAÇÕES E SLOTS ---

func _on_area_3d_monitor_body_entered(objeto_colidido):
	if objeto_colidido is Objeto:
		var numero_de_items_excedido = items_processando.size() >= max_slots;
		var devo_rejeitar_objeto = (cozinhando || 
									pronto_para_coleta ||
									objeto_colidido.quantidade_atual > 1 ||
									numero_de_items_excedido ||
									objeto_colidido.nome_item == "Frasco Vazio");
		
		if devo_rejeitar_objeto:
			_rejeitar_item(objeto_colidido)
			return;
			
		_adicionar_item_para_processamento(objeto_colidido)
		return;
	if objeto_colidido is Jogador:
		print("JOGADOR ENCOSTOU NO CALDERAO")

func _adicionar_item_para_processamento(objeto_colidido: Objeto):
	items_processando.append(objeto_colidido.nome_item)
	_somitemadicionado()
	_receita_compativel(items_processando)

	var receita = Receitas.pegar_receita(objeto_colidido.nome_item);
	if !receita || receita.objeto_necessario != "Frasco Vazio":
		objeto_colidido.queue_free()
	else:
		objeto_colidido.nome_item = "Frasco Vazio"
		objeto_colidido.carregar_visual_automatico()
		_rejeitar_item(objeto_colidido)
	_elastico()

func _receita_compativel(itens: Array):
	alterar_cor_liquido()
	if itens.size() < max_slots: return null

	var receita_encontrada = Receitas.pegar_receita_compativel(itens, meu_tipo_de_mobilia)
	if receita_encontrada:
		receita_validada = true
		tempo_da_receita = receita_encontrada.tempo_de_cozinha
		_mostrarHolograma(receita_encontrada)
		if holograma_atual:
			cor_da_pocao = await _pegar_cor_do_holograma(holograma_atual)
			alterar_cor_liquido(cor_da_pocao)
		return
	
	receita_validada = false
	return

# --- LÓGICA DE PREPARO ---

func cozinhando_pocao():
	if cozinhando: return 
	if pronto_para_coleta: return
	if items_processando.is_empty() or !receita_validada:
		tempo_da_receita = 1 

	cozinhando = true
	querointeracao = true # Avisa o player para travar o movimento e monitorar o Z
	
	var progresso_atual = 0.0
	while progresso_atual < tempo_da_receita:
		# LÓGICA OTIMIZADA:
		# Progride se for automático OU se o jogador estiver ativamente interagindo
		if mobilia_automatica or interagindo:
			progresso_atual += get_process_delta_time()
			var porcentagem = clamp(progresso_atual / tempo_da_receita, 0.0, 1.0)
			_gerenciar_barra_visual(porcentagem)
		
		await get_tree().process_frame 
	
	_gerenciar_barra_visual(0)

	# Finalização...
	if receita_validada and !items_processando.is_empty():
		_disparar_puff_colorido(cor_da_pocao)
		cozinhar()
		if icone_coleta: icone_coleta.visible = true
	else:
		_falha_na_cozinha()
	
	querointeracao = false
	cozinhando = false

func cozinhar():
	var sucesso = false
	querointeracao = false

	var receita_compativel = Receitas.pegar_receita_compativel(items_processando, meu_tipo_de_mobilia);
	if (receita_compativel):
		sucesso = true
		receita_concluida = ReceitaConcluida.new(
			receita_compativel.nome, 
			receita_compativel.objeto_necessario)
		pronto_para_coleta = true
		_alternar_estado_pronto()

	if sucesso and holograma_atual:
		holograma_atual.nome_item = receita_compativel.nome
		holograma_atual.carregar_visual_automatico()
		var cor = await _pegar_cor_do_holograma(holograma_atual)
		_disparar_puff_colorido(cor)
		alterar_cor_liquido(cor)
	elif !sucesso:
		_elastico()
	
	items_processando.clear()

# --- VISUAL E FEEDBACK ---

func _mostrarHolograma(receita: Receitas.Receita):
	if holograma_atual: holograma_atual.queue_free()
	if !cena_base_item or !marker_holograma: return

	holograma_atual = cena_base_item.instantiate() as Objeto
	holograma_atual.nome_item = receita.ingredientes[0] if receita.ingredientes.size() == 1 else receita.nome
	holograma_atual.desativar_colisao()
	if holograma_atual is RigidBody3D:
		holograma_atual.freeze = true
		holograma_atual.collision_layer = 0
		holograma_atual.collision_mask = 0
	
	var area = holograma_atual.get_node_or_null("Area3D_Monitor")
	if area: 
		area.collision_layer = 0
		area.collision_mask = 0
		
	marker_holograma.add_child(holograma_atual)

func _gerenciar_barra_visual(porcentagem: float):
	if porcentagem <= 0 or porcentagem >= 1.0:
		if barra_fundo:
			var t = create_tween()
			t.tween_property(barra_fundo, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
			t.finished.connect(
				func(): 
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
	barra_fundo.mesh.top_radius = 0.1 
	barra_fundo.mesh.bottom_radius = 0.1
	barra_fundo.mesh.height = 1.3
	barra_fundo.rotation.z = deg_to_rad(90)
	
	var mat_fundo = StandardMaterial3D.new()
	mat_fundo.transparency = 1
	mat_fundo.albedo_color = Color(0.1, 0.1, 0.2, 0.4)
	barra_fundo.material_override = mat_fundo
	marker_barra.add_child(barra_fundo)

	barra_progresso = MeshInstance3D.new()
	barra_progresso.mesh = CylinderMesh.new()
	barra_progresso.mesh.top_radius = 0.05
	barra_progresso.mesh.bottom_radius = 0.05
	
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

func coletarliquido(objeto_levantado: Objeto):
	var objeto_necessario = objeto_levantado.nome_item if objeto_levantado else null
	if (receita_concluida.objeto_necessario != objeto_necessario):
		return null;
	
	if !pronto_para_coleta:
		return null
		
	if holograma_atual: 
		holograma_atual.queue_free(); 
		holograma_atual = null
	if icone_coleta: 
		icone_coleta.visible = false
		
	pronto_para_coleta = false
	_alternar_estado_pronto()
	alterar_cor_liquido(cor_original)
	var nome_receita_concluida = receita_concluida.nome
	receita_concluida = null
	return nome_receita_concluida

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
	_elastico()
	items_processando.clear()
	if holograma_atual: holograma_atual.queue_free(); holograma_atual = null

func _elastico():
	if !objeto_visual: return
	var tween = create_tween()
	var vetor_do_efeito = Vector3(escala_original_objeto_visual.x - 0.2, escala_original_objeto_visual.y - 0.3, escala_original_objeto_visual.z - 0.2)

	tween.tween_property(objeto_visual, "scale", vetor_do_efeito, 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(objeto_visual, "scale", escala_original_objeto_visual, 0.3).set_trans(Tween.TRANS_ELASTIC)

func _rejeitar_item(item):
	if item is Objeto:
		item.apply_central_impulse(Vector3.BACK * 2.3 + Vector3.UP * 4.0)
		_elastico()

func _conectar_as_receitas():
	var todas = Receitas.pegar_todas_as_receitas()
	for receita in todas:
		print("Poção: ", receita.id, " | Ingredientes: ", " + ".join(receita.ingredientes))

func _alternar_estado_pronto():
	if particula_de_luz: particula_de_luz.visible = !particula_de_luz.visible

func _somitemadicionado():
	if get_node_or_null("Soms/AudioStreamPlayer3D_ItemAdicionadoNoCaldeirão"):
		$"Soms/AudioStreamPlayer3D_ItemAdicionadoNoCaldeirão".play()

func _sompuff():
	if get_node_or_null("Soms/AudioStreamPlayer3D_Puff"):
		$Soms/AudioStreamPlayer3D_Puff.play()
