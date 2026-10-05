extends SceneTree

var game: Node2D
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("run")

func check(value: bool, label: String) -> void:
    print(("PASS: " if value else "FAIL: ") + label)
    if not value:
        failures.append(label)

func tap_position(pos: Vector2) -> void:
    var event := InputEventScreenTouch.new()
    event.position = pos
    event.pressed = true
    game._unhandled_input(event)

func tap(cell: Vector2i) -> void:
    tap_position(game.cell_center(cell))

func solve_round() -> void:
    for relay in game.relays:
        if not relay.has("target"):
            continue
        for turn in 4:
            var actual: Array = game.connections(relay.r, relay.shape)
            var target: Array = game.connections(relay.target, relay.shape)
            if actual[0] in target and actual[1] in target:
                break
            tap(relay.p)

func run() -> void:
    game = load("res://main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.demo_ads_enabled = true
    check(game.LEVEL_PATHS.size() == 10, "campaign has exactly ten rounds")
    check(game.ORIGIN.x + game.COLS * game.CELL <= 480, "board fits portrait width")
    check(game.reset_button.position.y + game.reset_button.size.y <= 800, "buttons fit portrait height")
    var layouts: Array[String] = []
    for sector in range(1, 11):
        var path: Array = game.LEVEL_PATHS[sector - 1]
        var occupied: Array = []
        var valid := true
        for i in path.size():
            valid = valid and path[i] not in occupied and path[i].x >= 0 and path[i].x < 6 and path[i].y >= 0 and path[i].y < 4
            if i > 0:
                var step: Vector2i = path[i] - path[i - 1]
                valid = valid and absi(step.x) + absi(step.y) == 1
            occupied.append(path[i])
        check(valid, "round %d has a valid non-overlapping route" % sector)
        var layout := str(path)
        check(layout not in layouts, "round %d layout is unique" % sector)
        layouts.append(layout)
        check(not game.solved and not game.is_solved(), "round %d starts unsolved" % sector)
        print("ROUND %d: planned solution=%d, limit=%d" % [sector, game.par_moves, game.move_limit])
        solve_round()
        check(game.solved and game.moves <= game.move_limit, "round %d solvable within limit" % sector)
        check(game.sector_stars == 3 and game.total_reward("stars") == sector * 3, "reward accumulates once")
        check(game.move_history.size() == game.moves, "every rotation recorded")
        var frozen_time: float = game.elapsed
        var frozen_moves: int = game.moves
        game._process(1.0)
        tap(game.relays[0].p)
        check(game.elapsed == frozen_time and game.moves == frozen_moves, "solved board and timer frozen")
        if sector < 10:
            check(not game.campaign_complete, "campaign does not finish early")
            tap_position(game.next_button.get_rect().get_center())
            check(game.level == sector + 1 and game.moves == 0, "Next advances and resets budget")
    check(game.campaign_complete and game.level == 10, "round ten ends campaign")
    check(game.moves == game.move_limit and not game.out_of_moves(), "win on final allowed move takes precedence")
    check(game.total_reward("stars") == 30 and game.total_reward("score") == 10000, "perfect campaign gives 30 stars and 10000 points")
    tap_position(game.next_button.get_rect().get_center())
    check(game.level == 1 and game.results.is_empty(), "Play Again clears campaign")
    # Exhaust the budget on an irrelevant spare relay.
    tap_position(Vector2(5, 220))
    check(game.moves == 0 and game.undo_button.disabled, "empty-space tap costs nothing; no undo without history")
    for i in game.move_limit:
        tap(Vector2i(2, 2))
    check(game.out_of_moves() and not game.solved, "wasted moves lock the round")
    var exhausted_rotation: int = game.relay_at(Vector2i(2, 2)).r
    var exhausted_time: float = game.elapsed
    tap(Vector2i(2, 2))
    game._process(1.0)
    check(game.moves == game.move_limit and game.relay_at(Vector2i(2, 2)).r == exhausted_rotation and game.elapsed == exhausted_time, "zero moves blocks extra rotation and timer")
    tap_position(game.undo_button.get_rect().get_center())
    var first_request: int = game.pending_ad_request
    check(game.ad_active, "touch opens reward demo")
    tap(Vector2i(1, 1))
    game.claim_demo_reward()
    check(game.moves == game.move_limit and game.ad_active, "no early reward or board input during ad")
    tap_position(game.ad_cancel_button.get_rect().get_center())
    game.rewarded_ad_earned(first_request)
    check(not game.ad_active and game.moves == game.move_limit, "cancel and late callback grant no reward")
    tap_position(game.undo_button.get_rect().get_center())
    var request_id: int = game.pending_ad_request
    game.rewarded_ad_earned(first_request)
    check(game.ad_active and game.moves == game.move_limit, "stale callback cannot reward a new request")
    game._process(game.DEMO_AD_SECONDS)
    tap_position(game.ad_claim_button.get_rect().get_center())
    check(not game.ad_active and game.moves == game.move_limit - 1 and not game.out_of_moves(), "completed ad restores exactly one move")
    check(game.relay_at(Vector2i(2, 2)).r == posmod(exhausted_rotation - 1, 4), "undo restores exact previous orientation")
    game.rewarded_ad_earned(request_id)
    check(game.moves == game.move_limit - 1, "duplicate reward ignored")
    # Restart invalidates any outstanding reward and resets all round state.
    game.request_rewarded_undo()
    request_id = game.pending_ad_request
    game.reset_board()
    game.rewarded_ad_earned(request_id)
    check(game.moves == 0 and game.move_history.is_empty() and not game.ad_active, "restart resets budget/history and ignores old rewards")
    # Production mode never silently falls back to fake ads.
    game.demo_ads_enabled = false
    tap(Vector2i(1,1))
    game.request_rewarded_undo()
    check(not game.ad_active and game.moves == 1 and game.ad_message.contains("unavailable"), "missing real provider fails without reward")
    game.demo_ads_enabled = true
    tap_position(game.reset_button.get_rect().get_center())
    check(game.moves == 0 and game.move_history.is_empty(), "touch restart is free")
    # Two extra moves remain within the introductory limit, but lower stars.
    tap(Vector2i(2,2))
    tap(Vector2i(2,2))
    solve_round()
    check(game.solved and game.moves == game.move_limit and game.sector_stars == 1, "allowed wasted steps reduce stars")
    game.advance_sector()
    game.reset_board()
    check(game.level == 2 and game.results.has(1), "restarting round preserves earlier rewards")
    print("ALL CHECKS PASSED" if failures.is_empty() else "FAILED: %d" % failures.size())
    quit(0 if failures.is_empty() else 1)