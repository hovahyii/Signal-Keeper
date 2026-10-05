extends SceneTree

var game: Node2D
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("run_qa")

func check(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)
        print("FAIL: ", label)
    else:
        print("PASS: ", label)

func mouse_motion(pos: Vector2) -> void:
    var event := InputEventMouseMotion.new()
    event.position = pos
    event.global_position = pos
    game._unhandled_input(event)
    await process_frame

func tap(pos: Vector2) -> void:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.button_mask = MOUSE_BUTTON_MASK_LEFT
    event.position = pos
    event.pressed = true
    game._unhandled_input(event)
    await process_frame

func save_frame(path: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_viewport().get_texture().get_image().save_png(path)

func run_qa() -> void:
    game = preload("res://main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    await save_frame("D:/Signal Keeper/.verification/hover_initial.png")

    await mouse_motion(Vector2(289, 301))
    check(game.hovered_cell == Vector2i(1, 1), "relay hover targets the relay cell")
    await save_frame("D:/Signal Keeper/.verification/hover_relay.png")

    await mouse_motion(Vector2(183, 195))
    check(game.hovered_cell == Vector2i(0, 0), "moving to a non-relay tile removes relay hover target")
    await save_frame("D:/Signal Keeper/.verification/hover_background.png")

    var relay_cells := [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(2, 2), Vector2i(3, 2)]
    var every_tile_clear := true
    for y in 4:
        for x in 6:
            var cell := Vector2i(x, y)
            await mouse_motion(game.cell_center(cell))
            var should_target: bool = not game.relay_at(cell).is_empty()
            var actual_target: bool = not game.relay_at(game.hovered_cell).is_empty()
            if actual_target != should_target:
                every_tile_clear = false
    check(every_tile_clear, "all 24 tiles distinguish relay targets from background tiles")

    await mouse_motion(Vector2(289, 301))
    await tap(Vector2(289, 301))
    check(game.moves == 1, "tap still rotates the relay")
    check(game.hovered_cell == Vector2i(-1, -1), "tap clears hover styling instead of leaving a stuck state")
    await save_frame("D:/Signal Keeper/.verification/hover_after_tap.png")

    if failures.is_empty():
        print("ALL CHECKS PASSED")
    else:
        print("FAILURES: ", failures.size())
    quit(1 if not failures.is_empty() else 0)
