extends CanvasLayer
class_name InventoryUI

@onready var items_vbox = $Control/MarginContainer/VBoxContainer
@onready var lock_vbox = $lock/VBoxContainer
@onready var orders_hbox = $OrdersHBox
@onready var score_label: Label = $ScoreLabel
@onready var wave_target_label: Label = $WaveTargetLabel
@onready var game_timer_label: Label = $GameTimerLabel
@onready var hearts_container: HBoxContainer = $HeartsContainer
@onready var hud_backdrop: Panel = $HudBackdrop
@onready var damage_flash_overlay: ColorRect = $DamageFlashOverlay
@onready var wave_popup: WavePopup = $WavePopup
@onready var game_over_popup: GameOverPopup = $GameOverPopup
@onready var clovis_popup_panel: Panel = $ClovisPopup
@onready var clovis_popup_label: Label = $ClovisPopup/Label

var slot_scene = preload("res://GUI/inventory/invetory_slot.tscn")
var lock_scene = preload("res://GUI/inventory/lock.tscn")
var order_card_scene = preload("res://order/ordercard.tscn")
const SCORE_BASE: float = 100.0

const RED_PILL_ICON: Texture2D = preload("res://GUI/inventory/items/real_red_pill.png")
const BLUE_PILL_ICON: Texture2D = preload("res://GUI/inventory/items/real_blue_pill.png")
const GREEN_PILL_ICON: Texture2D = preload("res://GUI/inventory/items/real_green_pill.png")
const PURPLE_PILL_ICON: Texture2D = preload("res://GUI/inventory/items/real_purple_pill.png")
const RED_INJECTION_ICON: Texture2D = preload("res://GUI/inventory/items/red_injection.png")
const BLUE_INJECTION_ICON: Texture2D = preload("res://GUI/inventory/items/blue_injection.png")
const GREEN_INJECTION_ICON: Texture2D = preload("res://GUI/inventory/items/green_injection.png")
const PURPLE_INJECTION_ICON: Texture2D = preload("res://GUI/inventory/items/purple_injection.png")
const CLOVIS_ICON: Texture2D = preload("res://GUI/interactable/box/exclamation.png")
const ORDER_FACE_ICON: Texture2D = preload("res://order/backcard.png")
const HEART_ICON: Texture2D = preload("res://GUI/heart.png")
const HIT_HURT_SFX: AudioStream = preload("res://GUI/hitHurt.wav")
const ORDER_FINISH_SFX: AudioStream = preload("res://GUI/order_finish.wav")
const CLOVIS_STREAK_TARGET: int = 20

@export var score_particles_offset: Vector2 = Vector2.ZERO
@export var hud_backdrop_color: Color = Color(0.0, 0.0, 0.0, 0.3)
@export var hud_backdrop_border_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var damage_flash_color: Color = Color(1.0, 0.0, 0.0, 0.45)
@export var damage_flash_in_duration: float = 0.05
@export var damage_flash_out_duration: float = 0.16

var items: Array = []          # stores slot nodes
var lock_nodes: Array = []
var active_orders: Array[OrderCard] = []

var order_spawn_elapsed: float = 0.0
var current_wave: int = 1
var current_wave_target_score: float = 0.0
var game_time_left: float = 0.0
var wave_popup_open: bool = false
var game_ended: bool = false
var cured_patients: int = 0
var total_time_used_ratio: float = 0.0
var score_label_tween: Tween
var score_color_tween: Tween
var score_particles: GPUParticles2D
var hurt_sfx_player: AudioStreamPlayer
var order_finish_sfx_player: AudioStreamPlayer
var clovis_submit_streak: int = 0
var clovis_popup_tween: Tween
var damage_flash_tween: Tween


func _ready():
	randomize()
	Global.score = 0.0
	current_wave = 1
	current_wave_target_score = Global.wave_target_base_score
	game_time_left = Global.game_time_limit
	wave_popup_open = false
	game_ended = false
	cured_patients = 0
	total_time_used_ratio = 0.0
	clovis_submit_streak = 0
	clovis_popup_panel.visible = false
	clovis_popup_label.text = "Hi I'm Clovis"
	damage_flash_overlay.color = Color(damage_flash_color.r, damage_flash_color.g, damage_flash_color.b, 0.0)

	if not wave_popup.buff_chosen.is_connected(_on_wave_buff_chosen):
		wave_popup.buff_chosen.connect(_on_wave_buff_chosen)
	if not Global.lives_changed.is_connected(_on_lives_changed):
		Global.lives_changed.connect(_on_lives_changed)
	_setup_score_feedback_fx()
	_setup_hurt_sfx()
	_setup_order_finish_sfx()
	_apply_hud_backdrop_style()

	Global.reset_lives()
	_update_score_label()
	_update_lives_display()
	_update_wave_target_label()
	_update_game_timer_label()
	update_locks()
	Global.inventory_upgraded.connect(update_locks)
	_try_spawn_order()


func _process(delta: float) -> void:
	if game_ended:
		return

	game_time_left -= delta
	_update_game_timer_label()

	if game_time_left <= 0.0:
		game_time_left = 0.0
		_update_game_timer_label()
		print("Game over reason: session timer reached 0.")
		_end_game()
		return

	if wave_popup_open:
		wave_popup.update_timer_label(game_time_left)
		return

	if Global.score >= current_wave_target_score:
		_show_wave_popup()
		return

	order_spawn_elapsed += delta
	if order_spawn_elapsed >= Global.order_spawn_interval:
		order_spawn_elapsed = 0.0
		_try_spawn_order()


# ---------------------------
# ADD ITEM (ENUM BASED)
# ---------------------------
func add_item(item_type: ItemTypes.ItemType):

	if items.size() >= Global.unlocked_inventory_slots:
		print(items.size())
		print(Global.unlocked_inventory_slots)
		print("Inventory full")
		return

	var slot = slot_scene.instantiate()

	items_vbox.add_child(slot)      # 🔥 ADD FIRST
	items_vbox.move_child(slot, 0)

	slot.set_item(item_type)        # 🔥 THEN SET

	items.insert(0, slot)


# ---------------------------
# USE ITEM (SEND TO ORDER)
# ---------------------------
func use_item():

	if items.is_empty():
		return

	var slot = items[0]
	var item_type = slot.item_type

	# find station automatically
	var station = get_tree().get_first_node_in_group("patient_station")

	if station == null:
		return

	var success = station.submit_item(item_type)

	if success:
		slot.queue_free()
		items.remove_at(0)
		_track_clovis_submission(item_type)


func submit_top_item_to_order(order_card: OrderCard) -> bool:
	if items.is_empty():
		return false

	var slot = items[0]
	var success: bool = false

	if order_card != null:
		success = order_card.submit_item(slot.item_type)

	# Submit station should consume one item per interaction.
	var submitted_item_type: ItemTypes.ItemType = slot.item_type
	slot.queue_free()
	items.remove_at(0)
	_track_clovis_submission(submitted_item_type)

	return success


func submit_top_item_to_orders() -> bool:
	if game_ended or wave_popup_open:
		return false

	if items.is_empty():
		return false

	var slot = items[0]
	var item_type: ItemTypes.ItemType = slot.item_type
	var success: bool = false

	for order in active_orders:
		if not is_instance_valid(order):
			continue
		if not order.is_active():
			continue
		if order.peek_expected_item() != item_type:
			continue

		success = order.submit_item(item_type)
		if success:
			break

	# Submit station should consume one item per interaction.
	slot.queue_free()
	items.remove_at(0)
	_track_clovis_submission(item_type)

	return success


func spawn_debug_order(sequence: Array[ItemTypes.ItemType], time_limit: float = -1.0) -> bool:
	if game_ended:
		return false

	if active_orders.size() >= Global.max_active_orders:
		return false

	if sequence.is_empty():
		return false

	var duration: float = Global.order_time_limit if time_limit <= 0 else time_limit
	_create_order(sequence, duration)
	return true


func _try_spawn_order() -> void:
	if active_orders.size() >= Global.max_active_orders:
		return

	var order_pool: Array[ItemTypes.ItemType] = []
	for item in Global.allowed_order_items:
		if item == ItemTypes.ItemType.CLOVIS:
			continue
		order_pool.append(item)

	if order_pool.is_empty():
		return

	var count: int = randi_range(Global.order_length_min, Global.order_length_max)
	count = min(count, 6) # scene has six slot icons
	count = max(count, 1)

	var sequence: Array[ItemTypes.ItemType] = []
	for i in range(count):
		sequence.append(order_pool.pick_random())

	_create_order(sequence, Global.order_time_limit)


func _create_order(sequence: Array[ItemTypes.ItemType], time_limit: float) -> void:
	var order: OrderCard = order_card_scene.instantiate()
	_configure_order_visuals(order)

	orders_hbox.add_child(order)
	active_orders.append(order)

	order.completed.connect(_on_order_completed.bind(order))
	order.timed_out.connect(_on_order_timed_out.bind(order))
	order.failed.connect(_on_order_failed.bind(order))

	order.setup(sequence, time_limit)


func _configure_order_visuals(order: OrderCard) -> void:
	order.custom_minimum_size = Vector2(230, 120)

	order.red_icon = RED_PILL_ICON
	order.blue_icon = BLUE_PILL_ICON
	order.green_icon = GREEN_PILL_ICON
	order.purple_icon = PURPLE_PILL_ICON
	order.red_injection_icon = RED_INJECTION_ICON
	order.blue_injection_icon = BLUE_INJECTION_ICON
	order.green_injection_icon = GREEN_INJECTION_ICON
	order.purple_injection_icon = PURPLE_INJECTION_ICON
	order.clovis_icon = CLOVIS_ICON

	order.face_normal = ORDER_FACE_ICON
	order.face_sick = ORDER_FACE_ICON
	order.face_sad = ORDER_FACE_ICON


func _on_order_completed(order: OrderCard) -> void:
	var time_left: float = order.get_time_left()
	var item_count: int = order.get_required_count()
	var duration: float = order.get_duration()
	var time_left_ratio: float = (time_left / duration)
	total_time_used_ratio += clamp(time_left_ratio, 0.0, 1.0)
	cured_patients += 1

	var added_score: float = SCORE_BASE * time_left * float(item_count)
	Global.score += added_score
	_update_score_label()
	_play_score_gain_effect()
	_play_order_finish_sfx()

	print("Order completed successfully.")
	print(
		"Score formula: ", SCORE_BASE, " * ", time_left, " * ", item_count,
		" = ", added_score
	)
	print("Score added: ", added_score, " | Total score: ", Global.score)
	_remove_order(order)


func _on_order_timed_out(order: OrderCard) -> void:
	_remove_order(order)
	_lose_life_and_check_end()


func _on_order_failed(order: OrderCard) -> void:
	_remove_order(order)
	print("Order failed.")


func _remove_order(order: OrderCard) -> void:
	if active_orders.has(order):
		active_orders.erase(order)

	if is_instance_valid(order):
		order.queue_free()


func _track_clovis_submission(item_type: ItemTypes.ItemType) -> void:
	if item_type == ItemTypes.ItemType.CLOVIS:
		clovis_submit_streak += 1
		if clovis_submit_streak >= CLOVIS_STREAK_TARGET:
			clovis_submit_streak = 0
			_show_clovis_popup()
		return

	clovis_submit_streak = 0


func _show_clovis_popup() -> void:
	if clovis_popup_tween and clovis_popup_tween.is_running():
		clovis_popup_tween.kill()

	clovis_popup_panel.visible = true
	clovis_popup_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	clovis_popup_label.text = "Hi I'm Clovis"

	clovis_popup_tween = create_tween()
	clovis_popup_tween.tween_property(clovis_popup_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.14)
	clovis_popup_tween.tween_interval(1.8)
	clovis_popup_tween.tween_property(clovis_popup_panel, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.2)
	clovis_popup_tween.tween_callback(Callable(self, "_hide_clovis_popup"))


func _hide_clovis_popup() -> void:
	clovis_popup_panel.visible = false


func _update_score_label() -> void:
	score_label.text = "Score: %.1f" % Global.score
	score_label.pivot_offset = score_label.size * 0.5


func _apply_hud_backdrop_style() -> void:
	var style: StyleBoxFlat = hud_backdrop.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.bg_color = hud_backdrop_color
	style.border_color = hud_backdrop_border_color


func _play_score_gain_effect() -> void:
	if score_label_tween and score_label_tween.is_running():
		score_label_tween.kill()
	if score_color_tween and score_color_tween.is_running():
		score_color_tween.kill()

	score_label.pivot_offset = score_label.size * 0.5
	score_label.scale = Vector2(1.0, 1.0)
	score_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

	score_label_tween = create_tween()
	score_label_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Expand/rebound from center in all directions.
	score_label_tween.tween_property(score_label, "scale", Vector2(1.28, 1.28), 0.24)
	score_label_tween.tween_property(score_label, "scale", Vector2(0.92, 0.92), 0.16)
	score_label_tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.28)

	# Color flash cycle while rebounding.
	score_color_tween = create_tween()
	score_color_tween.tween_property(score_label, "modulate", Color(1.0, 0.5, 0.2, 1.0), 0.12)
	score_color_tween.tween_property(score_label, "modulate", Color(1.0, 0.95, 0.3, 1.0), 0.12)
	score_color_tween.tween_property(score_label, "modulate", Color(0.3, 1.0, 0.8, 1.0), 0.14)
	score_color_tween.tween_property(score_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.24)

	_emit_score_particles()


func _setup_score_feedback_fx() -> void:
	score_particles = GPUParticles2D.new()
	score_particles.name = "ScoreParticles"
	score_particles.one_shot = true
	score_particles.explosiveness = 1.0
	score_particles.amount = 60
	score_particles.lifetime = 0.8
	score_particles.emitting = false
	score_particles.z_index = 20
	add_child(score_particles)

	# Small white square texture for sparks.
	var img: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	var spark_tex: ImageTexture = ImageTexture.create_from_image(img)
	score_particles.texture = spark_tex

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10.0
	material.spread = 180.0
	material.gravity = Vector3(0.0, 120.0, 0.0)
	material.initial_velocity_min = 120.0
	material.initial_velocity_max = 220.0
	material.scale_min = 1.5
	material.scale_max = 2.6
	material.angular_velocity_min = -12.0
	material.angular_velocity_max = 12.0
	material.damping_min = 15.0
	material.damping_max = 25.0

	var grad: Gradient = Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.45, 0.2, 1.0))
	grad.add_point(0.4, Color(1.0, 1.0, 0.25, 1.0))
	grad.add_point(0.75, Color(0.3, 1.0, 0.8, 0.9))
	grad.add_point(1.0, Color(1.0, 1.0, 1.0, 0.0))
	var grad_tex: GradientTexture1D = GradientTexture1D.new()
	grad_tex.gradient = grad
	material.color_ramp = grad_tex

	score_particles.process_material = material


func _setup_hurt_sfx() -> void:
	hurt_sfx_player = AudioStreamPlayer.new()
	hurt_sfx_player.name = "HurtSfxPlayer"
	hurt_sfx_player.stream = HIT_HURT_SFX
	add_child(hurt_sfx_player)


func _play_hurt_sfx() -> void:
	if hurt_sfx_player == null or hurt_sfx_player.stream == null:
		return
	if hurt_sfx_player.playing:
		hurt_sfx_player.stop()
	hurt_sfx_player.play()


func _setup_order_finish_sfx() -> void:
	order_finish_sfx_player = AudioStreamPlayer.new()
	order_finish_sfx_player.name = "OrderFinishSfxPlayer"
	order_finish_sfx_player.stream = ORDER_FINISH_SFX
	add_child(order_finish_sfx_player)


func _play_order_finish_sfx() -> void:
	if order_finish_sfx_player == null or order_finish_sfx_player.stream == null:
		return
	if order_finish_sfx_player.playing:
		order_finish_sfx_player.stop()
	order_finish_sfx_player.play()


func _play_damage_flash() -> void:
	if damage_flash_overlay == null:
		return

	if damage_flash_tween and damage_flash_tween.is_running():
		damage_flash_tween.kill()

	var start_color: Color = Color(damage_flash_color.r, damage_flash_color.g, damage_flash_color.b, 0.0)
	var peak_color: Color = damage_flash_color
	var end_color: Color = Color(damage_flash_color.r, damage_flash_color.g, damage_flash_color.b, 0.0)

	damage_flash_overlay.color = start_color
	damage_flash_tween = create_tween()
	damage_flash_tween.tween_property(damage_flash_overlay, "color", peak_color, max(damage_flash_in_duration, 0.01))
	damage_flash_tween.tween_property(damage_flash_overlay, "color", end_color, max(damage_flash_out_duration, 0.01))


func _emit_score_particles() -> void:
	if score_particles == null:
		return
	score_particles.global_position = score_label.get_global_rect().get_center() + score_particles_offset
	score_particles.restart()
	score_particles.emitting = true


func _update_wave_target_label() -> void:
	wave_target_label.text = "Wave %d Target: %.1f" % [current_wave, current_wave_target_score]


func _update_game_timer_label() -> void:
	var clamped: int = max(int(ceil(game_time_left)), 0)
	var mins: int = clamped / 60
	var secs: int = clamped % 60
	game_timer_label.text = "Time: %02d:%02d" % [mins, secs]


func _show_wave_popup() -> void:
	wave_popup_open = true
	wave_popup.show_popup(current_wave, current_wave_target_score, game_time_left)


# important place for changing buff values
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#

func _on_wave_buff_chosen(buff_id: String) -> void:
	match buff_id:
		"more_time":
			Global.modify_value("order_time_limit", "add", 7.0)
		"faster_boxes":
			Global.modify_value("box_respawn_time", "multiply", 0.85)
		"faster_player":
			Global.modify_value("player_move_speed", "add", 100)
		"inventory_up":
			Global.increase_inventory_size(1)
		"life_up":
			Global.add_life(1)
		_:
			push_warning("Unknown buff id: %s" % buff_id)

	current_wave += 1
	current_wave_target_score *= Global.wave_target_growth_multiplier
	Global.order_length_min = min(Global.order_length_min + 1, 6)
	Global.order_length_max = min(Global.order_length_max + 1, 6)
	if Global.order_length_max < Global.order_length_min:
		Global.order_length_max = Global.order_length_min

	_update_wave_target_label()
	wave_popup.hide_popup()
	wave_popup_open = false
	order_spawn_elapsed = 0.0
	_try_spawn_order()


func _end_game() -> void:
	game_ended = true
	wave_popup_open = false
	wave_popup.hide_popup()

	var average_time_left_ratio: float = 1.0
	if cured_patients > 0:
		average_time_left_ratio = total_time_used_ratio / float(cured_patients)

	game_over_popup.show_results(cured_patients, average_time_left_ratio, Global.score)


func _on_lives_changed(_current: int, _max_value: int) -> void:
	_update_lives_display()


func _update_lives_display() -> void:
	for child in hearts_container.get_children():
		child.queue_free()

	for i in range(Global.current_lives):
		var heart: TextureRect = TextureRect.new()
		heart.texture = HEART_ICON
		heart.custom_minimum_size = Vector2(42, 42)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(heart)


func _lose_life_and_check_end() -> void:
	if game_ended:
		return
	_play_damage_flash()
	_play_hurt_sfx()
	Global.lose_life(1)
	print("Life lost. Remaining lives:", Global.current_lives)
	if Global.current_lives <= 0:
		print("Game over reason: lives reached 0.")
		_end_game()

# ---------------------------
# LOCK SYSTEM (UNCHANGED)
# ---------------------------
func update_locks():

	for lock in lock_nodes:
		lock.queue_free()

	lock_nodes.clear()

	var lock_count = Global.total_inventory_slots - Global.unlocked_inventory_slots

	for i in range(lock_count):
		var lock = lock_scene.instantiate()
		lock_vbox.add_child(lock)
		lock_nodes.append(lock)
