class_name Objeto
extends RigidBody3D

@export var nome_item : String = ""
@export var quantidade_atual : int = 1
# Variável para armazenar a escala original do modelo carregado
var escala_base_modelo : Vector3
var objeto_stackando: Objeto = null;

var esta_congelado_manualmente: bool = false
var estou_ocupado: bool = false

func _ready():
	escala_base_modelo = scale
	carregar_visual_automatico()
	_conectarcomglobalitem()
	_ocuparespaco()

func carregar_visual_automatico():
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
			ajustarescaladoobjeto(false)
	else:
		if FileAccess.file_exists(caminho_modelo_caixa):
			_somvirarcaixa()
			cena_modelo = load(caminho_modelo_caixa)
			ajustarescaladoobjeto(true)
			
			
	if cena_modelo:
		var instancia = cena_modelo.instantiate()
		
		if has_node("CSGBox3D_ObjetoVisual"):
			$CSGBox3D_ObjetoVisual.visible = false
		
		add_child(instancia)
		localizaranimacao()
		
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
	_controlar_animacoes()
	# Se o item estiver parado no ar (freeze falso) mas não estiver caindo (linear_velocity baixa)
	# e não tiver ninguém segurando ele (pai é a cena principal)
	if not freeze and not esta_congelado_manualmente and linear_velocity.length() < 0.1 and get_parent() == get_tree().current_scene:
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
	and body.freeze == false
	and body.esta_congelado_manualmente == false):
		_stackaritens(body)

func _stackaritens(outro_item: Objeto):
	if outro_item.objeto_stackando || self.objeto_stackando:
		return

	self.objeto_stackando = outro_item;
	outro_item.objeto_stackando = self;
	self.quantidade_atual += outro_item.quantidade_atual
	outro_item.queue_free()
	carregar_visual_automatico()
	print(self.quantidade_atual)
	self.objeto_stackando = null;

func _diminuirquantidade():
	if quantidade_atual > 1:
		quantidade_atual -= 1
		carregar_visual_automatico() # O elástico vai rodar aqui também!
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
	if !item or (item.eu_ando == false and item.eu_fujo == false):
		return

	# Se já houver um loop rodando, não comece outro
	if estou_ocupado:
		return
	
	estou_ocupado = true

	# Loop contínuo enquanto o objeto existir
	while is_inside_tree() and estou_ocupado:
		# Se estiver congelado ou no freeze, esperamos um pouco e tentamos de novo
		if freeze or esta_congelado_manualmente:
			await get_tree().create_timer(2.0).timeout
			continue

		# Lógica para 1 unidade (Andar/Pular)
		if quantidade_atual == 1 and item.eu_ando:
			await get_tree().create_timer(item.tempo_eu_ando).timeout
			# Checagem de segurança pós-espera
			if is_inside_tree() and !freeze and !esta_congelado_manualmente and quantidade_atual == 1:
				_saidinhaanoite()
		
		# Lógica para Pilha (Fuga)
		elif quantidade_atual > 1 and item.eu_fujo:
			await get_tree().create_timer(item.tempo_eu_fujo).timeout
			# Checagem de segurança pós-espera
			if is_inside_tree() and !freeze and !esta_congelado_manualmente and quantidade_atual > 1:
				_fugadaprisao(item)
		
		# Pequena pausa entre ciclos para não travar o jogo e evitar loops infinitos instantâneos
		await get_tree().create_timer(1.0).timeout

	estou_ocupado = false
	
func _saidinhaanoite():
	var direcao_aleatoria = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()

	var forca_pulo = 5
	var forca_impulso = 3
	
	var impulso_final= (direcao_aleatoria * forca_impulso) + (Vector3.UP * forca_pulo)
	look_at(global_position + direcao_aleatoria, Vector3.UP)
	
	#freeze = false
	
	apply_central_impulse(impulso_final)
	
	if has_method("aplicar_elastico_externo"):
		aplicar_elastico_externo()
	return
func _fugadaprisao(item: Items.Item):
	_diminuirquantidade()
	
	var cena_item = load("res://GirlsAndPotions/Cenas/rigid_body_3d_objeto.tscn")
	var novo_item = cena_item.instantiate()
		
	novo_item.nome_item = self.nome_item
	novo_item.quantidade_atual = 1
		
	var mapa_principal = get_tree().current_scene
	mapa_principal.add_child(novo_item)
	
	var vou_pular = randf_range(0.5, 1.0) < item.probabilidade_fuga;
	var soma = Vector3.UP * 2 if vou_pular else Vector3.UP * 1;
	novo_item.global_position = self.global_position + soma;
		
	novo_item.congelar_objeto()
	novo_item._saidinhaanoite()
	await get_tree().create_timer(0.1).timeout  
	novo_item.descongelar_objeto()
	novo_item = null
	return
	
func _ocuparespaco():
	var item = Items.pegar_item(nome_item)
	if !item:
		return
	if(item.ocupo_espaco):
		self.set_collision_layer(3)
		self.set_collision_mask(3)
	else:
		self.set_collision_layer(2)
		self.set_collision_mask(2)
		
func desativar_colisao():
	# Supondo que o CollisionShape3D seja filho direto do RigidBody3D
	$CollisionShape3D.disabled = true

func ativar_colisao():
	$CollisionShape3D.disabled = false

func localizaranimacao():
	# 1. Procuramos o AnimationPlayer dentro dos filhos deste objeto
	# O True no final do find_child faz a busca ser recursiva (procura em todos os sub-nós)
	var anim_player = find_child("AnimationPlayer", true, false)
	
	if anim_player and anim_player is AnimationPlayer:
		print("🎬 AnimationPlayer encontrado no item: ", nome_item)
		
		# 2. Pegamos a biblioteca de animações
		var lista_animacoes = anim_player.get_animation_list()
		
		if lista_animacoes.size() > 0:
			print("📜 Animações disponíveis para [", nome_item, "]:")
			for anim_name in lista_animacoes:
				print("  - ", anim_name)
		else:
			print("⚠️ O AnimationPlayer de ", nome_item, " existe, mas está vazio.")
	else:
		print("❌ Nenhum AnimationPlayer encontrado para o item: ", nome_item)

func _controlar_animacoes():
	var anim = find_child("AnimationPlayer", true, false)
	
	if !anim: return
	if esta_congelado_manualmente == true:
		anim.play("Armação|Carregado")
		# 1. Se o sapo estiver voando (subindo ou caindo rápido)
	if abs(linear_velocity.y) > 0.5 && !esta_congelado_manualmente:
		if linear_velocity.y > 0:
			anim.play("Armação|Pulando") # Subindo
		else:
			anim.play("Armação|Voando")   # Caindo (batendo as pernas)
			
	# 2. Se o sapo estiver praticamente parado no chão
	elif linear_velocity.length() < 0.2 && !esta_congelado_manualmente:
		# Se ele estiver sendo carregado (quantidade_atual no seu sistema)
		# ou se você quiser usar a animação de 'Carregado' em algum momento:
		if anim.current_animation != "Armação|Parado":
			anim.play("Armação|Parado")

func congelar_objeto():
	esta_congelado_manualmente = true
	
	# 1. Desativa a gravidade (O objeto para de cair)
	gravity_scale = 0.0
	
	# 2. Zera as velocidades atuais para ele parar no ar instantaneamente
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# 3. Desativa as colisões (Ele para de bater e ser batido)
	# Usamos set_deferred para evitar erros de física se a função for chamada 
	# no meio de um cálculo de colisão.
	$CollisionShape3D.set_deferred("disabled", true)
	
	# 4. (Opcional) Se tiver Area3D para monitoramento de stack, desative também
	if has_node("Area3D_Monitor"):
		$Area3D_Monitor.set_deferred("monitoring", false)
		$Area3D_Monitor.set_deferred("monitorable", false)

	print("❄️ Objeto '", nome_item, "' congelado manualmente.")
	
func descongelar_objeto():
	esta_congelado_manualmente = false
	
	# 1. Restaura a gravidade padrão
	gravity_scale = 1.0
	
	# 2. Reativa os colisores
	$CollisionShape3D.set_deferred("disabled", false)
	
	if has_node("Area3D_Monitor"):
		$Area3D_Monitor.set_deferred("monitoring", true)
		$Area3D_Monitor.set_deferred("monitorable", true)

	print("🔥 Objeto '", nome_item, "' liberado para a física.")

func ajustarescaladoobjeto(caixa: bool):
	# 1. Pegamos os dados do item na Global
	var item = Items.pegar_item(nome_item)
	print("aminha escala é:", item.minha_scala)
	
	if !item:
		return

	if caixa:
		# Se for caixa, a escala do RigidBody volta para o padrão (1, 1, 1)
		self.scale = Vector3.ONE
	else:
		# Se não for caixa, aplicamos o multiplicador 'minha_scala'
		# Como o valor original do nó na cena é (1,1,1), basta atribuir o novo Vector3
		var fator = item.minha_scala
		self.scale = Vector3(fator, fator, fator)
	
	print("📏 Escala do RigidBody ajustada. Caixa: ", caixa, " | Escala Final: ", self.scale)
