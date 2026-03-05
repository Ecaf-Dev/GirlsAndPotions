extends Node3D

@onready var sprite = $Sprite3D_Seta

# Variável preenchida pelo Caldeirão (Cima, Baixo, Esquerda, Direita)
var direcao_da_seta : String = ""

# Caminho base para suas artes (usamos o padrão "res://" do Godot para apontar para dentro do projeto)
# Como sua pasta está no GitHubDesktop, dentro do projeto Godot ela deve aparecer como:
var caminho_base = "res://GirlsAndPotions/Arts/Icones/seta_"

func _ready():
	# 1. Configura o visual
	ajustarmeutamanho()
	ajustarminharotacao()
	
	sprite.modulate = Color(0.352, 0.352, 0.352, 1.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
func marcar_como_acerto():
	# Feedback visual de sucesso
	var t = create_tween().set_parallel(true)
	t.tween_property(sprite, "modulate", Color(2.5, 2.5, 2.5), 0.1) # Brilho intenso
	
	# Efeito de pulso na escala do Sprite
	var st = create_tween()
	st.tween_property(sprite, "scale", Vector3(1.3, 1.3, 1.3), 0.05)
	st.tween_property(sprite, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func ajustarmeutamanho():
	# Ajusta a escala do Node3D_Seta (o pai)
	# 0.08 é um bom ponto de partida para o tamanho do seu caldeirão
	var escala_final = 0.15
	self.scale = Vector3(escala_final, escala_final, escala_final)

func ajustarminharotacao():
	# 1. Montamos o caminho completo: res://Arts/Icones/seta_ + baixo + .png
	# Importante: O Godot usa letras minúsculas internamente nos caminhos, 
	# então usamos o .to_lower() por segurança.
	var caminho_final = caminho_base + direcao_da_seta.to_lower() + ".png"
	
	# 2. Carregamos a textura dinamicamente
	var nova_textura = load(caminho_final)
	
	# 3. Verificamos se o arquivo foi encontrado antes de aplicar
	if nova_textura:
		sprite.texture = nova_textura
	else:
		print("❌ Erro: Não foi possível carregar a imagem em: ", caminho_final)
	
	# Resetamos a rotação, pois a imagem já está na posição correta
	sprite.rotation_degrees.z = 0
