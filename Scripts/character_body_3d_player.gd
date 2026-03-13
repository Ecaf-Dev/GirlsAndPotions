extends CharacterBody3D

# --- CONSTANTES ---
const SPEED = 5.0
const JUMP_VELOCITY = 0
const INTERVALO_PASSO = 0.4

# --- EXPORTS ---
@export var velocidade_carga: float = 40.0
@export var multiplicador_distancia: float = 0.15

# --- VARIÁVEIS DE ESTADO ---
var objeto_levantado = null
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
	if objeto_interagivel and objeto_interagivel.get("querointeracao"):
		# 'interagindo' no caldeirão vira true APENAS enquanto Z estiver pressionado
		objeto_interagivel.interagindo = Input.is_action_pressed("tecla_z")
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
			if objeto_levantado and _saberoquelevo():
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
	if objeto_levantado == null and area.is_in_group("item_carregavel"):
		_falaronomedoitem(corpo.nome_item)
		objeto_proximo = area
	
	if area.is_in_group("caldeirao"):
		podeInteragir = true
		objeto_interagivel = corpo

func _on_area_3d_monitor_area_exited(area):
	if area.is_in_group("caldeirao"):
		podeInteragir = false
		objeto_interagivel = null
	
	if area == objeto_proximo:
		objeto_proximo = null

# --- MECÂNICAS DE ITEM ---

func _levantaritem():
	if objeto_levantado == null and objeto_proximo != null:
		objeto_levantado = objeto_proximo
		var corpo = objeto_levantado.get_parent()
		
		corpo.aplicar_elastico_externo()
		corpo.freeze = true
		corpo.get_node("CollisionShape3D").disabled = true
		corpo.reparent(marker_mao)
		
		corpo.position = Vector3.ZERO
		corpo.rotation = Vector3.ZERO
		_somlevantandoobjeto()

func _soltaritem():
	var corpo = objeto_levantado.get_parent()
	corpo.reparent(get_tree().current_scene)
	
	var direcao_frente = global_transform.basis.z
	corpo.global_position = global_position + (direcao_frente * 1.5) + Vector3.UP * 0.5
	
	corpo.set_deferred("freeze", false)
	corpo.set_deferred("sleeping", false)
	corpo.get_node("CollisionShape3D").set_deferred("disabled", false)

	get_tree().create_timer(0.05).timeout.connect(func(): 
		if is_instance_valid(corpo): corpo.apply_central_impulse(Vector3.DOWN * 2.0)
	)
	
	corpo.aplicar_elastico_externo()
	objeto_levantado = null

func _jogaritem():
	if objeto_levantado == null: return
	var corpo = objeto_levantado.get_parent()
	
	var direcao_frente = -Vector3.FORWARD.rotated(Vector3.UP, rotation.y).normalized()
	var impulso = (direcao_frente * 8.0) + (Vector3.UP * 2.0)
	
	corpo.reparent(get_tree().root)
	corpo.freeze = false
	corpo.get_node("CollisionShape3D").disabled = false
	corpo.apply_central_impulse(impulso)
	corpo.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 2.0)
	
	objeto_levantado = null
	_somjogando()

func _interagir_com_item():
	if objeto_levantado != null or objeto_proximo == null: return
	
	var item_alvo = objeto_proximo.get_parent()
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
	
	objeto_levantado = novo_item.get_node("Area3D_Monitor")

# --- AUXILIARES E VISUAIS ---

func _saberoquelevo() -> bool:
	var pai = objeto_levantado.get_parent()
	if pai and "nome_item" in pai:
		if pai.nome_item == "Frasco Vazio" and objeto_interagivel != null:
			if objeto_interagivel.has_method("coletarliquido"):
				var res = objeto_interagivel.coletarliquido(pai.nome_item)
				if res:
					pai.nome_item = res[1]
					pai._carregar_visual_automatico()
					return true
	return false

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
