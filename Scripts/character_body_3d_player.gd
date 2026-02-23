extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var objeto_levantado = null
var objeto_proximo = null

var forca_atual: float = 0.0
const FORCA_MAXIMA = 100.0
@export var velocidade_carga: float = 40.0
@export var multiplicador_distancia :float = 0.15
var podeCozinhar = false
var caldeirao = null
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var pode_falar = true

@onready var anim_player = $Heroina/AnimationPlayer

#tempo
var timer_passo: float = 0.0
const INTERVALO_PASSO: float = 0.4

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Criamos a direção baseada no ESPAÇO GLOBAL (não usamos transform.basis)
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction:
		# Aplicamos a velocidade nos eixos globais
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# 3. Calculamos o ângulo para onde ele deve olhar
		var target_angle = atan2(direction.x, direction.z)
		
		# 4. Rotacionamos o corpo
		rotation.y = lerp_angle(rotation.y, target_angle, 0.15)
		_soncaminha(delta, direction.length() > 0)
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	var target_angle = atan2(direction.x,direction.z)
	
	if Input.is_action_just_pressed("tecla_z"):
		#preicos repensar esta logica aqui, pois to com problemas em  filtrar qual ação realizar
		if(podeCozinhar == true && caldeirao != null && objeto_levantado == null):
			if caldeirao.has_method("cozinhando_pocao"):
				caldeirao.cozinhando_pocao()
		elif(objeto_levantado == null):
			_interagir_com_item()
		elif(objeto_levantado != null):
			_soltaritem()
		#criaremos uma checagem que caso a tecla z seja prescionada enquanto proximo a um caldeirão, chamaremos o metodo do caldeirao de cozinhar
		
	if Input.is_action_just_pressed("tecla_x"):
		if(objeto_levantado == null):
			_levantaritem()
		elif (objeto_levantado != null) :
			_sonjogando()
			_jogaritem()
	
	move_and_slide()
	update_animations()

func _on_area_3d_monitor_area_entered(area):
	print("objeto dentro da area:", area)
	var corpo = area.get_parent()
	if(objeto_levantado == null && area.is_in_group("item_carregavel")):
		_falaronomedoitem(corpo.nome_item)
		print("é carregavel")
		objeto_proximo = area
	#verificaremos se o jogador está proximo de uma area 2d caldeirao, caso esteja alteraremos o boleano pdoe cozinhar para true
	if area.is_in_group("caldeirao"):
		podeCozinhar = true
		caldeirao = area.get_parent()
		print(caldeirao.name, podeCozinhar)
		
func _on_area_3d_monitor_area_exited(area):
	if area.is_in_group("caldeirao"):
		podeCozinhar = false
		caldeirao = null
	
	# Cuidado aqui: se você sair de perto de QUALQUER área, 
	# ele limpa o objeto_proximo, mesmo que você ainda esteja perto do item.
	if area == objeto_proximo:
		objeto_proximo = null
		
func _levantaritem():
	if(objeto_levantado == null && objeto_proximo != null):
		
		objeto_levantado = objeto_proximo
		var corpo = objeto_levantado.get_parent()
		corpo.aplicar_elastico_externo()
		corpo.freeze = true
		corpo.get_node("CollisionShape3D").disabled = true
		corpo.reparent($Marker3D_MaoPos)
		corpo.position = Vector3.ZERO
		corpo.rotation = Vector3.ZERO
		#meu caracterbody tem um filho chamado Marker3D_maoPos, para colocar o objeto a ser carregado, como faço isso?
		print("item levantado e grudado")
	
func _soltaritem():
	var corpo = objeto_levantado.get_parent()
	
	# 1. Reparent primeiro (sempre para a cena atual)
	corpo.reparent(get_tree().current_scene)
	
	# 2. Posicionamento (ajustando a distância para positiva)
	var direcao_frente = global_transform.basis.z
	corpo.global_position = global_position + (direcao_frente * 1.5) + Vector3.UP * 0.5
	
	# 3. O SEGREDO: Descongelar de forma diferida
	# Isso garante que a física só ligue DEPOIS que ele mudou de pai e posição
	corpo.set_deferred("freeze", false)
	corpo.set_deferred("sleeping", false)
	
	# 4. Forçar a colisão a voltar
	var collision = corpo.get_node("CollisionShape3D")
	collision.set_deferred("disabled", false)

	# 5. Impulso de "Acorda!" (chamado um tiquinho depois)
	get_tree().create_timer(0.05).timeout.connect(func(): 
		if is_instance_valid(corpo):
			corpo.apply_central_impulse(Vector3.DOWN * 2.0)
	)
	
	# 6. Limpeza
	corpo.aplicar_elastico_externo()
	objeto_levantado = null
	
func _jogaritem():
	if objeto_levantado == null: return
	
	var corpo = objeto_levantado.get_parent()
	
	# 1. Direção para onde o player está olhando
	var direcao_frente = -Vector3.FORWARD.rotated(Vector3.UP, rotation.y).normalized()
	
	# 2. Definição de Força Fixa (Ajuste esses valores ao seu gosto!)
	var forca_horizontal = 8.0 
	var forca_vertical = 2.0  # Um pequeno pulinho para o arco ficar bonito
	
	var impulso = (direcao_frente * forca_horizontal) + (Vector3.UP * forca_vertical)
	
	# 3. Soltar no mundo
	corpo.reparent(get_tree().root) # Melhor soltar direto na root ou no seu nó de Level
	
	# 4. Reativar física
	corpo.freeze = false
	corpo.get_node("CollisionShape3D").disabled = false
	
	# 5. Aplicar o impulso
	corpo.apply_central_impulse(impulso)
	
	# Adiciona um giro aleatório para o item parecer que foi "jogado" de verdade
	corpo.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 2.0)
	
	# 6. Resetar estados
	objeto_levantado = null
	print("Item lançado instantaneamente!")

func _interagir_com_item():
	if objeto_levantado != null or objeto_proximo == null:
		return

	var item_alvo = objeto_proximo.get_parent()
	var resultado = item_alvo._diminuirquantidade()

	if resultado == "LEVAR_INTEIRO":
		# Caso seja um item único, usa sua função de levantar que já funciona
		_levantaritem() 
		
	elif resultado != "":
		# CASO DA CAIXA: Instancia um novo item direto na mão
		_instanciar_na_mao(resultado)
		print("Retirado 1 ", resultado, " da caixa.")

func _instanciar_na_mao(nome):
	# 1. Carrega a cena base do item
	var cena_item = load("res://GirlsAndPotions/Cenas/rigid_body_3d_objeto.tscn")
	var novo_item = cena_item.instantiate()
	
	# 2. Configura os dados do novo item
	novo_item.nome_item = nome
	novo_item.quantidade_atual = 1
	
	# 3. Gruda no Marker3D da mão
	$Marker3D_MaoPos.add_child(novo_item)
	novo_item.position = Vector3.ZERO
	novo_item.rotation = Vector3.ZERO
	
	# 4. Desativa física enquanto estiver na mão
	novo_item.freeze = true
	if novo_item.has_node("CollisionShape3D"):
		novo_item.get_node("CollisionShape3D").disabled = true
	
	# 5. Define como o objeto levantado (pegando a Area3D para manter seu padrão)
	objeto_levantado = novo_item.get_node("Area3D_Monitor")

func _falaronomedoitem(nome_do_item):
	if not pode_falar: return
	pode_falar = false
	# 1. Criamos o Label3D dinamicamente
	var balao = Label3D.new()
	balao.text = nome_do_item
	
	# 2. Configurações visuais básicas
	balao.billboard = StandardMaterial3D.BILLBOARD_ENABLED # Faz o texto sempre olhar para a câmera
	balao.no_depth_test = true # Garante que o texto apareça na frente de tudo
	balao.font_size = 48
	balao.outline_size = 12
	balao.modulate = Color.WHITE # Ou a cor que preferir para destacar
	
	# 3. Posicionamento
	# Se você criou o Marker3D chamado "PosicaoFala"
	var posicao_base = get_node("Marker3D_PosicaoFala").global_position
	get_tree().root.add_child(balao) # Adicionamos ao mundo para não girar com o player
	balao.global_position = posicao_base
	
	# 4. A Animação (O "Pulo" e o Sumiço)
	var tween = create_tween()
	# Faz o balão subir 1 metro em 0.8 segundos
	tween.tween_property(balao, "global_position", posicao_base + Vector3(0, 1.5, 0), 2)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Faz o balão ficar transparente ao mesmo tempo
	tween.parallel().tween_property(balao, "modulate:a", 0.0, 2)
	
	# 5. Autodestruição
	tween.tween_callback(balao.queue_free)
	
	await get_tree().create_timer(0.5).timeout # Espera meio segundo
	pode_falar = true

func update_animations():
	# 1. Checagem de segurança para evitar erros caso o player não tenha sido carregado
	if anim_player == null: return

	# 2. Lógica de movimento (X e Z)
	var movendo = Vector2(velocity.x, velocity.z).length() > 0.1

	if movendo:
		# Verifica se a animação de correr já não está tocando
		# O nome deve ser EXATAMENTE como aparece na lista do seu AnimationPlayer
		if anim_player.current_animation != "Correndo/mixamo_com":
			anim_player.play("Correndo/mixamo_com")
	else:
		# Quando parado, toca a animação de Idle
		if anim_player.current_animation != "Parada/mixamo_com":
			anim_player.play("Parada/mixamo_com")

func _soncaminha(delta, esta_movendo):
	if not esta_movendo:
		timer_passo = 0.0
		return

	timer_passo -= delta

	if timer_passo <= 0:
		# Verifique se o nome do nó está idêntico ao da sua árvore: AudioStreamPlayer3D_SonsPasso
		$Audios/AudioStreamPlayer3D_SonsPasso.play()
		timer_passo = INTERVALO_PASSO

func _sonjogando():
	$"Audios/AudioStreamPlayer3D_LançarObjeto".play()
	
