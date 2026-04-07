extends Node

# representa quanto de ouro a mais a gente coloca de margem em pedidos para conseguir o ranqueamento máximo
var fator_balanceamento_ouro: float = 20;
var fase_atual: Array = []
var tamanho_do_mapa: Array = []

class Ranqueamento:
	var ouro_minimo: float
	var estrelas: int

	func _init(dictionary: Dictionary):
		self.ouro_minimo = dictionary.get("ouro_minimo", 0)
		self.estrelas = dictionary.get("estrelas", 0)

class Fase:
	var id: String
	var nome: String
	var ranqueamentos: Array[Ranqueamento] = []
	var tempo_limite_de_jogo: int
	var largura: int  # Novo
	var profundidade: int # Novo
	var dados_mobilias: Dictionary

	func _init(dictionary: Dictionary):
		self.id = dictionary.get("nome", null)
		self.nome = dictionary.get("nome", null)
		self.ranqueamentos = _gerar_ranqueamentos(dictionary)
		self.tempo_limite_de_jogo = dictionary.get("tempo_limite_de_jogo", 0)
		var tamanho = dictionary.get("tamanhodafase", {"x": 2, "z": 2})
		self.largura = tamanho.x
		self.profundidade = tamanho.z
		self.dados_mobilias = dictionary.get("mobilias", {})

	func pegar_numero_de_estrelas(ouro: float) -> int:
		var ranqueamento_atual: Ranqueamento = null;
		for ranqueamento in ranqueamentos:
			ranqueamento_atual = ranqueamento
			if ouro < ranqueamento.ouro_minimo:
				return ranqueamento.estrelas - 1
		return ranqueamento_atual.estrelas

	func pegar_ranqueamento_maximo() -> Ranqueamento:
		# criamos nova referência pra não alterar a referência principal
		var nova_referencia_ranqueamentos = ranqueamentos.duplicate()
		nova_referencia_ranqueamentos.sort_custom(func(a: Ranqueamento, b:Ranqueamento): return a.estrelas > b.estrelas)

		return nova_referencia_ranqueamentos[0];

	func gerar_pedidos() -> Array[Receitas.Receita]:
		var pedidos_viaveis = Receitas.pegar_receitas_viaveis()
		if pedidos_viaveis.is_empty(): return [];

		var ouro_atual: float = 0;
		var ranqueamento_maximo = pegar_ranqueamento_maximo()
		var pedidos_da_fase: Array[Receitas.Receita] = []
		while ouro_atual <= ranqueamento_maximo.ouro_minimo + Fases.fator_balanceamento_ouro:
			var pedido = pedidos_viaveis.pick_random()
			var item = Items.pegar_item(pedido.nome)
			if !item || item.valor_venda == 0:
				continue;
			pedidos_da_fase.append(pedido)
			ouro_atual += item.valor_venda
		print("Pedidos Gerados: Ouro total da fase: ", ouro_atual)
		return pedidos_da_fase;
		
	func _gerar_ranqueamentos(dictionary: Dictionary) -> Array[Ranqueamento]:
		var ranqueamento_dictionary = []
		ranqueamento_dictionary.assign(dictionary.get("ranqueamentos", []))
		var ranqueamento_parseado: Array[Ranqueamento] = []
		ranqueamento_parseado.assign(ranqueamento_dictionary.map(func(d: Dictionary): return Ranqueamento.new(d)))
		return ranqueamento_parseado

var sequencia_fases = [
	"Fase 1",
	"Fase 2",
	"Fase 3"
]

var fases = {
	"Fase 1":{
		"nome": "Fase 1",
		"ranqueamentos":[
			{
				"ouro_minimo": 10,
				"estrelas": 1
			},
			{
				"ouro_minimo": 20,
				"estrelas": 2
			},
			{
				"ouro_minimo": 30,
				"estrelas": 3
			}
		],
		"tamanhodafase": {
			"x": 20,
			"z": 20 # Usei Z porque em 3D o "chão" costuma ser X e Z
		},
		"mobilias": {
			"caldeirao" : {
				"x":10,
				"y": 10
			},
			"tabua_de_corte" : {
				"x": 5,
				"y": 5
			},
			"balcao": {
				"x": 9,
				"y": 5
			},
			"caixa_ce_correio": {
				"x": 2,
				"y": 6
			}
		}, 
		"tempo_limite_de_jogo": 120
	}
}

func pegar_fase(nome) -> Fase:
	if !fases.has(nome):
		print("FASE NÃO ESTÁ CONFIGURADA NO FASES.GD -> ", nome)
		return null;
	return Fase.new(fases[nome]);

func pegar_todas_as_fases() -> Array[Fase]:
	var todas: Array[Fase] = [];
	for id in Fases.fases:
		todas.append(Fase.new(Fases.fases[id]))
	return todas;

	
