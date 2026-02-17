extends Node


# Called when the node enters the scene tree for the first time.
var receitas = {
	"Poção De Cura" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Cura",
		"item1" : "Flor Da Vida",
		"item2" : "Flor Da Vida",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4
	},
	"Poção De Mana" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Mana",
		"item1" : "Flor Magica",
		"item2" : "Flor Magica",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4
	},
	"Poção Da Determinação" : {
		"prestigio_minimo" : 5,
		"nome" : "Poção Da Determinação",
		"item1" : "Flor Da Vida",
		"item2" : "Poção De Cura",
		"pode_fabricar" : false,
		"tempo_de_cozinha" : 8
	},
	"Poção De Cura Maior" : {
		"prestigio_minimo" : 15,
		"nome" : "Poção De Cura Maior",
		"item1" : "Poção De Cura",
		"item2" : "Poção De Cura",
		"pode_fabricar" : false,
		"tempo_de_cozinha" : 10
	},
	
	
}
