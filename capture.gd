extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var scene: PackedScene = preload("res://main.tscn")
    root.add_child(scene.instantiate())
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_viewport().get_texture().get_image()
    image.save_png("D:/Signal Keeper/.verification/signal_keeper_prototype.png")
    quit()
