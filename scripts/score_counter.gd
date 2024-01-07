extends Label

func _process(delta):
	self.text = str(world.score)
