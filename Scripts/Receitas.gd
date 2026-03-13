extends Node

# Este script funciona como um Banco de Dados Global para suas receitas
var receitas = {
	"Poção De Cura" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Cura",
		"item1" : "Tabua De Essencia Da Vida",
		"item2" : "Tabua De Essencia Da Vida",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"caminho_modelo": "res://GirlsAndPotions/Modelos/poção_de_cura.tscn",
		"Sequencia": [],
		"Mobilia" : "Caldeirao"
	},
	"Poção De Mana" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Mana",
		"item1" : "Tabua De Essencia Magica",
		"item2" : "Tabua De Essencia Magica",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"caminho_modelo": "res://GirlsAndPotions/Modelos/poção_de_mana.tscn",
		"Sequencia": [],
		"Mobilia" : "Caldeirao"
	},
	"Poção Da Determinação" : {
		"prestigio_minimo" : 5,
		"nome" : "Poção Da Determinação",
		"item1" : "Tabua De Essencia Da Vida",
		"item2" : "Poção De Cura",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 8,
		"caminho_modelo": "res://GirlsAndPotions/Modelos/poção_da_determinação.tscn",
		"Sequencia": [],
		"Mobilia" : "Caldeirao"
	},
	"Poção De Cura Maior" : {
		"prestigio_minimo" : 15,
		"nome" : "Poção De Cura Maior",
		"item1" : "Poção De Cura",
		"item2" : "Poção De Cura",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 10,
		"caminho_modelo": "res://GirlsAndPotions/Modelos/poção_de_cura_maior.tscn",
		"Sequencia": [],
		"Mobilia" : "Caldeirao"
	},
	# --- RECEITAS DO MORTAR ---
	"Tabua De Essencia Da Vida" : {
		"prestigio_minimo" : 0,
		"nome" : "Tabua De Essencia Da Vida",
		"item1" : "Flor Da Vida", # O ingrediente bruto
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 2, # Mortar costuma ser instantâneo, focado na sequência
		"caminho_modelo": "res://GirlsAndPotions/Modelos/tabua_de_essencia_da_vida.tscn",
		"Sequencia": [], # Sequência de "amassar"
		"Mobilia" : "Mortar"
	},
	# --- RECEITAS DO MORTAR ---
		"Tabua De Essencia Magica" : {
			"prestigio_minimo" : 0,
			"nome" : "Tabua De Essencia Magica",
			"item1" : "Flor Magica", # O ingrediente bruto
			"pode_fabricar" : true,
			"tempo_de_cozinha" : 2, # Mortar costuma ser instantâneo, focado na sequência
			"caminho_modelo": "res://GirlsAndPotions/Modelos/tabua_de_essencia_magica.tscn",
			"Sequencia": [], # Sequência de "amassar"
			"Mobilia" : "Mortar"
	}
}
