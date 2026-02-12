extends RigidBody3D

@export var nome_item : String = ""
@export var quantidade_atual : int = 1

# Chamamos no _ready para que o visual mude assim que o item nascer no mundo
func _ready():
	await get_tree().create_timer(0.01).timeout
	_carregar_visual_automatico()

func _carregar_visual_automatico():
	
	for child in get_children():
		if child is MeshInstance3D or child is Node3D and child.name != "CSGBox3D_ObjetoVisual" and child.name != "CollisionShape3D" and child.name != "Area3D_Monitor":
			# Se o nó não for um dos componentes básicos, é um modelo antigo
			child.queue_free()
	
	# 1. Padroniza o nome para o formato de arquivo (ex: "Flor Da Vida" -> "flor_da_vida")
	var nome_arquivo = nome_item.to_lower().replace(" ", "_")
	print(nome_arquivo)
	# 2. Define os caminhos possíveis (você pode adicionar .glb ou .tscn)
	var caminho_modelo = "res://GirlsAndPotions/Modelos/" + nome_arquivo + ".tscn"
	var caminho_modelo_caixa = "res://GirlsAndPotions/Modelos/" + "caixa" + ".tscn"
	# 3. Verifica se o arquivo realmente existe na pasta
	if FileAccess.file_exists(caminho_modelo):
		var cena_modelo = null
		if quantidade_atual == 1:
			cena_modelo = load(caminho_modelo)
		elif quantidade_atual  >= 2:
			cena_modelo = load(caminho_modelo_caixa)			
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



func _on_area_3d_monitor_body_entered(body):
	if body.get("nome_item") == self.nome_item: # Replace with function body.
		print("Itens iguais")
		if "quantidade_atual" in body:
			if body.freeze == false:
				_stackaritens(body)

func  _stackaritens(outro_item):
	if outro_item.quantidade_atual > self.quantidade_atual :
		print("meu grupo é menor")
		_aumentarquantidade(outro_item)
	elif outro_item.quantidade_atual == self.quantidade_atual:
		if outro_item.global_position.y < self.global_position.y :
			_aumentarquantidade(outro_item)

func _aumentarquantidade(outro_item):
	outro_item.quantidade_atual = outro_item.quantidade_atual + self.quantidade_atual
	outro_item._carregar_visual_automatico()
	queue_free()

func _diminuirquantidade():
	if quantidade_atual > 1:
		quantidade_atual -= 1
		_carregar_visual_automatico() # Atualiza para o modelo de unidade se sobrar 1
		return nome_item
	elif quantidade_atual == 1:
		# Se só tem 1, o player vai levar o objeto inteiro, não precisa instanciar novo
		return "LEVAR_INTEIRO"
	return ""

