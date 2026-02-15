# No script da cena VBoxContainer_Item.tscn
extends VBoxContainer

var id_do_item = ""

func configurar(id, dados):
	id_do_item = id
	$Label_Nome.text = dados.nome
	# Se tiver o nó de preço:
	$Label_Preco.text = str(dados.valor_compra) + " G"
	# Se tiver imagem:
	# $ColorRect_Imagem.texture = load(dados.icon)
