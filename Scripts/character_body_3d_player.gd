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
		#preicos repensar esta logica aqui, pois to com problemas em  filtrar qual ação realizar
		if(podeCozinhar == true && caldeirao != null && objeto_levantado == null):
			if caldeirao.has_method("cozinhar"):
				caldeirao.cozinhar()
		elif(objeto_levantado == null):
			_interagir_com_item()
		elif(objeto_levantado != null):
			_soltaritem()
		#criaremos uma checagem que caso a tecla z seja prescionada enquanto proximo a um caldeirão, chamaremos o metodo do caldeirao de cozinhar
		
	if Input.is_action_just_pressed("tecla_x"):
		_jogaritem()
	
	move_and_slide()


func _on_area_3d_monitor_area_entered(area):
	print("objeto dentro da area:", area)
	if(objeto_levantado == null && area.is_in_group("item_carregavel")):
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
		corpo.freeze = true
		corpo.get_node("CollisionShape3D").disabled = true
		corpo.reparent($Marker3D_MaoPos)
		corpo.position = Vector3.ZERO
		corpo.rotation = Vector3.ZERO
		#meu caracterbody tem um filho chamado Marker3D_maoPos, para colocar o objeto a ser carregado, como faço isso?
		print("item levantado e grudado")
	
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
