extends StaticBody3D

@export var pedidos = []
@export var max_pedidos = 3

const POCOES_POSSIVEIS = ["Poção De Cura"]


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_gerarpedidos()

func _gerarpedidos():
	if pedidos.size() < max_pedidos:
		var nova_pocao = POCOES_POSSIVEIS.pick_random()
		pedidos.append(nova_pocao)
		print("NOVO PEDIDO ADICIONADO: ", nova_pocao)
		print("PEDIDOS PENDENTES: ", pedidos)
	


func _on_area_3d_monitor_body_entered(body):
	if "nome_item" in body:
		_checarentrega(body) # Replace with function body.

func _checarentrega(objeto):
	# Verificamos se o nome do item que colidiu está dentro da nossa lista de pedidos
	if objeto.nome_item in pedidos:
		print("SUCESSO: O item '", objeto.nome_item, "' era um dos pedidos!")
		
		# Remove APENAS uma instância desse pedido da lista
		pedidos.erase(objeto.nome_item)
		
		# Deleta o objeto físico
		objeto.queue_free()
		
		# Chama a recompensa e gera um novo pedido para manter o fluxo
		_recompensa()
	else:
		print("REJEITADO: Ninguém pediu '", objeto.nome_item, "' no momento.")
		_rejeitar_item(objeto)
		
func _recompensa():
	# Aqui você pode adicionar moedas, XP ou apenas um efeito sonoro/partícula
	print("RECOMPENSA: Você ganhou 10 moedas de ouro!")
	
func _rejeitar_item(item):
	if item is RigidBody3D:
		# Empurra o item para longe do balcão (em arco)
		var direcao = (item.global_position - global_position).normalized()
		item.apply_central_impulse(direcao * 4.0 + Vector3.UP * 3.0)
		
