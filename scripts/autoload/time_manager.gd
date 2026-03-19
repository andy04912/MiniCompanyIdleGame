extends Node
## 時間管理器 - 控制遊戲內時間流逝

# 遊戲時間設定
var game_speed: float = 1.0  # 時間倍率
var is_paused: bool = false

# 遊戲內日期
var current_year: int = 2026
var current_month: int = 6  # 大學畢業月份
var current_day: int = 1
var current_hour: float = 0.0

# 時間累計
var total_days_played: int = 0
var _accumulated_time: float = 0.0

# 每個遊戲日對應的現實秒數（基礎值）
const SECONDS_PER_GAME_DAY: float = 2.0

var speed_multipliers: Array[float] = [0.0, 1.0, 2.0, 5.0, 10.0]
var current_speed_index: int = 1

func _ready() -> void:
	game_speed = speed_multipliers[current_speed_index]

func _process(delta: float) -> void:
	if is_paused or game_speed <= 0.0:
		return

	_accumulated_time += delta * game_speed
	var days_to_advance := int(_accumulated_time / SECONDS_PER_GAME_DAY)

	if days_to_advance > 0:
		_accumulated_time -= days_to_advance * SECONDS_PER_GAME_DAY
		for i in range(days_to_advance):
			_advance_day()

	EventBus.game_tick.emit(delta * game_speed)

func _advance_day() -> void:
	current_day += 1
	total_days_played += 1
	EventBus.day_passed.emit(total_days_played)

	if current_day > _days_in_month():
		current_day = 1
		current_month += 1
		EventBus.month_passed.emit(current_month)

		if current_month > 12:
			current_month = 1
			current_year += 1
			EventBus.year_passed.emit(current_year)

func _days_in_month() -> int:
	match current_month:
		2:
			return 29 if current_year % 4 == 0 else 28
		4, 6, 9, 11:
			return 30
		_:
			return 31

func get_date_string() -> String:
	return "%d年%d月%d日" % [current_year, current_month, current_day]

func get_age() -> int:
	# 角色出生年 = 起始年 - 22（大學畢業年齡）
	var birth_year := GameManager.character.birth_year
	var age := current_year - birth_year
	if current_month < 1:  # 簡化：假設1月生日
		age -= 1
	return age

func cycle_speed() -> void:
	current_speed_index = (current_speed_index + 1) % speed_multipliers.size()
	game_speed = speed_multipliers[current_speed_index]

func toggle_pause() -> void:
	is_paused = !is_paused
	if is_paused:
		game_speed = 0.0
	else:
		game_speed = speed_multipliers[current_speed_index]

func get_speed_text() -> String:
	if is_paused:
		return "暫停"
	return "x%s" % str(speed_multipliers[current_speed_index])

func get_save_data() -> Dictionary:
	return {
		"current_year": current_year,
		"current_month": current_month,
		"current_day": current_day,
		"total_days_played": total_days_played,
		"current_speed_index": current_speed_index,
	}

func load_save_data(data: Dictionary) -> void:
	current_year = data.get("current_year", 2026)
	current_month = data.get("current_month", 6)
	current_day = data.get("current_day", 1)
	total_days_played = data.get("total_days_played", 0)
	current_speed_index = data.get("current_speed_index", 1)
	game_speed = speed_multipliers[current_speed_index]
