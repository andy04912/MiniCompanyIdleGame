extends Control
## 角色創建畫面

signal character_created

@onready var name_input: LineEdit = %NameInput
@onready var male_button: Button = %MaleButton
@onready var female_button: Button = %FemaleButton
@onready var start_button: Button = %StartButton
@onready var load_button: Button = %LoadButton
@onready var prestige_label: Label = %PrestigeLabel

var selected_gender: CharacterData.Gender = CharacterData.Gender.MALE

func _ready() -> void:
	male_button.pressed.connect(_on_male_selected)
	female_button.pressed.connect(_on_female_selected)
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)

	_update_gender_buttons()
	load_button.visible = SaveManager.has_save()

	# 檢查轉生資料
	var prestige_data := SaveManager.load_prestige_data()
	if prestige_data.is_empty():
		prestige_label.visible = false
	else:
		prestige_label.visible = true
		prestige_label.text = "第 %d 次人生 | 經驗倍率 x%.1f" % [
			prestige_data.get("prestige_count", 0),
			prestige_data.get("exp_multiplier", 1.0),
		]

func _on_male_selected() -> void:
	selected_gender = CharacterData.Gender.MALE
	_update_gender_buttons()

func _on_female_selected() -> void:
	selected_gender = CharacterData.Gender.FEMALE
	_update_gender_buttons()

func _update_gender_buttons() -> void:
	male_button.button_pressed = selected_gender == CharacterData.Gender.MALE
	female_button.button_pressed = selected_gender == CharacterData.Gender.FEMALE

func _on_start_pressed() -> void:
	var char_name := name_input.text.strip_edges()
	if char_name.is_empty():
		char_name = "玩家"

	var prestige_data := SaveManager.load_prestige_data()
	if prestige_data.is_empty():
		GameManager.start_new_game(char_name, selected_gender)
	else:
		GameManager.start_new_game_with_prestige(char_name, selected_gender, prestige_data)

	character_created.emit()

func _on_load_pressed() -> void:
	if SaveManager.load_game():
		character_created.emit()
