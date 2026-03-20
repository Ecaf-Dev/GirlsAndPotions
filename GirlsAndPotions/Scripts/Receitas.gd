extends Node

class Receita:
	var id: String
	var prestigio_minimo: int
	var nome: String
	var ingredientes: Array[String] = []
	var pode_fabricar: bool
	var tempo_de_cozinha: int
	var modelo: String
	var mobilia: String
	var objeto_necessario

	func _init(receita_dictionary: Dictionary):
		self.id = receita_dictionary.get("nome", null)
		self.prestigio_minimo = receita_dictionary.get("prestigio_minimo", 0)
		self.nome = receita_dictionary.get("nome", null)
		self.ingredientes.assign(receita_dictionary.get("ingredientes", [])) 
		self.pode_fabricar = receita_dictionary.get("pode_fabricar", false)
		self.tempo_de_cozinha = receita_dictionary.get("tempo_de_cozinha", 0)
		self.modelo = receita_dictionary.get("modelo", null)
		self.mobilia = receita_dictionary.get("mobilia", null)
		self.objeto_necessario = receita_dictionary.get("objeto_necessario", null)

# Called when the node enters the scene tree for the first time.
var receitas = {
	"Poção De Cura" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Cura",
		"ingredientes": ["Flor Da Vida", "Flor Da Vida"],
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"modelo": "res://GirlsAndPotions/Modelos/poção_de_cura.tscn",
		"mobilia" : "Caldeirao",
		"objeto_necessario": "Frasco Vazio"
	},
	"Poção De Mana" : {
		"prestigio_minimo" : 0,
		"nome" : "Poção De Mana",
		"ingredientes": ["Flor Magica", "Flor Magica"],
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"modelo": "res://GirlsAndPotions/Modelos/poção_de_mana.tscn",
		"mobilia" : "Caldeirao",
		"objeto_necessario": "Frasco Vazio"
	},
	"Poção Da Determinação" : {
		"prestigio_minimo" : 5,
		"nome" : "Poção Da Determinação",
		"ingredientes": ["Flor Da Vida", "Poção De Cura"],
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 8,
		"modelo": "res://GirlsAndPotions/Modelos/poção_da_determinação.tscn",
		"mobilia" : "Caldeirao",
		"objeto_necessario": "Frasco Vazio"
	},
	"Poção De Cura Maior" : {
		"prestigio_minimo" : 15,
		"nome" : "Poção De Cura Maior",
		"ingredientes": ["Poção De Cura", "Poção De Cura"],
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 10,
		"modelo": "res://GirlsAndPotions/Modelos/poção_de_cura_maior.tscn",
		"mobilia" : "Caldeirao",
		"objeto_necessario": "Frasco Vazio"
	},
	"Pétalas De Flor Magica" : {
		"prestigio_minimo" : 0,
		"nome" : "Pétalas De Flor Magica",
		"ingredientes": ["Flor Magica"],
		"pode_fabricar" : true,
		"tempo_de_cozinha" : 4,
		"modelo": "res://GirlsAndPotions/Modelos/pétalas_de_flor_magica.tscn",
		"mobilia" : "TabuaDeCorte",
		"objeto_necessario": null
	}
}

func pegar_receita(nome_receita) -> Receita:
	if !receitas.has(nome_receita):
		print("RECEITA NÃO ESTÁ CONFIGURADA NO RECEITAS.GD -> ", nome_receita)
		return null;
	return Receita.new(receitas[nome_receita]);

func pegar_receitas_viaveis() -> Array:
	var pedidos_viaveis = [];
	for nome in receitas:
		if receitas[nome]["pode_fabricar"] == true:
			pedidos_viaveis.append(nome)
	return pedidos_viaveis

func pegar_receita_compativel(items_processando: Array[String], tipo_de_mobilia: String) -> Receita:
	for nome_id in receitas:
		var receita = Receita.new(receitas[nome_id]);
		if receita.mobilia != tipo_de_mobilia: continue
		
		if items_processando == receita.ingredientes:
			return receita;
	return null;

func pegar_todas_as_receitas() -> Array[Receita]:
	var todas: Array[Receita] = [];
	for id in Receitas.receitas:
		todas.append(Receita.new(Receitas.receitas[id]))
	return todas;
