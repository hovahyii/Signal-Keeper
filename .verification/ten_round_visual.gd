extends SceneTree

var game: Node2D

func _initialize() -> void:
    call_deferred("run")

func capture(file_name: String) -> void:
    game.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    var result: int = root.get_texture().get_image().save_png("res://.verification/" + file_name + ".png")
    if result != OK:
        push_error("Screenshot save failed")

func run() -> void:
    game = load("res://main.tscn").instantiate()
    root.add_child(game)
    game.demo_ads_enabled = true
    await capture("ten_round_ready")
    for i in game.move_limit:
        game.rotate_at(game.cell_center(Vector2i(2,2)))
    await capture("ten_round_out_of_moves")
    game.request_rewarded_undo()
    await capture("ten_round_demo_ad")
    game._process(5.0)
    game.claim_demo_reward()
    await capture("ten_round_undo_restored")
    game.level = 10
    game.reset_board()
    for relay in game.relays:
        for turn in 4:
            var actual: Array = game.connections(relay.r, relay.shape)
            var target: Array = game.connections(relay.target, relay.shape)
            if actual[0] in target and actual[1] in target:
                break
            game.rotate_at(game.cell_center(relay.p))
    await capture("ten_round_final")
    print("VISUAL CHECK CAPTURES COMPLETE")
    quit()