extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var scene: PackedScene = preload("res://main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    for relay in game.relays:
        relay.r = 0
    game.moves = 9
    game.solved = true
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_viewport().get_texture().get_image().save_png("D:/Signal Keeper/.verification/qa_solved_fixed.png")
    quit()
