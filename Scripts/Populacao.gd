extends Node

var velhos = 3
var crianças = 5
var adultos = 100

# Called when the node enters the scene tree for the first time.
func alterarpopulação():
	velhos = adultos * 0.3
	print("Adultos que envelheceram",velhos)
	adultos = adultos - velhos
	print("velhos partiram, sobrou esses adultos:", adultos)
	adultos = adultos + crianças
	print("As crianças se tornaram adultos", adultos)
	crianças = adultos * 0.2
	print("Crianças nasceram!")
	
func get_total_populacao() -> int:
	return int(velhos + crianças + adultos)
