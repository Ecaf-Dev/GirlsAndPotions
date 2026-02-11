extends RigidBody3D

@export var nome_item : String = ""

# Chamamos no _ready para que o visual mude assim que o item nascer no mundo
func _ready():
	await get_tree().create_timer(0.01).timeout
	_carregar_visual_automatico()

func _carregar_visual_automatico():
	# 1. Padroniza o nome para o formato de arquivo (ex: "Flor Da Vida" -> "flor_da_vida")
	var nome_arquivo = nome_item.to_lower().replace(" ", "_")
	print(nome_arquivo)
	# 2. Define os caminhos possíveis (você pode adicionar .glb ou .tscn)
	var caminho_modelo = "res://GirlsAndPotions/Modelos/" + nome_arquivo + ".tscn"
	
	# 3. Verifica se o arquivo realmente existe na pasta
	if FileAccess.file_exists(caminho_modelo):
		var cena_modelo = load(caminho_modelo)
		if cena_modelo:
			var instancia = cena_modelo.instantiate()
			
			# 4. Desativa o visual temporário (a caixa rosa)
			if has_node("CSGBox3D_ObjetoVisual"):
				$CSGBox3D_ObjetoVisual.visible = false
				# Ou use queue_free() se quiser deletar de vez: $CSGBox3D_ObjetoVisual.queue_free()
			
			# 5. Adiciona o novo modelo
			add_child(instancia)
			
			# 6. Ajuste de escala (Opcional)
			# Se seus modelos vierem muito grandes ou pequenos da pasta, 
			# você pode forçar um tamanho padrão aqui:
			# instancia.scale = Vector3(0.5, 0.5, 0.5) 
			
			print("Sucesso: Visual de '", nome_item, "' carregado de ", caminho_modelo)
	else:
		print("Aviso: Modelo para '", nome_item, "' não encontrado em ", caminho_modelo, ". Mantendo caixa rosa.")

