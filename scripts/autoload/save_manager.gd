extends Node
## 存檔管理器

const SAVE_PATH := "user://savegame.json"
const PRESTIGE_SAVE_PATH := "user://prestige.json"

func save_game() -> void:
	var save_data := GameManager.get_save_data()
	save_data["save_timestamp"] = Time.get_unix_time_from_system()

	var json_string := JSON.stringify(save_data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		EventBus.game_saved.emit()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		return false

	var save_data: Dictionary = json.data
	GameManager.load_save_data(save_data)

	# 計算離線收益
	var saved_time: float = save_data.get("save_timestamp", 0.0)
	var current_time := Time.get_unix_time_from_system()
	var offline_seconds := current_time - saved_time

	if offline_seconds > 60:  # 至少離線1分鐘才計算
		_calculate_offline_progress(offline_seconds)

	EventBus.game_loaded.emit()
	return true

func _calculate_offline_progress(seconds: float) -> void:
	# 離線收益（效率為在線的50%）
	var offline_efficiency := 0.5
	var offline_days := seconds / TimeManager.SECONDS_PER_GAME_DAY * offline_efficiency

	# 最多計算7天離線收益
	offline_days = minf(offline_days, 7.0 * 24.0)

	var total_offline_income := 0.0

	# 工作收入
	if GameManager.character.current_job.size() > 0:
		var daily_salary: float = GameManager.character.current_job.get("base_salary", 0.0) / 30.0
		total_offline_income += daily_salary * offline_days

	# 公司收入
	if GameManager.character.has_company:
		var daily_profit: float = GameManager.character.company.get("revenue_per_day", 0.0) - GameManager.character.company.get("expenses_per_day", 0.0)
		if daily_profit > 0:
			total_offline_income += daily_profit * offline_days

	if total_offline_income > 0:
		GameManager.character.add_money(total_offline_income)
		var hours := int(seconds / 3600)
		var minutes := int(fmod(seconds, 3600) / 60)
		EventBus.show_notification.emit(
			"離線 %d小時%d分鐘，獲得 %s 收入！" % [hours, minutes, GameManager.format_money(total_offline_income)],
			"positive"
		)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func save_prestige_data(prestige_data: Dictionary) -> void:
	var json_string := JSON.stringify(prestige_data)
	var file := FileAccess.open(PRESTIGE_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

func load_prestige_data() -> Dictionary:
	if not FileAccess.file_exists(PRESTIGE_SAVE_PATH):
		return {}

	var file := FileAccess.open(PRESTIGE_SAVE_PATH, FileAccess.READ)
	if not file:
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		return {}

	return json.data
