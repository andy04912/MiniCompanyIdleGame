extends Node
## 遊戲管理器 - 核心遊戲邏輯

var character: CharacterData
var is_game_started: bool = false

# 系統引用
var job_system: JobSystem
var company_system: CompanySystem
var education_system: EducationSystem
var relationship_system: RelationshipSystem
var prestige_system: PrestigeSystem

func _ready() -> void:
	character = CharacterData.new()

	# 初始化子系統
	job_system = JobSystem.new()
	company_system = CompanySystem.new()
	education_system = EducationSystem.new()
	relationship_system = RelationshipSystem.new()
	prestige_system = PrestigeSystem.new()

	add_child(job_system)
	add_child(company_system)
	add_child(education_system)
	add_child(relationship_system)
	add_child(prestige_system)

	# 連接時間事件
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.month_passed.connect(_on_month_passed)
	EventBus.year_passed.connect(_on_year_passed)

func reset_all() -> void:
	## 完全重置所有狀態（轉生用）
	character = CharacterData.new()
	is_game_started = false
	job_system.reset()
	company_system.reset()
	education_system.reset()
	relationship_system.reset()

func start_new_game(char_name: String, gender: CharacterData.Gender) -> void:
	reset_all()
	character.character_name = char_name
	character.gender = gender
	character.birth_year = TimeManager.current_year - 22

	is_game_started = true
	EventBus.character_created.emit({
		"name": char_name,
		"gender": gender,
	})

func start_new_game_with_prestige(char_name: String, gender: CharacterData.Gender, bonuses: Dictionary) -> void:
	start_new_game(char_name, gender)
	character.prestige_bonuses = bonuses
	character.prestige_count = bonuses.get("prestige_count", 0)
	character.money += bonuses.get("starting_money_bonus", 0.0)

func _on_day_passed(_day: int) -> void:
	if not is_game_started:
		return

	# 每日更新
	_daily_stat_recovery()
	_daily_random_events()

	# 自動儲存（每30天）
	if _day % 30 == 0:
		SaveManager.save_game()

func _on_month_passed(_month: int) -> void:
	if not is_game_started:
		return

	# 月薪發放由 job_system 處理
	# 公司收入由 company_system 處理

func _on_year_passed(_year: int) -> void:
	if not is_game_started:
		return

	var age := TimeManager.get_age()
	EventBus.age_changed.emit(age)

	# 年齡影響
	if age > 50:
		character.stamina = maxf(character.stamina - 0.5, 1.0)
		character.health = maxf(character.health - 1.0, 1.0)

func _daily_stat_recovery() -> void:
	# 精力恢復
	character.energy = minf(character.energy + 5.0, 100.0)

	# 壓力自然消退
	character.stress = maxf(character.stress - 1.0, 0.0)

	# 壓力影響健康和幸福
	if character.stress > 80:
		character.health = maxf(character.health - 0.5, 0.0)
		character.happiness = maxf(character.happiness - 1.0, 0.0)
	elif character.stress < 20:
		character.happiness = minf(character.happiness + 0.2, 100.0)

func _daily_random_events() -> void:
	# 隨機事件（簡化版）
	var roll := randf()
	var luck_factor := character.get_effective_stat("luck") / 100.0

	# 好運事件
	if roll < 0.01 * luck_factor:
		var bonus := randf_range(100, 1000) * (1.0 + luck_factor)
		character.add_money(bonus)
		EventBus.show_notification.emit("運氣不錯！撿到了 $%.0f" % bonus, "positive")

func format_money(amount: float) -> String:
	if amount >= 100_000_000:  # 1億
		return "%.2f億" % (amount / 100_000_000.0)
	elif amount >= 10_000_000:  # 1000萬
		return "%.0f萬" % (amount / 10_000.0)
	elif amount >= 10_000:  # 1萬
		return "%.1f萬" % (amount / 10_000.0)
	else:
		return "$%.0f" % amount

func get_save_data() -> Dictionary:
	return {
		"character": character.get_save_data(),
		"is_game_started": is_game_started,
		"time": TimeManager.get_save_data(),
		"job_system": job_system.get_save_data(),
		"company_system": company_system.get_save_data(),
		"education_system": education_system.get_save_data(),
		"relationship_system": relationship_system.get_save_data(),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("character"):
		character.load_save_data(data["character"])
	is_game_started = data.get("is_game_started", false)
	if data.has("time"):
		TimeManager.load_save_data(data["time"])
	if data.has("job_system"):
		job_system.load_save_data(data["job_system"])
	if data.has("company_system"):
		company_system.load_save_data(data["company_system"])
	if data.has("education_system"):
		education_system.load_save_data(data["education_system"])
	if data.has("relationship_system"):
		relationship_system.load_save_data(data["relationship_system"])
