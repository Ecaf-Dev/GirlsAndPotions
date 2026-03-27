extends Node

class Item:
	var id: String
	var nome: String
	var descricao: String
	var valor_compra: float
	var valor_venda: float
	var icon: String
	var compravel: bool
	var escala_icone: float
	var eu_ando: bool
	var tempo_eu_ando: float
	var eu_fujo: bool
	var tempo_eu_fujo: float
	var probabilidade_fuga: float
	var ocupo_espaco: bool

	func _init(item_dictionary: Dictionary):
		self.id = item_dictionary.get("nome", null)
		self.nome = item_dictionary.get("nome", null)
		self.descricao = item_dictionary.get("descricao", null)
		self.valor_compra = item_dictionary.get("valor_compra", 0)
		self.valor_venda = item_dictionary.get("valor_venda", 0)
		self.icon = item_dictionary.get("icon", null)
		self.compravel = item_dictionary.get("compravel", false)
		self.escala_icone = item_dictionary.get("escala_icone", 0)
		self.eu_ando = item_dictionary.get("eu_ando", false)
		self.tempo_eu_ando = item_dictionary.get("tempo_eu_ando", 0)
		self.eu_fujo = item_dictionary.get("eu_fujo", false)
		self.tempo_eu_fujo = item_dictionary.get("tempo_eu_fujo", 0)
		self.probabilidade_fuga = item_dictionary.get("probabilidade_fuga", 0)
		self.ocupo_espaco = item_dictionary.get("ocupo_espaco", false)

# Called when the node enters the scene tree for the first time.
var itens = {
	"Flor Da Vida": {
		"nome": "Flor Da Vida",
		"descricao": "Uma flor vibrante que pulsa com energia vital.",
		"valor_compra": 2,
		"valor_venda": 0,
		"icon": "res://GirlsAndPotions/Arts/Icones/flor_da_vida.png",
		"compravel": true,
		"escala_icone" : 0.7,
		"eu_ando" : false,
		"tempo_eu_ando" : 5,
		"eu_fujo" : false,
		"tempo_eu_fujo": 3,
		"probabilidade_fuga": 1,
		"ocupo_espaco": false
		
	},
	"Flor Magica": {
		"nome": "Flor Magica",
		"descricao": "Uma flor pulsando magia",
		"valor_compra": 2,
		"valor_venda": 0,
		"icon": "res://GirlsAndPotions/Arts/Icones/Flor_magica.png",
		"compravel": true,
		"escala_icone" : 0.5,
		"eu_ando" : false,
		"tempo_eu_ando" : 0,
		"eu_fujo" : false,
		"tempo_eu_fujo": 0,
		"probabilidade_fuga": 0,
		"ocupo_espaco": false
	},
	"Frasco Vazio": {
		"nome": "Frasco Vazio",
		"descricao": "Uma flor pulsando magia",
		"valor_compra": 1,
		"valor_venda": 0,
		"icon": "res://GirlsAndPotions/Arts/Icones/frasco_vazio.png",
		"compravel": true,
		"escala_icone" : 0.3,
		"eu_ando" : false,
		"tempo_eu_ando" : 0,
		"eu_fujo" : false,
		"tempo_eu_fujo": 0,
		"probabilidade_fuga": 0,
		"ocupo_espaco": false
	},
	"Poção De Cura": {
		"nome": "Poção De Cura",
		"descricao": "Uma poção que cura pequenos ferimentos e doenças corriqueiras",
		"valor_compra": 0,
		"valor_venda": 6,
		"icon": "res://GirlsAndPotions/Arts/Icones/poção_de_cura.png",
		"compravel": false,
		"escala_icone" : 0.6,
		"eu_ando" : false,
		"tempo_eu_ando" : 0,
		"eu_fujo" : false,
		"tempo_eu_fujo": 0,
		"probabilidade_fuga": 0,
		"ocupo_espaco": false
	},
	"Poção Da Determinação": {
		"nome": "Poção Da Determinação",
		"descricao": "Uma poção que revigora o espirito, o tornando mais valente",
		"valor_compra": 0,
		"valor_venda": 10,
		"icon": "res://GirlsAndPotions/Arts/Icones/poção_da_determinação.png",
		"compravel": false,
		"escala_icone" : 0.6,
		"eu_ando" : false,
		"tempo_eu_ando" : 0,
		"eu_fujo" : false,
		"tempo_eu_fujo": 0,
		"probabilidade_fuga": 0,
		"ocupo_espaco": false
	},
	"Poção De Mana": {
		"nome": "Poção De Mana",
		"descricao": "Uma poção que recupera um pouco a energia de um mago",
		"valor_compra": 0,
		"valor_venda": 5,
		"icon": "res://GirlsAndPotions/Arts/Icones/poção_de_mana.png",
		"compravel": false,
		"escala_icone" : 0.6,
		"eu_ando" : false,
		"tempo_eu_ando" : 0,
		"eu_fujo" : false,
		"tempo_eu_fujo": 0,
		"probabilidade_fuga": 0,
		"ocupo_espaco": false
	},
	"Poção De Cura Maior": {
		"nome": "Poção De Cura Maior",
		"descricao": "Uma poção que cura ferimentos graves e doenças incomuns",
		"valor_compra": 0,
		"valor_venda": 12,
		"icon": "res://GirlsAndPotions/Arts/Icones/poção_de_cura_maior.png",
		"compravel": false,
		"escala_icone" : 0.5,
		"eu_ando" : false,
		"tempo_eu_ando" : 0,
		"eu_fujo" : false,
		"tempo_eu_fujo": 7,
		"probabilidade_fuga": 1,
		"ocupo_espaco": false
	},
	"Petalas Da Flor Da Vida" :{
		"nome": "Petalas Da Flor Da Vida",
		"descricao": "As petalas cortadas de uma flor da vida",
		"valor_compra": 0,
		"valor_venda": 0,
		"icon": "res://GirlsAndPotions/Arts/Icones/petalas_da_flor_da_vida.png",
		"compravel": false,
		"escala_icone" : 0.5,
		"eu_ando" : false,
		"tempo_eu_ando" : 0,
		"eu_fujo" : false,
		"tempo_eu_fujo": 0,
		"probabilidade_fuga": 0,
		"ocupo_espaco": false
	},
	"El Sapon" :{
		"nome": "El Sapon",
		"descricao": "Um sapinho do balaco bacu",
		"valor_compra": 3,
		"valor_venda": 0,
		"icon": "res://GirlsAndPotions/Arts/Icones/el_sapon.png",
		"compravel": true,
		"escala_icone" : 0.2,
		"eu_ando" : true,
		"tempo_eu_ando" : 4,
		"eu_fujo" : true,
		"tempo_eu_fujo": 12,
		"probabilidade_fuga": 0.9,
		"ocupo_espaco": true
	}
}

func pegar_item(nome_item) -> Item:
	if !itens.has(nome_item):
		print("ITEM NÃO ESTÁ CONFIGURADO NO ITEMS.GD -> ", nome_item)
		return null;
	return Item.new(itens[nome_item]);

func pegar_todos_os_items() -> Array[Item]:
	var items: Array[Item] = [];
	for id in Items.itens:
		items.append(Item.new(Items.itens[id]))
	return items;
