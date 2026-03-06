extends Node

# Este script funciona como um Banco de Dados Global para suas receitas
var receitas = {
	"Poção De Cura" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Cura",
		"item1" : "Flor Da Vida",
		"item2" : "Flor Da Vida",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"caminho_modelo": "res://GirlsAndPotions/Modelos/poção_de_cura.tscn",
		"Sequencia": ["Cima", "Esquerda", "Baixo", "Direita"],
		"Mobilia" : "Caldeirao"
	},
	"Poção De Mana" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Mana",
		"item1" : "Flor Magica",
		"item2" : "Flor Magica",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"caminho_modelo": "res://GirlsAndPotions/Modelos/poção_de_mana.tscn",
		"Sequencia": ["Cima", "Direita", "Baixo", "Esquerda"],
		"Mobilia" : "Caldeirao"
	},
	"Poção Da Determinação" : {
		"prestigio_minimo" : 5,
		"nome" : "Poção Da Determinação",
		"item1" : "Flor Da Vida",
		"item2" : "Poção De Cura",
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 8,
		"caminho_modelo": "res://GirlsAndPotions/Modelos/poção_da_determinação.tscn",
		"Sequencia": ["Cima", "Baixo", "Esquerda", "Direita", "Cima"],
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
		"Sequencia": ["Baixo", "Cima", "Baixo", "Cima", "Esquerda", "Direita"],
		"Mobilia" : "Caldeirao"
	},
	# --- RECEITAS DO MORTAR ---
	"Tabua De Essencia Da Vida" : {
		"prestigio_minimo" : 0,
		"nome" : "Tabua De Essencia Da Vida",
		"item1" : "Flor Da Vida", # O ingrediente bruto
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 0, # Mortar costuma ser instantâneo, focado na sequência
		"caminho_modelo": "res://GirlsAndPotions/Modelos/tabua_de_essencia_da_vida.tscn",
		"Sequencia": ["Baixo", "Baixo", "Cima"], # Sequência de "amassar"
		"Mobilia" : "Mortar"
	},
	# --- RECEITAS DO MORTAR ---
		"Tabua De Essencia Magica" : {
			"prestigio_minimo" : 0,
			"nome" : "Tabua De Essencia Magica",
			"item1" : "Flor Magica", # O ingrediente bruto
			"pode_fabricar" : true,
			"tempo_de_cozinha" : 0, # Mortar costuma ser instantâneo, focado na sequência
			"caminho_modelo": "res://GirlsAndPotions/Modelos/tabua_de_essencia_magica.tscn",
			"Sequencia": ["Esquerda", "Direita", "Cima"], # Sequência de "amassar"
			"Mobilia" : "Mortar"
	}
}
