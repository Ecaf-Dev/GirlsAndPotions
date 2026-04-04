extends Node3D

@export_group("Configurações do Grid")
@export var colunas: int = 5      # Largura (X)
@export var linhas: int = 5       # Profundidade (Z)
@export var tamanho_tile: float = 2.0 

@export_group("Recursos")
@export var cena_tile: PackedScene

@export_group("Cenas de Mobília")
#Observação, precisa-se ajustar a arquitetura de mobilias, indico criar uma variavel global que gerencie todas as mobilias, por hora não criei pois estou implementando a mecanica de instancia via configuração da fase
@export var catalogo_mobilias: Dictionary = {
	"caldeirao": preload("res://GirlsAndPotions/Cenas/static_body_3d_caldeirao.tscn"),
	"tabua_de_corte": preload("res://GirlsAndPotions/Cenas/static_body_3d_tabua_de_corte.tscn"), # ajuste o caminho
	"balcao": preload("res://GirlsAndPotions/Cenas/static_body_3d_balcao.tscn"),
	"caixa_ce_correio": preload("res://GirlsAndPotions/Cenas/static_body_3d_caixa_de_correio.tscn")
}

func _ready():
	var fase_ativa = Fases.pegar_fase("Fase 1")
	
	if fase_ativa:
		self.colunas = fase_ativa.largura
		self.linhas = fase_ativa.profundidade
		gerar_grid_centralizado()

func gerar_grid_centralizado():
	# Limpeza
	for child in get_children():
		child.queue_free()
	
	if not cena_tile: return

	# CÁLCULO DO OFFSET (O SEGREDO DO CENTRO)
	# Subtraímos 1 do total para que o centro do grid fique exatamente no (0,0)
	# Ex: Se colunas for 10 e tamanho for 2, a largura total é 20.
	# O centro será (10 - 1) * 2 / 2 = 9.0 de deslocamento.
	var offset_x = (float(colunas - 1) * tamanho_tile) / 2.0
	var offset_z = (float(linhas - 1) * tamanho_tile) / 2.0

	for x in range(colunas):
		for z in range(linhas):
			var novo_tile = cena_tile.instantiate()
			
			# Posição original multiplicada pelo tamanho, menos o deslocamento central
			var pos_x = (x * tamanho_tile) - offset_x
			var pos_z = (z * tamanho_tile) - offset_z
			
			novo_tile.position = Vector3(pos_x, 0, pos_z)
			novo_tile.name = "Tile_%d_%d" % [x, z]
			
			add_child(novo_tile)
			
	print("✅ Grid Centralizado Gerado: ", colunas, "x", linhas)

# Ajuste nas funções de conversão para respeitar o novo centro:
func mundo_para_grid(posicao_mundo: Vector3) -> Vector2i:
	var offset_x = (float(colunas - 1) * tamanho_tile) / 2.0
	var offset_z = (float(linhas - 1) * tamanho_tile) / 2.0
	
	var x = round((posicao_mundo.x + offset_x) / tamanho_tile)
	var z = round((posicao_mundo.z + offset_z) / tamanho_tile)
	return Vector2i(x, z)
