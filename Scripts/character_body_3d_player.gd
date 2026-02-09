extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var objeto_levantado = null
var objeto_proximo = null

var forca_atual: float = 0.0
const FORCA_MAXIMA = 100.0
@export var velocidade_carga: float = 40.0
@export var multiplicador_distancia :float = 0.15


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


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
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	var target_angle = atan2(direction.x,direction.z)
	
	if Input.is_action_just_pressed("tecla_z"):
		if(objeto_levantado == null):
			_levantaritem()
		elif(objeto_levantado != null):
			_soltaritem()
	if Input.is_action_pressed("tecla_x"):
		forca_atual = min(forca_atual + velocidade_carga * delta, FORCA_MAXIMA)
	if Input.is_action_just_released("tecla_x"):
		_jogaritem()
		forca_atual = 0.0
	
	move_and_slide()


func _on_area_3d_monitor_area_entered(area):
	print("objeto dentro da area:", area)
	if(objeto_levantado == null && area.is_in_group("item_carregavel")):
		print("é carregavel")
		objeto_proximo = area

func _on_area_3d_monitor_area_exited(area):
	print("objeto fora da area:", area)
	objeto_proximo == null
	
func _levantaritem():
	if(objeto_levantado == null && objeto_proximo != null):
		objeto_levantado = objeto_proximo
		var corpo = objeto_levantado.get_parent()
		corpo.freeze = true
		corpo.get_node("CollisionShape3D").disabled = true
		corpo.reparent($Marker3D_MaoPos)
		corpo.position = Vector3.ZERO
		corpo.rotation = Vector3.ZERO
		#meu caracterbody tem um filho chamado Marker3D_maoPos, para colocar o objeto a ser carregado, como faço isso?
		print("item levantado e grudado")
		objeto_proximo = null
	
func _soltaritem():
	var corpo = objeto_levantado.get_parent()
	
	# 1. Antes de soltar, calculamos a posição à frente
	# Pegamos a direção "frente" baseada na rotação do personagem
	# No Godot, o eixo -Z costuma ser a frente, mas como usamos o atan2,
	# vamos usar o Vector3.FORWARD rotacionado:
	var direcao_frente = Vector3.FORWARD.rotated(Vector3.UP, rotation.y)
	var distancia = -1.5 # Distância à frente para não colidir com o pé da bruxinha
	
	# 2. Fazemos o reparent para o mundo
	corpo.reparent(get_tree().root.get_child(0)) 
	
	# 3. Posicionamos o objeto no mundo à frente do player
	# Usamos global_position do player + a direção calculada
	corpo.global_position = global_position + (direcao_frente * distancia)
	
	# Opcional: Ajuste a altura para ele não "nascer" dentro do chão
	corpo.global_position.y = global_position.y + 0.5 
	
	# 4. Reativamos a física
	corpo.freeze = false
	corpo.get_node("CollisionShape3D").disabled = false
	
	# 5. Limpamos a referência
	objeto_levantado = null
	
	print("Item deixado à frente!")

func _jogaritem():
	if objeto_levantado == null: return
	
	var corpo = objeto_levantado.get_parent()
	
	# 1. Direção horizontal pura
	var direcao_frente = -Vector3.FORWARD.rotated(Vector3.UP, rotation.y).normalized()
	
	# 2. Cálculo do Impulso (removido o Vector3.UP)
	var forca_final = forca_atual * multiplicador_distancia
	if(forca_final < 4.0):
		forca_final = 4
	var impulso = direcao_frente * forca_final
	
	# 3. Soltar no mundo
	corpo.reparent(get_tree().root.get_child(0))
	
	# 4. Reativar física
	corpo.freeze = false
	corpo.get_node("CollisionShape3D").disabled = false
	
	# 5. Aplicar o impulso linear
	corpo.apply_central_impulse(impulso)
	
	# 6. Resetar estados
	objeto_levantado = null
	forca_atual = 0.0
	print("Item lançado em linha reta com força: ", forca_final)
