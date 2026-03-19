extends VBoxContainer
## 生活面板 - 教育、感情、轉生

# 教育
@onready var education_status_label: Label = %EducationStatusLabel
@onready var study_progress_bar: ProgressBar = %StudyProgressBar
@onready var masters_button: Button = %MastersButton
@onready var drop_out_button: Button = %DropOutButton

# 感情
@onready var relationship_status_label: Label = %RelationshipStatusLabel
@onready var meet_button: Button = %MeetButton
@onready var date_button: Button = %DateButton
@onready var propose_button: Button = %ProposeButton
@onready var child_button: Button = %ChildButton
@onready var affection_bar: ProgressBar = %AffectionBar

# 轉生
@onready var prestige_info_label: Label = %PrestigeInfoLabel
@onready var prestige_button: Button = %PrestigeButton

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)

	masters_button.pressed.connect(_on_masters_pressed)
	drop_out_button.pressed.connect(_on_drop_out_pressed)
	meet_button.pressed.connect(_on_meet_pressed)
	date_button.pressed.connect(_on_date_pressed)
	propose_button.pressed.connect(_on_propose_pressed)
	child_button.pressed.connect(_on_child_pressed)
	prestige_button.pressed.connect(_on_prestige_pressed)

	_update_display()

func _on_day_passed(_day: int) -> void:
	if _day % 3 == 0:
		_update_display()

func _update_display() -> void:
	var c := GameManager.character

	# 教育區域
	if c.has_masters:
		education_status_label.text = "碩士學位 ✓"
		study_progress_bar.visible = false
		masters_button.visible = false
		drop_out_button.visible = false
	elif c.is_studying:
		education_status_label.text = "碩士進修中..."
		study_progress_bar.visible = true
		study_progress_bar.value = c.study_progress
		masters_button.visible = false
		drop_out_button.visible = true
	else:
		education_status_label.text = "大學學歷"
		study_progress_bar.visible = false
		masters_button.visible = true
		masters_button.text = "攻讀碩士 (%s)" % GameManager.format_money(EducationSystem.MASTERS_COST)
		drop_out_button.visible = false

	# 感情區域
	match c.relationship_status:
		"single":
			relationship_status_label.text = "單身"
			meet_button.visible = true
			date_button.visible = false
			propose_button.visible = false
			child_button.visible = false
			affection_bar.visible = false
		"dating":
			relationship_status_label.text = "交往中 - %s" % c.partner.get("name", "")
			meet_button.visible = false
			date_button.visible = true
			propose_button.visible = true
			propose_button.disabled = c.partner.get("affection", 0.0) < 80.0
			child_button.visible = false
			affection_bar.visible = true
			affection_bar.value = c.partner.get("affection", 0.0)
		"married":
			relationship_status_label.text = "已婚 - %s" % c.partner.get("name", "")
			meet_button.visible = false
			date_button.visible = true
			propose_button.visible = false
			child_button.visible = c.children.size() < 5
			affection_bar.visible = true
			affection_bar.value = c.partner.get("affection", 0.0)

	# 轉生區域
	prestige_info_label.text = GameManager.prestige_system.get_prestige_description()
	prestige_button.disabled = not GameManager.prestige_system.can_prestige()

func _on_masters_pressed() -> void:
	GameManager.education_system.start_masters()
	_update_display()

func _on_drop_out_pressed() -> void:
	GameManager.education_system.drop_out()
	_update_display()

func _on_meet_pressed() -> void:
	GameManager.relationship_system.try_meet_someone()
	_update_display()

func _on_date_pressed() -> void:
	GameManager.relationship_system.go_on_date()
	_update_display()

func _on_propose_pressed() -> void:
	GameManager.relationship_system.try_propose()
	_update_display()

func _on_child_pressed() -> void:
	GameManager.relationship_system.try_have_child()
	_update_display()

func _on_prestige_pressed() -> void:
	var prestige_info := GameManager.prestige_system.do_prestige()
	if not prestige_info.is_empty():
		# 重新載入場景到角色創建
		get_tree().reload_current_scene()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_update_display()
