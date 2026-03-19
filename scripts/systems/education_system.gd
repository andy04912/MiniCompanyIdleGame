class_name EducationSystem
extends Node
## 教育系統 - 碩士學位進修

const MASTERS_DURATION_DAYS: int = 365  # 碩士約需1年（遊戲內時間）
const MASTERS_COST: float = 20000.0
const MASTERS_DAILY_COST: float = 10.0  # 日常生活費

var _study_days: int = 0

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)

func start_masters() -> bool:
	var character := GameManager.character

	if character.has_masters:
		EventBus.show_notification.emit("你已經有碩士學位了！", "info")
		return false

	if character.is_studying:
		EventBus.show_notification.emit("你正在進修中！", "info")
		return false

	if character.money < MASTERS_COST:
		EventBus.show_notification.emit("資金不足！碩士學費：%s" % GameManager.format_money(MASTERS_COST), "negative")
		return false

	character.add_money(-MASTERS_COST)
	character.is_studying = true
	character.study_progress = 0.0
	_study_days = 0

	EventBus.education_started.emit("碩士")
	EventBus.show_notification.emit("開始攻讀碩士學位！", "positive")
	return true

func drop_out() -> void:
	var character := GameManager.character
	if not character.is_studying:
		return

	character.is_studying = false
	character.study_progress = 0.0
	_study_days = 0

	EventBus.show_notification.emit("你中斷了碩士學業。學費不予退還。", "negative")

func _on_day_passed(_day: int) -> void:
	if not GameManager.is_game_started:
		return

	var character := GameManager.character
	if not character.is_studying:
		return

	_study_days += 1

	# 學習進度（受智力影響）
	var intelligence_factor := character.get_effective_stat("intelligence") / 50.0
	var daily_progress := (100.0 / MASTERS_DURATION_DAYS) * (1.0 + intelligence_factor * 0.3)
	character.study_progress = minf(character.study_progress + daily_progress, 100.0)

	# 日常消耗
	character.add_money(-MASTERS_DAILY_COST)
	character.stress = minf(character.stress + 0.5, 100.0)

	# 屬性和技能成長
	character.intelligence = minf(character.intelligence + 0.05, 100.0)
	character.add_skill_exp("研究", 0.03)
	character.add_skill_exp("邏輯思維", 0.02)

	# 完成碩士
	if character.study_progress >= 100.0:
		_complete_masters()

func _complete_masters() -> void:
	var character := GameManager.character
	character.has_masters = true
	character.is_studying = false
	character.study_progress = 0.0
	_study_days = 0

	# 碩士學位加成
	character.intelligence = minf(character.intelligence + 10.0, 100.0)
	character.add_skill_exp("研究", 5.0)

	EventBus.education_completed.emit("碩士")
	EventBus.show_notification.emit("恭喜獲得碩士學位！智力大幅提升！", "positive")

func get_save_data() -> Dictionary:
	return {
		"study_days": _study_days,
	}

func load_save_data(data: Dictionary) -> void:
	_study_days = data.get("study_days", 0)
