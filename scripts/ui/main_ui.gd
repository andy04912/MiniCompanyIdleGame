extends Control
## 主遊戲介面

@onready var character_creation: Control = $CharacterCreation
@onready var game_ui: VBoxContainer = $GameUI

@onready var status_panel: Control = %StatusPanel
@onready var tab_container: TabContainer = %TabContainer
@onready var notification_label: Label = %NotificationLabel
@onready var speed_button: Button = %SpeedButton
@onready var save_button: Button = %SaveButton

# 頂部資訊列
@onready var name_label: Label = %NameLabel
@onready var age_label: Label = %AgeLabel
@onready var date_label: Label = %DateLabel
@onready var money_label: Label = %MoneyLabel
@onready var job_label: Label = %JobLabel

var _notification_timer: float = 0.0

func _ready() -> void:
	EventBus.show_notification.connect(_on_show_notification)
	EventBus.game_tick.connect(_on_game_tick)
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.day_passed.connect(_on_day_passed)

	speed_button.pressed.connect(_on_speed_pressed)
	save_button.pressed.connect(_on_save_pressed)

	notification_label.visible = false

	# 連接角色創建完成信號
	character_creation.character_created.connect(_on_character_created)

	# 初始狀態：顯示角色創建，隱藏遊戲UI
	character_creation.visible = true
	game_ui.visible = false

	# 暫停時間直到遊戲開始
	TimeManager.is_paused = true

func _on_character_created() -> void:
	character_creation.visible = false
	game_ui.visible = true
	TimeManager.is_paused = false
	_update_all_labels()

func _on_game_tick(_delta: float) -> void:
	if _notification_timer > 0:
		_notification_timer -= _delta
		if _notification_timer <= 0:
			notification_label.visible = false

func _on_day_passed(_day: int) -> void:
	_update_all_labels()

func _on_money_changed(_amount: float) -> void:
	money_label.text = "資金: %s" % GameManager.format_money(GameManager.character.money)

func _update_all_labels() -> void:
	var c := GameManager.character
	name_label.text = "%s (%s)" % [c.character_name, "♂" if c.gender == CharacterData.Gender.MALE else "♀"]
	age_label.text = "%d 歲" % TimeManager.get_age()
	date_label.text = TimeManager.get_date_string()
	money_label.text = "資金: %s" % GameManager.format_money(c.money)

	if c.current_job.is_empty():
		job_label.text = "無業"
	else:
		job_label.text = c.current_job.get("name", "未知")

func _on_show_notification(message: String, type: String) -> void:
	notification_label.text = message
	notification_label.visible = true

	match type:
		"positive":
			notification_label.add_theme_color_override("font_color", Color.GREEN)
		"negative":
			notification_label.add_theme_color_override("font_color", Color.RED)
		_:
			notification_label.add_theme_color_override("font_color", Color.WHITE)

	_notification_timer = 5.0

func _on_speed_pressed() -> void:
	TimeManager.cycle_speed()
	speed_button.text = TimeManager.get_speed_text()

func _on_save_pressed() -> void:
	SaveManager.save_game()
	EventBus.show_notification.emit("遊戲已儲存！", "positive")
