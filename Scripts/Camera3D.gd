extends Camera3D

# Arraste o nó do seu personagem para cá no Inspector
@export var alvo: Node3D 

# A distância fixa que a câmera ficará do personagem
# Ajuste esses valores para chegar no ângulo isométrico desejado
@export var offset: Vector3 = Vector3(10, 10, 10)

func _ready():
	# Define a posição inicial e faz a câmera olhar para o alvo
	if alvo:
		global_position = alvo.global_position + offset
		look_at(alvo.global_position)

func _process(_delta):
	if alvo:
		# A câmera segue a posição global do alvo + o offset fixo
		# Isso garante que ela se mova, mas ignore a rotação do personagem
		global_position = alvo.global_position + offset
		
		# Mantém o alvo centralizado na tela
		look_at(alvo.global_position)
