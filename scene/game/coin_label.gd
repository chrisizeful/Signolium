extends Label

func _ready():
	_on_coin_collected()
	var game := get_node("/root/Game") as Game
	game.player.coins_changed.connect(_on_coin_collected)

func _on_coin_collected():
	var game := get_node("/root/Game") as Game
	text = str(game.player.coins) + "/" + str(Player.coins_required)
