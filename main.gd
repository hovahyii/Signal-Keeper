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
const SETTINGS_FILE := "user://settings.cfg"

enum State { MENU, GAME, SETTINGS }
enum AdPurpose { NONE, RESET_TURNS, RESTART_ROUND }

signal rewarded_ad_requested(request_id: int)
signal rewarded_ad_cancel_requested(request_id: int)

var demo_ads_enabled := OS.has_feature("demo_ads") or (OS.is_debug_build() and not OS.has_feature("android"))
var current_state: State = State.MENU
var previous_state: State = State.MENU
var ad_purpose: AdPurpose = AdPurpose.NONE

var free_restarts_left := 2
var music_volume: float = 0.8
var sfx_volume: float = 1.0

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

# Menu UI elements
var menu_play_button: Button
var menu_settings_button: Button
var menu_quit_button: Button
var menu_button: Button

# Settings UI elements
var settings_music_down: Button
var settings_music_up: Button
var settings_sfx_down: Button
var settings_sfx_up: Button
var settings_back_button: Button

# Game UI elements
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
    # MP3 loops over the full track without WAV sample loop boundaries.
    var bgm_res: AudioStreamMP3 = preload("res://audio/bgm_timelapse.mp3")
    bgm_res.loop = true
    bgm_player.stream = bgm_res
    add_child(bgm_player)

    sfx_rotate_player = AudioStreamPlayer.new()
    var sfx_rot = load("res://audio/sfx_rotate.wav")
    if sfx_rot:
        sfx_rotate_player.stream = sfx_rot
        add_child(sfx_rotate_player)

    sfx_solved_player = AudioStreamPlayer.new()
    var sfx_solv = load("res://audio/sfx_solved.wav")
    if sfx_solv:
        sfx_solved_player.stream = sfx_solv
        add_child(sfx_solved_player)

    # Load audio preferences
    load_settings()

    # Build UI buttons
    # Menu page buttons
    menu_play_button = make_button(Vector2(40, 420), "PLAY  /  RESTORE RELAYS", on_play_pressed, 400, 58)
    menu_settings_button = make_button(Vector2(40, 500), "SETTINGS  /  AUDIO", on_settings_pressed, 400, 54)
    menu_quit_button = make_button(Vector2(40, 576), "QUIT GAME", on_quit_pressed, 400, 54)

    # In-game header menu button
    menu_button = make_button(Vector2(382, 22), "MENU", on_in_game_menu_pressed, 76, 36)
    menu_button.add_theme_font_size_override("font_size", 14)

    # Settings panel buttons
    settings_music_down = make_button(Vector2(104, 308), "◀ -", on_music_vol_down, 64, 46)
    settings_music_up = make_button(Vector2(312, 308), "+ ▶", on_music_vol_up, 64, 46)
    settings_sfx_down = make_button(Vector2(104, 418), "◀ -", on_sfx_vol_down, 64, 46)
    settings_sfx_up = make_button(Vector2(312, 418), "+ ▶", on_sfx_vol_up, 64, 46)
    settings_back_button = make_button(Vector2(40, 536), "BACK  /  CLOSE", on_settings_back_pressed, 400, 54)

    # Gameplay action buttons
    next_button = make_button(Vector2(24, 670), "NEXT SECTOR", advance_sector, 432, 52)
    reset_button = make_button(Vector2(24, 734), "RESTART ROUND", on_restart_pressed, 432, 52)
    undo_button = make_button(Vector2(24, 670), "WATCH AD · RESET TURNS", request_rewarded_undo, 432, 52)
    ad_claim_button = make_button(Vector2(24, 448), "PLEASE WAIT", claim_demo_reward, 432, 52)
    ad_cancel_button = make_button(Vector2(24, 516), "CANCEL / RETURN TO GAME", cancel_rewarded_ad, 432, 52)

    reset_board()
    current_state = State.MENU
    update_buttons()

    # Start BGM
    if is_instance_valid(bgm_player):
        bgm_player.play()

    if OS.has_feature("android") and not demo_ads_enabled:
        var bridge := preload("res://addons/petal_ads/petal_bridge.gd").new()
        add_child(bridge)
        bridge.attach(self)

func make_button(pos: Vector2, text: String, action: Callable, width: float = 432.0, height: float = 52.0) -> Button:
    var button := Button.new()
    button.position = pos
    button.size = Vector2(width, height)
    button.text = text
    button.add_theme_font_size_override("font_size", 16)
    button.add_theme_color_override("font_color", CYAN)
    button.add_theme_stylebox_override("normal", make_box(PANEL, Color("36536e"), 2, 10))
    button.add_theme_stylebox_override("hover", make_box(Color("19334a"), CYAN, 2, 10))
    button.add_theme_stylebox_override("pressed", make_box(Color("21475d"), CYAN, 2, 10))
    button.add_theme_stylebox_override("disabled", make_box(Color("0a1420"), Color("1e2f42"), 1, 10))
    button.pressed.connect(action)
    add_child(button)
    return button

# --- Settings & Audio Management ---

func set_music_volume(pct: float) -> void:
    music_volume = clampf(pct, 0.0, 1.0)
    if is_instance_valid(bgm_player):
        if music_volume <= 0.01:
            bgm_player.volume_db = -80.0
        else:
            bgm_player.volume_db = linear_to_db(music_volume) + 3.0
    save_settings()

func set_sfx_volume(pct: float) -> void:
    sfx_volume = clampf(pct, 0.0, 1.0)
    var db := -80.0 if sfx_volume <= 0.01 else linear_to_db(sfx_volume)
    if is_instance_valid(sfx_rotate_player):
        sfx_rotate_player.volume_db = db
    if is_instance_valid(sfx_solved_player):
        sfx_solved_player.volume_db = db
    save_settings()

func save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "music_volume", music_volume)
    cfg.set_value("audio", "sfx_volume", sfx_volume)
    cfg.save(SETTINGS_FILE)

func load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SETTINGS_FILE) == OK:
        music_volume = cfg.get_value("audio", "music_volume", 0.8)
        sfx_volume = cfg.get_value("audio", "sfx_volume", 1.0)
    else:
        music_volume = 0.8
        sfx_volume = 1.0
    set_music_volume(music_volume)
    set_sfx_volume(sfx_volume)

func play_sfx(player: AudioStreamPlayer) -> void:
    if is_instance_valid(player) and sfx_volume > 0.01:
        player.play()

func on_music_vol_down() -> void:
    set_music_volume(music_volume - 0.1)
    queue_redraw()

func on_music_vol_up() -> void:
    set_music_volume(music_volume + 0.1)
    queue_redraw()

func on_sfx_vol_down() -> void:
    set_sfx_volume(sfx_volume - 0.1)
    play_sfx(sfx_rotate_player)
    queue_redraw()

func on_sfx_vol_up() -> void:
    set_sfx_volume(sfx_volume + 0.1)
    play_sfx(sfx_rotate_player)
    queue_redraw()

# --- State Navigation Handlers ---

func on_play_pressed() -> void:
    current_state = State.GAME
    update_buttons()
    queue_redraw()
    if is_instance_valid(bgm_player) and not bgm_player.playing:
        bgm_player.play()

func on_settings_pressed() -> void:
    previous_state = current_state
    current_state = State.SETTINGS
    update_buttons()
    queue_redraw()

func on_settings_back_pressed() -> void:
    current_state = previous_state
    update_buttons()
    queue_redraw()

func on_quit_pressed() -> void:
    get_tree().quit()

func on_in_game_menu_pressed() -> void:
    current_state = State.MENU
    update_buttons()
    queue_redraw()

# --- Gameplay Sector & Round Control ---

func advance_sector() -> void:
    if not solved:
        return
    if campaign_complete:
        results.clear()
        level = 1
    else:
        level += 1
    free_restarts_left = 2
    reset_board()

func on_restart_pressed() -> void:
    if free_restarts_left > 0:
        free_restarts_left -= 1
        reset_board()
    else:
        request_rewarded_restart()

func reset_board() -> void:
    var path: Array = LEVEL_PATHS[level - 1]
    source = path[0]
    receiver = path[-1]
    par_moves = 0
    build_level_relays(path)
    move_limit = par_moves + MOVE_ALLOWANCES[level - 1]
    moves = 0
    move_history.clear()
    elapsed = 0.0
    solved = false
    ad_message = ""
    update_buttons()

func _process(delta: float) -> void:
    if ad_active:
        if demo_ads_enabled:
            ad_seconds_left = maxf(0.0, ad_seconds_left - delta)
            ad_claim_button.disabled = ad_seconds_left > 0.0
            ad_claim_button.text = "CLAIM REWARD" if ad_seconds_left <= 0.0 else "DEMO · %d SECONDS" % int(ceil(ad_seconds_left))
        else:
            ad_wait_timer += delta
            # If native ad has been loading for more than 4 seconds without opening, offer backup demo
            if ad_wait_timer > 4.0 and not demo_ads_enabled:
                demo_ads_enabled = true
                ad_seconds_left = DEMO_AD_SECONDS
                update_buttons()
    if is_instance_valid(bgm_player) and not bgm_player.playing and music_volume > 0.01:
        bgm_player.play()
    if current_state == State.GAME and not solved and not out_of_moves() and not ad_active:
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
    if current_state == State.GAME:
        if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER and solved:
            advance_sector()
            return
        if event.is_action_pressed("reset"):
            on_restart_pressed()
            return
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            rotate_at(event.position)

func handle_touch(pos: Vector2) -> void:
    # Ensure BGM starts upon interaction
    if is_instance_valid(bgm_player) and not bgm_player.playing and music_volume > 0.01:
        bgm_player.play()

    var buttons: Array = []
    if current_state == State.MENU:
        buttons = [menu_play_button, menu_settings_button, menu_quit_button]
    elif current_state == State.SETTINGS:
        buttons = [settings_music_down, settings_music_up, settings_sfx_down, settings_sfx_up, settings_back_button]
    elif current_state == State.GAME:
        if ad_active:
            buttons = [ad_claim_button, ad_cancel_button]
        else:
            buttons = [menu_button, next_button, undo_button, reset_button]

    for button in buttons:
        if button.visible and button.get_rect().has_point(pos):
            if not button.disabled:
                button.pressed.emit()
            return

    if current_state == State.GAME and not ad_active:
        rotate_at(pos)

func out_of_moves() -> bool:
    return not solved and moves >= move_limit

func update_buttons() -> void:
    # Menu page buttons
    menu_play_button.visible = (current_state == State.MENU)
    menu_settings_button.visible = (current_state == State.MENU)
    menu_quit_button.visible = (current_state == State.MENU)

    # Settings page buttons
    settings_music_down.visible = (current_state == State.SETTINGS)
    settings_music_up.visible = (current_state == State.SETTINGS)
    settings_sfx_down.visible = (current_state == State.SETTINGS)
    settings_sfx_up.visible = (current_state == State.SETTINGS)
    settings_back_button.visible = (current_state == State.SETTINGS)

    # In-game buttons
    var in_game := (current_state == State.GAME)
    menu_button.visible = in_game and not ad_active

    next_button.visible = in_game and solved and not ad_active
    next_button.text = "PLAY AGAIN" if campaign_complete else "NEXT SECTOR  →"

    reset_button.visible = in_game and not campaign_complete and not ad_active
    if free_restarts_left > 0:
        reset_button.text = "RESTART ROUND (%d FREE LEFT)" % free_restarts_left
    else:
        reset_button.text = "WATCH AD TO RESTART ROUND"

    undo_button.visible = in_game and not solved and not ad_active
    undo_button.disabled = (moves == 0)
    undo_button.text = "WATCH AD · RESET TURNS"

    # Ad overlay buttons
    ad_claim_button.visible = in_game and ad_active and demo_ads_enabled
    ad_claim_button.disabled = (ad_seconds_left > 0.0)
    ad_cancel_button.visible = in_game and ad_active
    ad_cancel_button.text = "CANCEL / RETURN TO GAME"
    queue_redraw()

# --- Rewarded Ads Logic (Turn Reset & Round Restart) ---

func request_rewarded_restart() -> void:
    if ad_active:
        return
    ad_purpose = AdPurpose.RESTART_ROUND
    start_ad_request()

func request_rewarded_undo() -> void:
    if solved or ad_active or moves == 0:
        return
    ad_purpose = AdPurpose.RESET_TURNS
    start_ad_request()

func start_ad_request() -> void:
    ad_request_serial += 1
    pending_ad_request = ad_request_serial
    ad_active = true
    ad_wait_timer = 0.0
    ad_seconds_left = DEMO_AD_SECONDS
    ad_message = ""
    update_buttons()
    if not demo_ads_enabled:
        if rewarded_ad_requested.get_connections().is_empty():
            demo_ads_enabled = true
        else:
            rewarded_ad_requested.emit(pending_ad_request)

func claim_demo_reward() -> void:
    if demo_ads_enabled and ad_active and ad_seconds_left <= 0.0:
        rewarded_ad_earned(pending_ad_request)

func rewarded_ad_earned(request_id: int) -> void:
    if not ad_active:
        return
    ad_active = false
    pending_ad_request = -1
    if ad_purpose == AdPurpose.RESTART_ROUND:
        free_restarts_left = 2
        moves = 0
        reset_board()
        ad_message = "Round restarted! 2 free restarts granted."
    else:
        # Reset turns to 0 and unlock board, preserving current rotated nodes
        moves = 0
        move_history.clear()
        ad_message = "Turns reset to 0! Current puzzle preserved."
    ad_purpose = AdPurpose.NONE
    update_buttons()
    queue_redraw()

func cancel_rewarded_ad() -> void:
    if not ad_active:
        return
    var cancelled_id := pending_ad_request
    pending_ad_request = -1
    ad_active = false
    ad_purpose = AdPurpose.NONE
    rewarded_ad_cancel_requested.emit(cancelled_id)
    ad_message = "Ad cancelled. Puzzle unchanged."
    update_buttons()

func rewarded_ad_failed(request_id: int) -> void:
    if ad_active:
        # Fallback to local in-game demo reward so user is never blocked
        demo_ads_enabled = true
        ad_seconds_left = DEMO_AD_SECONDS
        ad_message = "Loading backup ad stream..."
        update_buttons()
        queue_redraw()

# --- Puzzle Manipulation & Rotation ---

func rotate_at(pos: Vector2) -> void:
    if solved or out_of_moves() or ad_active:
        return
    var cell := world_to_cell(pos)
    var relay := relay_at(cell)
    if relay.is_empty():
        return
    var before: int = relay.r
    relay.r = posmod(relay.r + 1, 4)
    moves += 1
    move_history.append({"cell": cell, "from": before, "to": relay.r})
    play_sfx(sfx_rotate_player)
    if is_solved():
        solved = true
        var score: int = max(100, 1000 - moves * 65 - int(elapsed * 12.0))
        var stars: int = 3 if moves <= par_moves else (2 if moves <= par_moves + 2 else 1)
        sector_stars = stars
        results[level] = {"stars": stars, "score": score, "time": elapsed, "moves": moves}
        campaign_complete = results.size() >= LEVEL_PATHS.size()
        play_sfx(sfx_solved_player)
    update_buttons()
    queue_redraw()

func build_level_relays(path: Array) -> void:
    relays.clear()
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

# --- Rendering ---

func _draw() -> void:
    draw_rect(Rect2(0, 0, 480, 800), BG)
    
    if current_state == State.MENU:
        draw_menu_screen()
    elif current_state == State.SETTINGS:
        draw_settings_screen()
    else:
        draw_game_screen()

func draw_menu_screen() -> void:
    # Decorative grid lines
    for x in range(20, 480, 40):
        draw_line(Vector2(x, 0), Vector2(x, 800), Color(0.12, 0.22, 0.35, 0.25), 1.0)
    for y in range(20, 800, 40):
        draw_line(Vector2(0, y), Vector2(480, y), Color(0.12, 0.22, 0.35, 0.25), 1.0)

    # Top Brand / Header Panel
    draw_style_box(make_box(PANEL, CYAN, 2.0, 16.0), Rect2(28, 48, 424, 150))
    if source_tex:
        draw_texture_rect(source_tex, Rect2(48, 80, 56, 56), false, CYAN)
    draw_string(ThemeDB.fallback_font, Vector2(118, 92), "SIGNAL KEEPER", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("e8f4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(118, 118), "RELAY LOGIC & TRANSMISSION GRID", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CYAN)
    draw_string(ThemeDB.fallback_font, Vector2(118, 140), "Restore the damaged industrial relay network", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("8ca9c8"))

    # Active Progress Card
    draw_style_box(make_box(Color("0c1a2d"), GRID, 1.5, 12.0), Rect2(40, 222, 400, 168))
    draw_string(ThemeDB.fallback_font, Vector2(56, 252), "TRANSMISSION SECTOR STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, AMBER)
    draw_line(Vector2(56, 262), Vector2(424, 262), Color(0.2, 0.35, 0.5, 0.4), 1.0)
    
    var sector_title := "SECTOR %02d: %s" % [level, LEVEL_NAMES[level - 1]]
    draw_string(ThemeDB.fallback_font, Vector2(56, 292), sector_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e8f4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(56, 320), "CAMPAIGN STARS:  %d / %d" % [total_reward("stars"), LEVEL_PATHS.size() * 3], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CYAN)
    draw_string(ThemeDB.fallback_font, Vector2(56, 346), "RESTORATION SCORE:  %d PTS" % total_reward("score"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b9c9db"))
    draw_string(ThemeDB.fallback_font, Vector2(56, 372), "FREE RESTARTS:  %d CHANCES REMAINING" % free_restarts_left, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, AMBER)

    # Footer note
    draw_string(ThemeDB.fallback_font, Vector2(24, 690), "HUAWEI PETAL ADS REWARD INTEGRATED", HORIZONTAL_ALIGNMENT_CENTER, 432, 12, Color("6e8ca8"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 712), "com.hovahdigitalsolutions.signalkeeper · v0.3.0", HORIZONTAL_ALIGNMENT_CENTER, 432, 12, Color("526d85"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 734), "https://signal-keeper.hovahdigitalsolutions.com", HORIZONTAL_ALIGNMENT_CENTER, 432, 12, Color("3d556e"))

func draw_settings_screen() -> void:
    # Backdrop
    draw_rect(Rect2(0, 0, 480, 800), BG)
    draw_style_box(make_box(PANEL, CYAN, 2.0, 16.0), Rect2(24, 48, 432, 704))

    # Header
    draw_string(ThemeDB.fallback_font, Vector2(48, 96), "SYSTEM SETTINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("e8f4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(48, 124), "AUDIO & TRANSMISSION CONFIGURATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CYAN)
    draw_line(Vector2(48, 140), Vector2(432, 140), Color(0.2, 0.4, 0.6, 0.5), 1.0)

    # Music Volume Box
    draw_style_box(make_box(Color("0c1a2d"), GRID, 1.5, 12.0), Rect2(40, 170, 400, 196))
    draw_string(ThemeDB.fallback_font, Vector2(56, 204), "BACKGROUND MUSIC (BGM)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AMBER)
    draw_string(ThemeDB.fallback_font, Vector2(56, 230), "Ambient cyberpunk synth transmission track.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("8ca9c8"))
    
    # Music Volume Meter
    var music_pct := int(round(music_volume * 100))
    draw_style_box(make_box(Color("08121f"), Color("203653"), 1.0, 6.0), Rect2(178, 308, 124, 46))
    var music_color := CYAN if music_pct > 0 else RED
    draw_string(ThemeDB.fallback_font, Vector2(178, 337), "%d%%" % music_pct if music_pct > 0 else "MUTED", HORIZONTAL_ALIGNMENT_CENTER, 124, 18, music_color)
    draw_string(ThemeDB.fallback_font, Vector2(56, 276), "VOLUME: %d%%" % music_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8f4ff"))

    # SFX Volume Box
    draw_style_box(make_box(Color("0c1a2d"), GRID, 1.5, 12.0), Rect2(40, 380, 400, 136))
    draw_string(ThemeDB.fallback_font, Vector2(56, 408), "SOUND EFFECTS (SFX)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AMBER)
    
    var sfx_pct := int(round(sfx_volume * 100))
    draw_style_box(make_box(Color("08121f"), Color("203653"), 1.0, 6.0), Rect2(178, 418, 124, 46))
    var sfx_color := CYAN if sfx_pct > 0 else RED
    draw_string(ThemeDB.fallback_font, Vector2(178, 447), "%d%%" % sfx_pct if sfx_pct > 0 else "MUTED", HORIZONTAL_ALIGNMENT_CENTER, 124, 18, sfx_color)
    draw_string(ThemeDB.fallback_font, Vector2(56, 434), "VOLUME: %d%%" % sfx_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8f4ff"))

    # Bottom notes
    draw_string(ThemeDB.fallback_font, Vector2(40, 630), "Settings are automatically saved to your device.", HORIZONTAL_ALIGNMENT_CENTER, 400, 13, Color("8ca9c8"))

func draw_game_screen() -> void:
    draw_rect(Rect2(0, 0, 480, 136), PANEL)
    draw_string(ThemeDB.fallback_font, Vector2(24, 45), "SIGNAL KEEPER", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("e8f4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 74), "RELAY DECK  /  SECTOR %02d OF %02d" % [level, LEVEL_PATHS.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("8ca9c8"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 113), "MOVES LEFT  %02d / %02d" % [maxi(0, move_limit - moves), move_limit], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, RED if out_of_moves() else AMBER)
    draw_string(ThemeDB.fallback_font, Vector2(240, 113), "TIME  %05.1fs" % elapsed, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b9c9db"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 180), LEVEL_NAMES[level - 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8f4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 207), "Tap relays to rotate clockwise. Connect source to receiver.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("8ca9c8"))

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
    var detail := "%d / %d STARS   •   SCORE %d" % [total_reward("stars"), LEVEL_PATHS.size() * 3, total_reward("score")] if campaign_complete else ("%d / 3 STARS   •   +%d POINTS" % [sector_stars, results[level]["score"]] if solved else ("Undo turns or restart round with ad." if out_of_moves() else "Connect the source to the target within the limit."))
    draw_string(ThemeDB.fallback_font, Vector2(40, 580), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, CYAN if solved else (RED if out_of_moves() else AMBER))
    draw_string(ThemeDB.fallback_font, Vector2(40, 607), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b9c9db"))
    
    var footer := "Free restarts left: %d  /  Round limit: %d moves" % [free_restarts_left, move_limit]
    if not ad_message.is_empty():
        footer = ad_message
    if campaign_complete:
        footer = "All 10 sectors restored. Campaign complete!"
    draw_string(ThemeDB.fallback_font, Vector2(40, 633), footer, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("8ca9c8"))

    if ad_active:
        draw_rect(Rect2(0, 0, 480, 800), Color(0.02, 0.04, 0.08, 0.94))
        draw_style_box(make_box(PANEL, AMBER, 2, 14), Rect2(16, 240, 448, 350))
        draw_string(ThemeDB.fallback_font, Vector2(40, 290), "REWARDED AD · DEMO" if demo_ads_enabled else "REWARDED AD", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, AMBER)
        draw_string(ThemeDB.fallback_font, Vector2(40, 327), "Local preview countdown in progress." if demo_ads_enabled else "Connecting to Huawei Petal Ads…", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e8f4ff"))
        
        var purpose_reward := "Reward: Reset turns to 0 (keep puzzle)." if ad_purpose == AdPurpose.RESET_TURNS else "Reward: Restart sector & restore 2 free restarts."
        draw_string(ThemeDB.fallback_font, Vector2(40, 368), purpose_reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CYAN)
        draw_string(ThemeDB.fallback_font, Vector2(40, 406), "Cancelling returns to game without reward.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("8ca9c8"))

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
