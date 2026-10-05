extends Node
## Runtime adapter. Android never falls back to a simulated reward.
const LIVE_UNIT := "g0cz46kwsu"
const TEST_UNIT := "g0cz46kwsu"
var game: Node
var native: Object

func attach(target: Node, provider: Object = null) -> void:
    game = target
    native = provider
    if native == null and Engine.has_singleton("PetalAds"):
        native = Engine.get_singleton("PetalAds")
    game.rewarded_ad_requested.connect(_request)
    game.rewarded_ad_cancel_requested.connect(_cancel)
    if native != null:
        native.connect("reward_earned", _earned)
        native.connect("ad_cancelled", _cancelled)
        native.connect("ad_failed", _failed)
        native.connect("ad_opened", _opened)

func _request(request_id: int) -> void:
    if native == null:
        game.rewarded_ad_failed(request_id)
        return
    native.show_rewarded(request_id, TEST_UNIT if OS.has_feature("petal_test_ads") else LIVE_UNIT)

func _cancel(request_id: int) -> void:
    if native != null:
        native.cancel_rewarded(request_id)

func _earned(request_id: int) -> void:
    if game.ad_active:
        game.rewarded_ad_earned(request_id)

func _cancelled(request_id: int) -> void:
    if game.ad_active:
        game.cancel_rewarded_ad()

func _failed(request_id: int, error: String) -> void:
    push_warning("Petal rewarded ad: " + error)
    if game.ad_active:
        game.rewarded_ad_failed(request_id)

func _opened(request_id: int) -> void:
    # Ensure UI state remains responsive when ad opens
    pass
