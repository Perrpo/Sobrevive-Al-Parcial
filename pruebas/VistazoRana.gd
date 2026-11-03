extends Node3D
## Herramienta de desarrollo: foto de la Xaca Rana de frente, del profe y de la rana dorada.
func _ready() -> void:
	var entorno := WorldEnvironment.new()
	entorno.environment = Environment.new()
	entorno.environment.background_mode = Environment.BG_COLOR
	entorno.environment.background_color = Color("#101914")
	entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.environment.ambient_light_color = Color.WHITE
	entorno.environment.ambient_light_energy = 0.6
	add_child(entorno)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-30, 10, 0)
	add_child(luz)
	var r := Constructor.rana()
	r.scale = Vector3.ONE * 3
	r.position = Vector3(-2.2, 0, 0)
	add_child(r)
	var p := Constructor.profe_rana()
	p.position = Vector3(0.6, -0.6, 0)
	add_child(p)
	var d := Constructor.rana(true)
	d.scale = Vector3.ONE * 3
	d.position = Vector3(3.0, 0, 0)
	add_child(d)
	var c := Camera3D.new()
	c.position = Vector3(0.3, 1.3, 5.5)
	add_child(c)
	c.look_at(Vector3(0.3, 0.9, 0))
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
