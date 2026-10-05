extends SceneTree

class FakePetal extends RefCounted:
    signal reward_earned(id: int)
    signal ad_cancelled(id: int)
    signal ad_failed(id: int, reason: String)
    signal ad_opened(id: int)
    var requested := -1
    var unit := ""
    var cancelled := -1
    func show_rewarded(id: int, ad_unit: String) -> void:
        requested = id
        unit = ad_unit
    func cancel_rewarded(id: int) -> void:
        cancelled = id

var failures := 0
func _initialize() -> void:
    call_deferred("run")
func check(condition: bool, label: String) -> void:
    print(("PASS: " if condition else "FAIL: ") + label)
    if not condition:
        failures += 1
func run() -> void:
    var game = load("res://main.tscn").instantiate()
    root.add_child(game)
    game.demo_ads_enabled = false
    var fake := FakePetal.new()
    var bridge = load("res://addons/petal_ads/petal_bridge.gd").new()
    game.add_child(bridge)
    bridge.attach(game, fake)
    game.rotate_at(game.cell_center(Vector2i(1,1)))
    game.request_rewarded_undo()
    check(fake.requested == game.pending_ad_request and fake.unit == "g0cz46kwsu", "native bridge uses configured live unit")
    var request_id: int = fake.requested
    fake.ad_opened.emit(request_id)
    check(not game.ad_cancel_button.visible and game.moves == 1, "opening ad does not grant reward")
    fake.ad_cancelled.emit(request_id)
    check(not game.ad_active and game.moves == 1, "closing without reward leaves move spent")
    game.request_rewarded_undo()
    request_id = fake.requested
    fake.reward_earned.emit(request_id)
    fake.reward_earned.emit(request_id)
    check(game.moves == 0 and game.move_history.is_empty(), "native reward grants exactly one undo")
    game.rotate_at(game.cell_center(Vector2i(1,1)))
    game.request_rewarded_undo()
    request_id = fake.requested
    game.reset_board()
    fake.reward_earned.emit(request_id)
    check(fake.cancelled == request_id and game.moves == 0, "restart cancels SDK request and ignores stale reward")
    game.rotate_at(game.cell_center(Vector2i(1,1)))
    game.request_rewarded_undo()
    fake.ad_failed.emit(fake.requested, "simulated no fill")
    check(game.moves == 1 and not game.ad_active and game.reset_button.visible, "no fill restores UI and free restart")
    print("ALL BRIDGE CHECKS PASSED" if failures == 0 else "BRIDGE CHECKS FAILED")
    quit(0 if failures == 0 else 1)
