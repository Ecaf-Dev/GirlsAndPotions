extends Node

# --- DEFINIÇÃO DA CLASSE (O MOLDE) ---
class Mobilia:
	var id: String
	var nome: String
	var descricao: String
	var cena_path: String
	var minha_scala: float
	var particularidades: Dictionary

	# O _init PRECISA estar dentro do bloco da classe 'class Mobilia'
	func _init(mobilia_dictionary: Dictionary):
		self.id = mobilia_dictionary.get("nome", "")
		self.nome = mobilia_dictionary.get("nome", "")
		self.descricao = mobilia_dictionary.get("descricao", "")
		self.cena_path = mobilia_dictionary.get("cena_path", "")
		self.minha_scala = mobilia_dictionary.get("minha_scala", 1.0)
		self.particularidades = mobilia_dictionary.get("particularidades", {})

# --- DADOS DAS MOBÍLIAS (O DICIONÁRIO) ---
var mobilias_dados = {
	"balcao": {
		"nome": "Balcão",
		"descricao": "Balcão de uma loja, gera pedidos a cada dia",
		"cena_path": "res://GirlsAndPotions/Cenas/static_body_3d_balcao.tscn",
		"minha_scala": 1.5,
		"particularidades" : {
			"nome_fase": "Fase 1",
			"max_pedidos": 3,
		}
	},
	"caldeirao": {
		"nome": "Caldeirão",
		"descricao": "Um caldeirão que todo iniciante da alquimia precisa, cuidado ele explode!",
		"cena_path": "res://GirlsAndPotions/Cenas/static_body_3d_caldeirao.tscn",
		"minha_scala": 1.7,
		"particularidades": {
			"max_slots": 2,
			"mobilia_automatica": true
		}
	},
	"tabua_de_corte": {
		"nome": "Tábua De Corte",
		"descricao": "Uma tábua para cortar diversas criaturas e plantas",
		"cena_path": "res://GirlsAndPotions/Cenas/static_body_3d_tabua_de_corte.tscn",
		"minha_scala": 1.5,
		"particularidades": {
			"max_slots": 1,
			"mobilia_automatica": false
		}
	},
	"caixa_de_correio": {
		"nome": "Caixa De Correio",
		"descricao": "Uma caixa de correio, onde você irá receber suas compras!",
		"cena_path": "res://GirlsAndPotions/Cenas/static_body_3d_caixa_de_correio.tscn",
		"minha_scala": 1.3,
		"particularidades": {}
	},
	"mesa": {
		"nome": "mesa",
		"descricao": "Uma mesa que apenas ocupa espaço.",
		"cena_path": "res://GirlsAndPotions/Cenas/node_3d_mesa.tscn",
		"minha_scala": 1.0,
		"particularidades": {}
	}
}

# --- FUNÇÕES DE BUSCA ---
func pegar_mobilia(nome_mobilia: String) -> Mobilia:
	if !mobilias_dados.has(nome_mobilia):
		print("MOBÍLIA NÃO CONFIGURADA NO MOBILIAS.GD -> ", nome_mobilia)
		return null
	
	# Criamos uma nova instância da classe Mobilia usando os dados do dicionário
	return Mobilia.new(mobilias_dados[nome_mobilia])

func pegar_todos_as_mobilias() -> Array[Mobilia]:
	var lista_de_objetos_mobilia: Array[Mobilia] = []
	
	# Percorremos as CHAVES do dicionário de dados (ex: "Balcao", "Caldeirao"...)
	for chave in mobilias_dados:
		# Criamos um objeto novo para cada entrada e colocamos na Array
		var nova_mobilia = Mobilia.new(mobilias_dados[chave])
		lista_de_objetos_mobilia.append(nova_mobilia)
	
	return lista_de_objetos_mobilia
