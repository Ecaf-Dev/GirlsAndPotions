class_name Jogador
extends CharacterBody3D

# --- CONSTANTES ---
const SPEED = 5.0
const JUMP_VELOCITY = 0
const INTERVALO_PASSO = 0.4

# --- EXPORTS ---
@export var velocidade_carga: float = 40.0
@export var multiplicador_distancia: float = 0.15

# --- VARIÁVEIS DE ESTADO ---
var objeto_levantado: Objeto = null
var objeto_proximo = null
var forca_atual: float = 0.0
const FORCA_MAXIMA = 100.0

var podeInteragir = false
var objeto_interagivel = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var pode_falar = true
var timer_passo: float = 0.0
var interagindo: bool = false

# --- NODES ---
@onready var anim_player = $Heroina/AnimationPlayer
@onready var marker_mao = $Marker3D_MaoPos
@onready var marker_fala = $Marker3D_PosicaoFala

func _physics_process(delta):
	_aplicar_gravidade(delta)
	if objeto_interagivel and objeto_interagivel.querointeracao:
		interagindo = Input.is_action_pressed("tecla_z")
		# Repassa para o caldeirão
		objeto_interagivel.interagindo = interagindo
	else:
		interagindo = false
	_processar_movimento(delta)
	
	_processar_inputs()
	
	move_and_slide()
	update_animations()

func _aplicar_gravidade(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _processar_movimento(delta):
	if interagindo:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		_somcaminha(delta, false)
		return #
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Rotação suave para a direção do movimento
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 0.15)
		_somcaminha(delta, true)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		_somcaminha(delta, false)

func _processar_inputs():
	# Tecla Z: Interações e Coleta
	if Input.is_action_just_pressed("tecla_z"):
		# 1. Prioridade: Coleta (Se tiver algo pronto, tenta coletar com frasco)
		if objeto_interagivel and objeto_interagivel.pronto_para_coleta:
			if _saberoquelevo():
				return

		# 2. Prioridade: Iniciar Cozimento (Só se não estiver cozinhando e não estiver pronto)
		if podeInteragir and objeto_interagivel and objeto_levantado == null:
			if objeto_interagivel.has_method("cozinhando_pocao") and not objeto_interagivel.cozinhando:
				objeto_interagivel.cozinhando_pocao()
				return
		
		# 3. Resto das interações
		if objeto_levantado == null:
			_interagir_com_item()
		else:
			_soltaritem()

	# Tecla X: Levantar e Jogar
	if Input.is_action_just_pressed("tecla_x"):
		if objeto_levantado == null:
			_levantaritem()
		else:
			_jogaritem()

# --- MONITORAMENTO DE ÁREAS ---

func _on_area_3d_monitor_area_entered(area):
	var corpo = area.get_parent()
	if corpo is Objeto and objeto_levantado == null:
		_falaronomedoitem(corpo.nome_item)
		objeto_proximo = corpo
	
	if corpo is Caldeirao:
		podeInteragir = true
		objeto_interagivel = corpo

func _on_area_3d_monitor_area_exited(area):
	var corpo = area.get_parent();
	if corpo is Caldeirao:
		podeInteragir = false
		objeto_interagivel = null
	
	if corpo == objeto_proximo:
		objeto_proximo = null

# --- MECÂNICAS DE ITEM ---

func _levantaritem():
	if objeto_levantado == null and objeto_proximo != null:
		objeto_levantado = objeto_proximo
		var corpo = objeto_levantado;
		
		corpo.aplicar_elastico_externo()
		corpo.freeze = true
		corpo.get_node("CollisionShape3D").disabled = true
		corpo.reparent(marker_mao)
		
		corpo.position = Vector3.ZERO
		corpo.rotation = Vector3.ZERO
		_somlevantandoobjeto()

func _soltaritem():
	objeto_levantado.reparent(get_tree().current_scene)
	
	var direcao_frente = global_transform.basis.z
	objeto_levantado.global_position = global_position + (direcao_frente * 1.5) + Vector3.UP * 0.5
	
	objeto_levantado.set_deferred("freeze", false)
	objeto_levantado.set_deferred("sleeping", false)
	objeto_levantado.get_node("CollisionShape3D").set_deferred("disabled", false)

	get_tree().create_timer(0.05).timeout.connect(func(): 
		if is_instance_valid(objeto_levantado): objeto_levantado.apply_central_impulse(Vector3.DOWN * 2.0)
	)
	
	objeto_levantado.aplicar_elastico_externo()
	objeto_levantado = null

func _jogaritem():
	if objeto_levantado == null: return
	
	var direcao_frente = -Vector3.FORWARD.rotated(Vector3.UP, rotation.y).normalized()
	var impulso = (direcao_frente * 8.0) + (Vector3.UP * 2.0)
	
	objeto_levantado.reparent(get_tree().root)
	objeto_levantado.freeze = false
	objeto_levantado.get_node("CollisionShape3D").disabled = false
	objeto_levantado.apply_central_impulse(impulso)
	objeto_levantado.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 2.0)
	
	objeto_levantado = null
	_somjogando()

func _interagir_com_item():
	if objeto_levantado != null or objeto_proximo == null: return
	
	var item_alvo = objeto_proximo
	var resultado = item_alvo._diminuirquantidade()
	
	if resultado == "LEVAR_INTEIRO":
		_levantaritem() 
	elif resultado != "":
		_instanciar_na_mao(resultado)

func _instanciar_na_mao(nome):
	var cena_item = load("res://GirlsAndPotions/Cenas/rigid_body_3d_objeto.tscn")
	var novo_item = cena_item.instantiate()
	
	novo_item.nome_item = nome
	novo_item.quantidade_atual = 1
	
	marker_mao.add_child(novo_item)
	novo_item.position = Vector3.ZERO
	novo_item.rotation = Vector3.ZERO
	novo_item.freeze = true
	
	if novo_item.has_node("CollisionShape3D"):
		novo_item.get_node("CollisionShape3D").disabled = true
	
	objeto_levantado = novo_item

# --- AUXILIARES E VISUAIS ---

func _saberoquelevo() -> bool:
	if !objeto_interagivel || !objeto_interagivel.has_method("coletarliquido"):
		return false
		
	var nome_receita_coletada = objeto_interagivel.coletarliquido(objeto_levantado)
	if !nome_receita_coletada:
		return false;
	
	if objeto_levantado:
		objeto_levantado.nome_item = nome_receita_coletada
		objeto_levantado._carregar_visual_automatico()
	else:
		_instanciar_na_mao(nome_receita_coletada)
	return true

func _falaronomedoitem(nome):
	if not pode_falar: return
	pode_falar = false
	
	var balao = Label3D.new()
	balao.text = nome
	balao.billboard = StandardMaterial3D.BILLBOARD_ENABLED
	balao.no_depth_test = true
	balao.font_size = 48
	
	var pos_base = marker_fala.global_position
	get_tree().root.add_child(balao)
	balao.global_position = pos_base
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(balao, "global_position", pos_base + Vector3(0, 1.5, 0), 2.0)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(balao, "modulate:a", 0.0, 2.0)
	tween.chain().tween_callback(balao.queue_free)
	
	await get_tree().create_timer(0.5).timeout
	pode_falar = true

func update_animations():
	if anim_player == null: return
	var movendo = Vector2(velocity.x, velocity.z).length() > 0.1
	var anim = "Correndo/mixamo_com" if movendo else "Parada/mixamo_com"
	
	if anim_player.current_animation != anim:
		anim_player.play(anim)

# --- SONS ---

func _somcaminha(delta, esta_movendo):
	if not esta_movendo:
		timer_passo = 0.0
		return
	timer_passo -= delta
	if timer_passo <= 0:
		$Audios/AudioStreamPlayer3D_SonsPasso.play()
		timer_passo = INTERVALO_PASSO

func _somjogando(): $Audios/AudioStreamPlayer3D_LançarObjeto.play()
func _somlevantandoobjeto(): $Audios/AudioStreamPlayer3D_LevantarObjeto.play()
