extends Node

# Called when the node enters the scene tree for the first time.
var receitas = {
	"Poção De Cura" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Cura",
		"item1" : "Flor Da Vida",
		"item2" : "Flor Da Vida",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"Poção De Cura": "res://GirlsAndPotions/Modelos/poção_de_cura.tscn",
		"Mobilia" : "Caldeirao",
		"objeto_necessario": "Frasco Vazio"
	},
	"Poção De Mana" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Mana",
		"item1" : "Flor Magica",
		"item2" : "Flor Magica",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"Poção De Mana": "res://GirlsAndPotions/Modelos/poção_de_mana.tscn",
		"Mobilia" : "Caldeirao",
		"objeto_necessario": "Frasco Vazio"
	},
	"Poção Da Determinação" : {
		"prestigio_minimo" : 5,
		"nome" : "Poção Da Determinação",
		"item1" : "Flor Da Vida",
		"item2" : "Poção De Cura",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 8,
		"Poção Da Determinação": "res://GirlsAndPotions/Modelos/poção_da_determinação.tscn",
		"Mobilia" : "Caldeirao",
		"objeto_necessario": "Frasco Vazio"
	},
	"Poção De Cura Maior" : {
		"prestigio_minimo" : 15,
		"nome" : "Poção De Cura Maior",
		"item1" : "Poção De Cura",
		"item2" : "Poção De Cura",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 10,
		"Poção De Cura Maior": "res://GirlsAndPotions/Modelos/poção_de_cura_maior.tscn",
		"Mobilia" : "Caldeirao",
		"objeto_necessario": "Frasco Vazio"
	},
	"Pétalas De Flor Magica" : {
		"prestigio_minimo" : 0,
		"nome" : "Pétalas De Flor Magica",
		"item1" : "Flor Magica",
		"item2" : "Flor Magica",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"Pétalas De Flor Magica": "res://GirlsAndPotions/Modelos/pétalas_de_flor_magica.tscn",
		"Mobilia" : "TabuaDeCorte",
		"objeto_necessario": null
	}
}

func pegar_receitas_viaveis():
	var pedidos_viaveis = [];
	for nome in receitas:
		if receitas[nome]["pode_fabricar"] == true:
			pedidos_viaveis.append(nome)
	return pedidos_viaveis

func pegar_receita_compativel(items_processando: Array, tipo_de_mobilia: String):
	for nome_id in receitas:
		var dados = receitas[nome_id]
		if dados.get("Mobilia", "") != tipo_de_mobilia: continue

		var ingredientes_receita = [dados["item1"], dados["item2"]]
		if items_processando == ingredientes_receita:
			return dados;
