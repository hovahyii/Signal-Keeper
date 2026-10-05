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

func click(pos: Vector2) -> void:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.button_mask = MOUSE_BUTTON_MASK_LEFT
    event.position = pos
    event.pressed = true
    game._unhandled_input(event)
    await process_frame

func key_r() -> void:
    var event := InputEventKey.new()
    event.physical_keycode = KEY_R
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame

func key_enter() -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_ENTER
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
    check(game.moves == 0, "initial moves are zero")
    check(not game.solved, "initial board is incomplete")
    await save_frame("D:/Signal Keeper/.verification/qa_initial.png")

    await click(Vector2(289, 301))
    check(game.moves == 1, "relay click increments moves")
    check(game.relays[0].r == 2, "relay rotates one quarter-turn")
    check(not game.solved, "invalid configuration remains unsolved")
    await save_frame("D:/Signal Keeper/.verification/qa_invalid.png")

    await key_r()
    check(game.moves == 0, "reset clears move counter")
    check(game.elapsed < 0.2, "reset clears elapsed time")
    check(game.relays[0].r == 1, "reset restores relay orientation")

    var centers := [Vector2(289, 301), Vector2(395, 301), Vector2(501, 301), Vector2(607, 301), Vector2(395, 407), Vector2(501, 407)]
    var rotations := [3, 0, 1, 2, 3, 0]
    for i in centers.size():
        for j in rotations[i]:
            await click(centers[i])
    check(game.moves == 9, "solution sequence counts all rotations")
    check(game.solved, "aligned relay configuration solves puzzle")
    await save_frame("D:/Signal Keeper/.verification/qa_solved.png")
    var elapsed_before: float = game.elapsed
    await process_frame
    await process_frame
    check(game.elapsed > elapsed_before, "time continues during solved animation")
    check(game.pulse >= 0.0 and game.pulse <= 1.0, "solved pulse animation is active")

    await key_enter()
    check(game.level == 2, "enter advances to the next sector")
    check(game.moves == 0 and not game.solved, "next sector starts unsolved with zero moves")
    check(game.relays[0].r == 2, "next sector loads its own relay configuration")

    await key_r()
    check(not game.solved and game.moves == 0, "reset exits solved state")
    await save_frame("D:/Signal Keeper/.verification/qa_reset.png")

    if failures.is_empty():
        print("ALL CHECKS PASSED")
    else:
        print("FAILURES: ", failures.size())
    quit(1 if not failures.is_empty() else 0)
