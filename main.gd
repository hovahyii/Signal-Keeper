extends Node2D

const COLS := 6
const ROWS := 4
const CELL := 72.0
const ORIGIN := Vector2(24, 234)
const BG := Color("091323")
const PANEL := Color("101e33")
const GRID := Color("203653")
const CYAN := Color("55e7ff")
const AMBER := Color("ffc857")
const RED := Color("ff667d")
const LEVEL_PATHS: Array = [
    [Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1)],
    [Vector2i(0,2), Vector2i(1,2), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1)],
    [Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2), Vector2i(3,2), Vector2i(4,2), Vector2i(4,1), Vector2i(5,1)],
    [Vector2i(0,2), Vector2i(1,2), Vector2i(1,1), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1)],
    [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1), Vector2i(2,2), Vector2i(3,2), Vector2i(4,2), Vector2i(4,1), Vector2i(4,0), Vector2i(5,0)],
    [Vector2i(0,3), Vector2i(1,3), Vector2i(1,2), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(3,2), Vector2i(3,3), Vector2i(4,3), Vector2i(4,2), Vector2i(5,2)],
    [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2), Vector2i(2,2), Vector2i(2,1), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(4,1), Vector2i(4,2), Vector2i(5,2)],
    [Vector2i(0,3), Vector2i(1,3), Vector2i(1,2), Vector2i(1,1), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1), Vector2i(2,2), Vector2i(3,2), Vector2i(4,2), Vector2i(4,1), Vector2i(4,0), Vector2i(5,0)],
    [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2), Vector2i(1,3), Vector2i(2,3), Vector2i(2,2), Vector2i(2,1), Vector2i(3,1), Vector2i(3,2), Vector2i(3,3), Vector2i(4,3), Vector2i(4,2), Vector2i(4,1), Vector2i(5,1)],
    [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2), Vector2i(1,2), Vector2i(1,3), Vector2i(2,3), Vector2i(3,3), Vector2i(4,3), Vector2i(4,2), Vector2i(3,2), Vector2i(3,1), Vector2i(4,1), Vector2i(4,0), Vector2i(5,0)],
]
const LEVEL_NAMES := ["FIRST CONTACT", "UPLINK", "THE DETOUR", "HIGH GROUND", "DOUBLE BEND", "LOW FREQUENCY", "SWITCHBACK", "THE ASCENT", "FINAL APPROACH", "DEEP NETWORK"]
const MOVE_ALLOWANCES := [2, 2, 2, 1, 1, 1, 1, 0, 0, 0]
const DEMO_AD_SECONDS := 5.0
signal rewarded_ad_requested(request_id: int)
signal rewarded_ad_cancel_requested(request_id: int)
# A provider adapter must acknowledge only its SDK's earned-reward callback.
var demo_ads_enabled := OS.has_feature("demo_ads") or (OS.is_debug_build() and not OS.has_feature("android"))
var relays: Array = []
var source := Vector2i.ZERO
var receiver := Vector2i.ZERO
var par_moves := 0
var sector_stars := 0
var results: Dictionary = {}
var moves := 0
var move_limit := 0
var move_history: Array[Dictionary] = []
var ad_active := false
var ad_seconds_left := 0.0
var ad_request_serial := 0
var pending_ad_request := -1
var ad_message := ""
var ad_wait_timer := 0.0
var bgm_player: AudioStreamPlayer
var sfx_rotate_player: AudioStreamPlayer
var sfx_solved_player: AudioStreamPlayer
var level := 1
var elapsed := 0.0
var solved := false
var campaign_complete := false
var pulse := 0.0
var next_button: Button
var reset_button: Button
var undo_button: Button
var ad_claim_button: Button
var ad_cancel_button: Button
var relay_tex: Array[Texture2D] = []
var source_tex: Texture2D
var receiver_tex: Texture2D
var active_receiver_tex: Texture2D
var floor_tex: Texture2D
var hovered_cell := Vector2i(-1, -1)

func _ready() -> void:
    relay_tex = [
        load("res://pixelart/Rotatable relay sprite/relay_rotation_0.png"),
        load("res://pixelart/Rotatable relay sprite/relay_rotation_90.png"),
        load("res://pixelart/Rotatable relay sprite/relay_rotation_180.png"),
        load("res://pixelart/Rotatable relay sprite/relay_rotation_270.png")
    ]
    source_tex = load("res://pixelart/Signal source unit/source_transmitting.png")
    receiver_tex = load("res://pixelart/Receiver unit/receiver_waiting.png")
    active_receiver_tex = load("res://pixelart/Receiver unit/receiver_active.png")
    floor_tex = load("res://pixelart/Background floor tile/floor_base.png")

    # Audio setup
    bgm_player = AudioStreamPlayer.new()
    var bgm_res = load("res://audio/bgm_ambient.wav")
    if bgm_res:
        bgm_player.stream = bgm_res
        bgm_player.volume_db = -8.0
        bgm_player.finished.connect(func(): if is_instance_valid(bgm_player): bgm_player.play())
        add_child(bgm_player)
        bgm_player.play()

    sfx_rotate_player = AudioStreamPlayer.new()
    var sfx_rot = load("res://audio/sfx_rotate.wav")
    if sfx_rot:
        sfx_rotate_player.stream = sfx_rot
        sfx_rotate_player.volume_db = -3.0
        add_child(sfx_rotate_player)

    sfx_solved_player = AudioStreamPlayer.new()
    var sfx_solv = load("res://audio/sfx_solved.wav")
    if sfx_solv:
        sfx_solved_player.stream = sfx_solv
        sfx_solved_player.volume_db = -2.0
        add_child(sfx_solved_player)

    next_button = make_button(Vector2(24, 670), "NEXT SECTOR", advance_sector)
    reset_button = make_button(Vector2(24, 734), "RESTART SECTOR", reset_board)
    undo_button = make_button(Vector2(24, 670), "RESET TURNS WITH AD", request_rewarded_undo)
    ad_claim_button = make_button(Vector2(24, 448), "PLEASE WAIT", claim_demo_reward)
    ad_cancel_button = make_button(Vector2(24, 516), "CANCEL / RETURN", cancel_rewarded_ad)
    reset_board()
    if OS.has_feature("android") and not demo_ads_enabled:
        var bridge := preload("res://addons/petal_ads/petal_bridge.gd").new()
        add_child(bridge)
        bridge.attach(self)

func make_button(pos: Vector2, text: String, action: Callable) -> Button:
    var button := Button.new()
    button.position = pos
    button.size = Vector2(432, 52)
    button.text = text
    button.add_theme_font_size_override("font_size", 17)
    button.add_theme_color_override("font_color", CYAN)
    button.add_theme_stylebox_override("normal", make_box(PANEL, Color("36536e"), 2, 10))
    button.add_theme_stylebox_override("hover", make_box(Color("19334a"), CYAN, 2, 10))
    button.add_theme_stylebox_override("pressed", make_box(Color("21475d"), CYAN, 2, 10))
    button.pressed.connect(action)
    add_child(button)
    return button

func advance_sector() -> void:
    if not solved:
        return
    if campaign_complete:
        results.clear()
        level = 1
    else:
        level += 1
    reset_board()

func _process(delta: float) -> void:
    if ad_active:
        if demo_ads_enabled:
            ad_seconds_left = maxf(0.0, ad_seconds_left - delta)
            ad_claim_button.disabled = ad_seconds_left > 0.0
            ad_claim_button.text = "CLAIM REWARD" if ad_seconds_left <= 0.0 else "DEMO · %d SECONDS" % int(ceil(ad_seconds_left))
        else:
            ad_wait_timer += delta
            if ad_wait_timer > 10.0:
                ad_cancel_button.text = "CANCEL / RESUME GAME"
    if not solved and not out_of_moves() and not ad_active:
        elapsed += delta
    pulse = fmod(pulse + delta * 2.2, 1.0)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        handle_touch(event.position)
        get_viewport().set_input_as_handled()
        return
    if ad_active:
        return
    if event is InputEventMouseMotion:
        var next_hover := world_to_cell(event.position)
        if next_hover != hovered_cell:
            hovered_cell = next_hover
            queue_redraw()
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER and solved:
        advance_sector()
        return
    if event.is_action_pressed("reset"):
        reset_board()
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        rotate_at(event.position)

func handle_touch(pos: Vector2) -> void:
    var buttons: Array = [ad_claim_button, ad_cancel_button] if ad_active else [next_button, undo_button, reset_button]
    for button in buttons:
        if button.visible and button.get_rect().has_point(pos):
            if not button.disabled:
                button.pressed.emit()
            return
    if not ad_active:
        rotate_at(pos)

func out_of_moves() -> bool:
    return not solved and moves >= move_limit

func update_buttons() -> void:
    next_button.visible = solved and not ad_active
    next_button.text = "PLAY AGAIN" if campaign_complete else "NEXT SECTOR  →"
    reset_button.visible = not campaign_complete and not ad_active
    reset_button.text = "RESTART ROUND · FREE"
    undo_button.visible = not solved and not ad_active
    undo_button.disabled = moves == 0
    undo_button.text = "RESET TURNS WITH AD · DEMO" if demo_ads_enabled else "WATCH AD · RESET TURNS"
    ad_claim_button.visible = ad_active and demo_ads_enabled
    ad_claim_button.disabled = ad_seconds_left > 0.0
    ad_cancel_button.visible = ad_active
    ad_cancel_button.text = "CANCEL / RETURN TO GAME"
    queue_redraw()

func request_rewarded_undo() -> void:
    if solved or ad_active or moves == 0:
        return
    ad_request_serial += 1
    pending_ad_request = ad_request_serial
    ad_active = true
    ad_wait_timer = 0.0
    ad_seconds_left = DEMO_AD_SECONDS
    ad_message = ""
    update_buttons()
    if not demo_ads_enabled:
        if rewarded_ad_requested.get_connections().is_empty():
            rewarded_ad_failed(pending_ad_request)
        else:
            rewarded_ad_requested.emit(pending_ad_request)

func claim_demo_reward() -> void:
    if demo_ads_enabled and ad_active and ad_seconds_left <= 0.0:
        rewarded_ad_earned(pending_ad_request)

func rewarded_ad_earned(request_id: int) -> void:
    if not ad_active:
        return
    # Reset turns to 0 and unlock board, while preserving current puzzle rotations
    moves = 0
    move_history.clear()
    pending_ad_request = -1
    ad_active = false
    ad_message = "Turns reset to 0! Current puzzle preserved."
    update_buttons()
    queue_redraw()

func cancel_rewarded_ad() -> void:
    if not ad_active:
        return
    var cancelled_id := pending_ad_request
    pending_ad_request = -1
    ad_active = false
    rewarded_ad_cancel_requested.emit(cancelled_id)
    ad_message = "Ad cancelled. Puzzle unchanged."
    update_buttons()

func rewarded_ad_failed(request_id: int) -> void:
    if ad_active:
        cancel_rewarded_ad()
        ad_message = "Ad unavailable. Retry or restart for free."
        queue_redraw()

func rotate_at(pos: Vector2) -> void:
    if solved or out_of_moves() or ad_active:
        return
    var relay := relay_at(world_to_cell(pos))
    if relay.is_empty():
        return
    hovered_cell = Vector2i(-1, -1)
    move_history.append({"index": relays.find(relay), "rotation": relay.r})
    relay.r = (relay.r + 1) % 4
    moves += 1
    ad_message = ""
    if sfx_rotate_player and not sfx_rotate_player.playing:
        sfx_rotate_player.play()
    solved = is_solved()
    campaign_complete = solved and level == LEVEL_PATHS.size()
    if solved:
        if sfx_solved_player:
            sfx_solved_player.play()
        sector_stars = 3 if moves <= par_moves else (2 if moves == par_moves + 1 else 1)
        results[level] = {"stars": sector_stars, "score": maxi(100, 1000 - maxi(0, moves - par_moves) * 50)}
    update_buttons()

func reset_board() -> void:
    if ad_active:
        cancel_rewarded_ad()
    pending_ad_request = -1
    ad_active = false
    ad_message = ""
    move_history.clear()
    results.erase(level)
    sector_stars = 0
    build_sector()
    move_limit = par_moves + MOVE_ALLOWANCES[level - 1]
    moves = 0
    elapsed = 0.0
    solved = false
    campaign_complete = false
    hovered_cell = Vector2i(-1, -1)
    update_buttons()

func build_sector() -> void:
    var path: Array = LEVEL_PATHS[level - 1]
    source = path.front()
    receiver = path.back()
    relays.clear()
    par_moves = 0
    for i in range(1, path.size() - 1):
        var incoming: Vector2i = path[i - 1] - path[i]
        var outgoing: Vector2i = path[i + 1] - path[i]
        var shape := "straight" if incoming == -outgoing else "elbow"
        var target := 0
        for turn_index in 4:
            var ports := connections(turn_index, shape)
            if incoming in ports and outgoing in ports:
                target = turn_index
                break
        var turns := 1 if shape == "straight" else 1 + ((i + level) % 3)
        par_moves += turns
        relays.append({"p": path[i], "r": posmod(target - turns, 4), "shape": shape, "target": target})
    if level == 1:
        relays.append({"p": Vector2i(2,2), "r": 1, "shape": "straight"})
        relays.append({"p": Vector2i(3,2), "r": 2, "shape": "elbow"})

func total_reward(key: String) -> int:
    var total := 0
    for result in results.values():
        total += int(result[key])
    return total

func world_to_cell(pos: Vector2) -> Vector2i:
    return Vector2i(floor((pos.x - ORIGIN.x) / CELL), floor((pos.y - ORIGIN.y) / CELL))

func cell_center(cell: Vector2i) -> Vector2:
    return ORIGIN + Vector2(cell) * CELL + Vector2.ONE * CELL * 0.5

func relay_at(cell: Vector2i) -> Dictionary:
    for relay in relays:
        if relay.p == cell:
            return relay
    return {}

func connections(turn_index: int, shape: String = "straight") -> Array[Vector2i]:
    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
    if shape == "elbow":
        return [directions[turn_index % 4], directions[(turn_index + 1) % 4]]
    return [directions[(turn_index + 1) % 4], directions[(turn_index + 3) % 4]]

func is_solved() -> bool:
    return receiver in powered_cells()

func ports_at(cell: Vector2i) -> Array[Vector2i]:
    if cell == source:
        return [Vector2i.RIGHT]
    if cell == receiver:
        return [Vector2i.LEFT]
    var relay := relay_at(cell)
    return connections(relay.r, relay.shape) if not relay.is_empty() else []

func powered_cells() -> Array[Vector2i]:
    var reached: Array[Vector2i] = [source]
    var pending: Array[Vector2i] = [source]
    while not pending.is_empty():
        var cell: Vector2i = pending.pop_front()
        for direction in ports_at(cell):
            var neighbor: Vector2i = cell + direction
            if neighbor not in reached and -direction in ports_at(neighbor):
                reached.append(neighbor)
                pending.append(neighbor)
    return reached

func _draw() -> void:
    draw_rect(Rect2(0, 0, 480, 800), BG)
    draw_rect(Rect2(0, 0, 480, 136), PANEL)
    draw_string(ThemeDB.fallback_font, Vector2(24, 45), "SIGNAL KEEPER", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("e8f4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 74), "RELAY DECK  /  SECTOR %02d OF %02d" % [level, LEVEL_PATHS.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("8ca9c8"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 113), "MOVES LEFT  %02d / %02d" % [maxi(0, move_limit - moves), move_limit], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, RED if out_of_moves() else AMBER)
    draw_string(ThemeDB.fallback_font, Vector2(286, 113), "TIME  %05.1fs" % elapsed, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b9c9db"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 180), LEVEL_NAMES[level - 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8f4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 207), "Plan first. Each tap turns clockwise and costs 1 move.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("8ca9c8"))
    for y in ROWS:
        for x in COLS:
            var rect := Rect2(ORIGIN + Vector2(x, y) * CELL + Vector2(3, 3), Vector2(CELL - 6, CELL - 6))
            draw_style_box(make_box(Color("0d1a2b"), GRID, 2.0, 8.0), rect)
            if floor_tex:
                draw_texture_rect(floor_tex, Rect2(rect.position + Vector2(8, 8), Vector2(CELL - 22, CELL - 22)), false, Color(1,1,1,0.12))
    if not solved and not out_of_moves() and not relay_at(hovered_cell).is_empty():
        var hover_rect := Rect2(ORIGIN + Vector2(hovered_cell) * CELL + Vector2(6, 6), Vector2(CELL - 12, CELL - 12))
        draw_style_box(make_box(Color(0.15, 0.75, 0.88, 0.08), CYAN, 2.0, 6.0), hover_rect)
    var powered := powered_cells()
    draw_route_hint(powered)
    draw_unit(source, source_tex, CYAN, "SOURCE")
    draw_unit(receiver, active_receiver_tex if solved else receiver_tex, CYAN if solved else Color("a7b6c7"), "TARGET")
    for relay in relays:
        draw_relay(relay, relay.p in powered)
    draw_style_box(make_box(PANEL, CYAN if solved else GRID, 1, 12), Rect2(24, 550, 432, 98))
    var title := "MISSION COMPLETE" if campaign_complete else ("SECTOR COMPLETE" if solved else ("OUT OF MOVES" if out_of_moves() else "EVERY MOVE COUNTS"))
    var detail := "%d / %d STARS   •   SCORE %d" % [total_reward("stars"), LEVEL_PATHS.size() * 3, total_reward("score")] if campaign_complete else ("%d / 3 STARS   •   +%d POINTS" % [sector_stars, results[level]["score"]] if solved else ("Undo your last rotation, or restart this round." if out_of_moves() else "Connect the source to the target within the limit."))
    draw_string(ThemeDB.fallback_font, Vector2(40, 580), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, CYAN if solved else (RED if out_of_moves() else AMBER))
    draw_string(ThemeDB.fallback_font, Vector2(40, 607), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b9c9db"))
    var footer := "3 stars: %d moves  /  Round limit: %d" % [par_moves, move_limit]
    if not ad_message.is_empty():
        footer = ad_message
    if campaign_complete:
        footer = "All 10 sectors restored. Campaign complete!"
    draw_string(ThemeDB.fallback_font, Vector2(40, 633), footer, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("8ca9c8"))
    if ad_active:
        draw_rect(Rect2(0, 0, 480, 800), Color(0.02, 0.04, 0.08, 0.94))
        draw_style_box(make_box(PANEL, AMBER, 2, 14), Rect2(16, 240, 448, 350))
        draw_string(ThemeDB.fallback_font, Vector2(40, 290), "REWARDED AD · DEMO" if demo_ads_enabled else "REWARDED AD", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, AMBER)
        draw_string(ThemeDB.fallback_font, Vector2(40, 327), "Local preview. No real advertisement." if demo_ads_enabled else "Waiting for the ad provider…", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e8f4ff"))
        draw_string(ThemeDB.fallback_font, Vector2(40, 368), "Reward: reset turns to 0 (keep puzzle).", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CYAN)
        draw_string(ThemeDB.fallback_font, Vector2(40, 406), "Cancelling gives no reward.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("8ca9c8"))

func draw_route_hint(powered: Array[Vector2i]) -> void:
    for cell in powered:
        for direction in ports_at(cell):
            var neighbor: Vector2i = cell + direction
            if neighbor not in powered or -direction not in ports_at(neighbor):
                continue
            var a := cell_center(cell)
            var b := cell_center(neighbor)
            draw_line(a, b, CYAN, 4.0)
            draw_circle(a.lerp(b, pulse), 3.0, Color("dcfcff"))

func draw_unit(cell: Vector2i, tex: Texture2D, tint: Color, label: String) -> void:
    var c := cell_center(cell)
    if tex:
        draw_texture_rect(tex, Rect2(c - Vector2(27, 27), Vector2(54, 54)), false, tint)
    draw_string(ThemeDB.fallback_font, c + Vector2(-23, 31), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, tint)

func draw_relay(relay: Dictionary, active: bool) -> void:
    var c := cell_center(relay.p)
    draw_style_box(make_box(Color("12263b"), Color("36536e"), 1, 8), Rect2(c - Vector2(23,23), Vector2(46,46)))
    for bolt in [Vector2(-17,-17), Vector2(17,-17), Vector2(-17,17), Vector2(17,17)]:
        draw_circle(c + bolt, 1.5, Color("61798f"))
    var ports := connections(relay.r, relay.shape)
    var pipe_color := CYAN if active else Color("7892aa")
    for direction in ports:
        draw_line(c, c + Vector2(direction) * 30.0, Color("07121e"), 15.0)
    draw_circle(c, 7.5, Color("07121e"))
    for direction in ports:
        draw_line(c, c + Vector2(direction) * 30.0, pipe_color, 8.0)
    draw_circle(c, 4, pipe_color)
    for direction in ports:
        draw_circle(c + Vector2(direction) * 29.0, 3.0, Color("d6fbff") if active else Color("a6bbcd"))

func make_box(fill: Color, border: Color, width: float, radius: float) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(int(width))
    box.set_corner_radius_all(int(radius))
    return box
