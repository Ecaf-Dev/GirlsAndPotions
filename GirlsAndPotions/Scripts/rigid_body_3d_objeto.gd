class_name Objeto
extends RigidBody3D

@export var nome_item : String = ""
@export var quantidade_atual : int = 1
# Variável para armazenar a escala original do modelo carregado
var escala_base_modelo : Vector3 = Vector3.ONE
var objeto_stackando: Objeto = null;

func _ready():
	_carregar_visual_automatico()
	_conectarcomglobalitem()
	_ocuparespaco()

func _carregar_visual_automatico():
	# 1. Limpeza de modelos antigos
	for child in get_children():
		if child is MeshInstance3D or (child is Node3D and child.name != "CSGBox3D_ObjetoVisual" and child.name != "CollisionShape3D" and child.name != "Area3D_Monitor" and child.name != "Node"):
			child.queue_free()
	
	var nome_arquivo = nome_item.to_lower().replace(" ", "_")
	var caminho_modelo = "res://GirlsAndPotions/Modelos/" + nome_arquivo + ".tscn"
	var caminho_modelo_caixa = "res://GirlsAndPotions/Modelos/caixa.tscn"
	
	var cena_modelo = null
	
	if quantidade_atual == 1:
		if FileAccess.file_exists(caminho_modelo):
			cena_modelo = load(caminho_modelo)
	else:
		if FileAccess.file_exists(caminho_modelo_caixa):
			_somvirarcaixa()
			cena_modelo = load(caminho_modelo_caixa)
			
			
	if cena_modelo:
		var instancia = cena_modelo.instantiate()
		
		if has_node("CSGBox3D_ObjetoVisual"):
			$CSGBox3D_ObjetoVisual.visible = false
		
		add_child(instancia)
		
		# --- NOVO: UPGRADE DA CAIXA (AUTO-CONFIGURAÇÃO) ---
		if quantidade_atual > 1:
			_configurar_display_caixa(instancia)
		
		escala_base_modelo = instancia.scale
		aplicar_elastico_externo(instancia)
		print("Sucesso: Visual de '", nome_item, "' carregado. Qtd: ", quantidade_atual)
	else:
		var modelo_padrao = MeshInstance3D.new();
		if has_node("CSGBox3D_ObjetoVisual"):
			$CSGBox3D_ObjetoVisual.visible = true
		print("Aviso: Modelo não encontrado para ", nome_item)
func _physics_process(_delta):
	# Se o item estiver parado no ar (freeze falso) mas não estiver caindo (linear_velocity baixa)
	# e não tiver ninguém segurando ele (pai é a cena principal)
	if not freeze and linear_velocity.length() < 0.1 and get_parent() == get_tree().current_scene:
		# Verificamos se ele está longe do chão (opcional, mas ajuda)
		# Se ele estiver 'dormindo', nós acordamos ele na marra
		if sleeping:
			sleeping = false
			apply_central_impulse(Vector3.DOWN * 5.0) # Um 'puxão' da gravidade

# FUNÇÃO QUE VOCÊ PEDIU: Identifica e ajusta proporções automaticamente
func _on_area_3d_monitor_body_entered(body):
	if (body is Objeto 
	and body != self
	and body.global_position.y > self.global_position.y
	and body.nome_item == self.nome_item 
	and body.freeze == false):
		_stackaritens(body)

func _stackaritens(outro_item: Objeto):
	if outro_item.objeto_stackando || self.objeto_stackando:
		return

	self.objeto_stackando = outro_item;
	outro_item.objeto_stackando = self;
	self.quantidade_atual += outro_item.quantidade_atual
	_carregar_visual_automatico()
	outro_item.queue_free()
	self.objeto_stackando = null;

func _diminuirquantidade():
	if quantidade_atual > 1:
		quantidade_atual -= 1
		_carregar_visual_automatico() # O elástico vai rodar aqui também!
		return nome_item
	elif quantidade_atual == 1:
		return "LEVAR_INTEIRO"
	return ""

func aplicar_elastico_externo(alvo: Node3D = null):
	var visual = alvo
	
	# Se ninguém passou um alvo, vamos caçar o modelo atual dele
	if visual == null:
		for child in get_children():
			# Procura o primeiro nó que não seja colisão ou área (o seu modelo)
			if child is Node3D and child.name != "CollisionShape3D" and child.name != "Area3D_Monitor" and child.name != "CSGBox3D_ObjetoVisual" :
				visual = child
				break
	
	if visual == null: return

	# Criamos o tween (se houver um antigo rodando no mesmo objeto, o Godot mata o anterior)
	var tween = create_tween()
	
	# Usamos a escala_base_modelo que salvamos no carregamento
	var squash = Vector3(escala_base_modelo.x * 0.7, escala_base_modelo.y * 1.4, escala_base_modelo.z * 0.7)
	
	tween.tween_property(visual, "scale", squash, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", escala_base_modelo, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _somvirarcaixa():
	$Node/AudioStreamPlayer3D_VirarCaixa.play()
func _configurar_display_caixa(instancia_caixa):
	# Procura os nós de UI dentro do modelo da caixa (caixa.tscn)
	var sprite_icone = instancia_caixa.find_child("Sprite3D_Icone", true, false)
	var label_qtd = instancia_caixa.find_child("Label3D_Quantidade", true, false)
	
	# 1. Configura o Ícone e sua Escala
	var item = Items.pegar_item(nome_item);
	if sprite_icone and item:		
		# Carrega a textura
		var caminho_icone = item.icon
		if caminho_icone != "":
			sprite_icone.texture = load(caminho_icone)
		
		# --- AJUSTE DE TAMANHO DA ART (UPGRADE!) ---
		# Pega a escala_icone do Items.gd. Se não existir, usa 1.0 como padrão.
		var escala_vinda_do_script = item.escala_icone
		
		# Aplicamos a escala no Sprite3D (ajustando X e Y)
		sprite_icone.scale = Vector3(escala_vinda_do_script, escala_vinda_do_script, 1.0)
	
	# 2. Configura a Label de quantidade
	if label_qtd:
		label_qtd.text = str(quantidade_atual)

func _conectarcomglobalitem():
	var item = Items.pegar_item(nome_item)
	if !item:
		return;
		
	if quantidade_atual == 1 && !freeze:
		print("✅ Conectado com sucesso ao Global Items: ", nome_item)
		var res = item.eu_ando
		print(res)
		if res:
			var restempo = item.tempo_eu_ando
			print(restempo)
			await get_tree().create_timer(restempo).timeout
			_saidinhaanoite()
			_conectarcomglobalitem()
	if(quantidade_atual >1 && !freeze):
		print("✅ Conectado com sucesso ao Global Items: ", nome_item)
		print(quantidade_atual)
		var res = item.eu_fujo
		if res:
			var restempo = item.tempo_eu_fujo
			print(restempo)
			await get_tree().create_timer(restempo).timeout
			_fugadaprisao(item)
			_conectarcomglobalitem()
	else:
		await get_tree().create_timer(10.0).timeout 
		_conectarcomglobalitem()
	return	
	
func _saidinhaanoite():
	var direcao_aleatoria = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
	var forca_pulo = 5
	var forca_impulso = 3
	
	var impulso_final= (direcao_aleatoria * forca_impulso) + (Vector3.UP * forca_pulo)
	
	freeze = false
	apply_central_impulse(impulso_final)
	
	if has_method("aplicar_elastico_externo"):
		aplicar_elastico_externo()

func _fugadaprisao(item: Items.Item):
	_diminuirquantidade()
	
	var cena_item = load("res://GirlsAndPotions/Cenas/rigid_body_3d_objeto.tscn")
	var novo_item = cena_item.instantiate()
		
	novo_item.nome_item = self.nome_item
	novo_item.quantidade_atual = 1
		
	var mapa_principal = get_tree().current_scene
	mapa_principal.add_child(novo_item)
	
	var vou_pular = randf_range(0, 1.0) < item.probabilidade_fuga;
	var soma = Vector3.UP * 2 if vou_pular else Vector3.UP * 1;
	novo_item.global_position = self.global_position + soma;
		
	novo_item._saidinhaanoite()

func _ocuparespaco():
	var item = Items.pegar_item(nome_item)
	if !item:
		return
	var res = item.ocupo_espaco
	if(res):
		self.set_collision_layer(3)
		self.set_collision_mask(3)
	else:
		self.set_collision_layer(2)
		self.set_collision_mask(2)
