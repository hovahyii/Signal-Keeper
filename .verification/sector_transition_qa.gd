extends SceneTree

var game: Node2D
var failures: Array[String] = []

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

func enter() -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_ENTER
    event.pressed = true
    game._unhandled_input(event)
    await process_frame

func save_frame(path: String) -> void:
    await process_frame

func solve_current(starts: Array, label: String) -> void:
    var centers := [Vector2(289, 301), Vector2(395, 301), Vector2(501, 301), Vector2(607, 301), Vector2(395, 407), Vector2(501, 407)]
    for i in centers.size():
        var turns: int = (4 - int(starts[i])) % 4
        for j in turns:
            await click(centers[i])
    check(game.solved, label + " reaches solved state")
    check(game.moves > 0, label + " records moves")
    check(game.hovered_cell == Vector2i(-1, -1), label + " has no stale hover state")
    await save_frame("D:/Signal Keeper/.verification/" + label + "_solved.png")

func run_qa() -> void:
    game = preload("res://main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    await process_frame

    var starts := [[1, 0, 3, 2, 1, 0], [2, 1, 3, 1, 2, 3], [3, 2, 1, 2, 3, 1]]
    await solve_current(starts[0], "sector1")
    await enter()
    check(game.level == 2, "1 to 2 transition changes sector")
    check(game.moves == 0 and not game.solved, "sector 2 starts with zero moves and unsolved")
    check(game.hovered_cell == Vector2i(-1, -1), "sector 2 starts without stale hover")
    await save_frame("D:/Signal Keeper/.verification/sector2_start.png")

    await solve_current(starts[1], "sector2")
    await enter()
    check(game.level == 3, "2 to 3 transition changes sector")
    check(game.moves == 0 and not game.solved, "sector 3 starts with zero moves and unsolved")
    check(game.hovered_cell == Vector2i(-1, -1), "sector 3 starts without stale hover")
    await save_frame("D:/Signal Keeper/.verification/sector3_start.png")

    await solve_current(starts[2], "sector3")
    await enter()
    check(game.level == 1, "3 to 1 transition wraps")
    check(game.moves == 0 and not game.solved, "sector 1 restart starts with zero moves and unsolved")
    check(game.hovered_cell == Vector2i(-1, -1), "sector 1 restart has no stale hover")
    await save_frame("D:/Signal Keeper/.verification/sector1_restart.png")

    if failures.is_empty():
        print("ALL CHECKS PASSED")
    else:
        print("FAILURES: ", failures.size())
    quit(1 if not failures.is_empty() else 0)
