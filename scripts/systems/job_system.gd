class_name JobSystem
extends Node
## 工作系統 - 處理打工、正職、升遷

var _work_experience_accumulated: float = 0.0
var _days_worked: int = 0
var _monthly_salary_pending: bool = false

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.month_passed.connect(_on_month_passed)

func apply_for_job(job_id: String) -> bool:
	var job := JobDatabase.get_job_by_id(job_id)
	if job.is_empty():
		return false

	var character := GameManager.character
	if not JobDatabase._meets_requirements(character, job):
		EventBus.show_notification.emit("你不符合這份工作的要求！", "negative")
		return false

	# 如果已有工作，先辭職
	if not character.current_job.is_empty():
		quit_job()

	character.current_job = job.duplicate(true)
	character.job_performance = 50.0
	_work_experience_accumulated = 0.0
	_days_worked = 0

	EventBus.job_started.emit(job)
	EventBus.show_notification.emit("你開始了新工作：%s！" % job["name"], "positive")
	return true

func quit_job() -> void:
	var character := GameManager.character
	if character.current_job.is_empty():
		return

	var old_job_name: String = character.current_job.get("name", "")
	character.current_job = {}
	character.job_performance = 0.0
	_work_experience_accumulated = 0.0
	_days_worked = 0

	EventBus.job_quit.emit()
	EventBus.show_notification.emit("你辭去了 %s 的工作。" % old_job_name, "info")

func try_promote() -> bool:
	var character := GameManager.character
	if character.current_job.is_empty():
		return false

	var current_job: Dictionary = character.current_job
	var exp_needed: float = current_job.get("experience_needed", 999.0)

	if _work_experience_accumulated < exp_needed:
		EventBus.show_notification.emit(
			"經驗不足！還需要 %.0f 經驗才能升遷。" % (exp_needed - _work_experience_accumulated),
			"negative"
		)
		return false

	var next_job_id: String = current_job.get("next_job", "")
	if next_job_id.is_empty():
		EventBus.show_notification.emit("這份工作已經是最高職位了！", "info")
		return false

	var next_job := JobDatabase.get_job_by_id(next_job_id)
	if next_job.is_empty():
		return false

	if not JobDatabase._meets_requirements(character, next_job):
		EventBus.show_notification.emit("你的能力還不足以升遷，繼續努力！", "negative")
		return false

	character.current_job = next_job.duplicate(true)
	_work_experience_accumulated = 0.0

	EventBus.job_promoted.emit(next_job["name"])
	EventBus.show_notification.emit("恭喜升遷為 %s！" % next_job["name"], "positive")
	return true

func _on_day_passed(_day: int) -> void:
	if not GameManager.is_game_started:
		return

	var character := GameManager.character
	if character.current_job.is_empty():
		return

	var job: Dictionary = character.current_job

	# 獲得工作經驗
	var performance_factor := character.job_performance / 100.0
	var intelligence_factor := character.get_effective_stat("intelligence") / 50.0
	var exp_gain := (1.0 + performance_factor + intelligence_factor * 0.5) * character.prestige_bonuses.get("exp_multiplier", 1.0)
	_work_experience_accumulated += exp_gain
	character.work_experience += exp_gain
	_days_worked += 1

	EventBus.work_experience_gained.emit(exp_gain)

	# 技能成長
	var skill_gains: Dictionary = job.get("skill_gains", {})
	for skill_name in skill_gains:
		var gain: float = skill_gains[skill_name] * (1.0 + intelligence_factor * 0.3)
		character.add_skill_exp(skill_name, gain)

	# 屬性成長
	var stat_gains: Dictionary = job.get("stat_gains", {})
	for stat_name in stat_gains:
		var gain: float = stat_gains[stat_name]
		var current_value: float = character.get(stat_name)
		character.set(stat_name, minf(current_value + gain, 100.0))

	# 壓力累積
	var stress_rate: float = job.get("stress_rate", 1.0)
	character.stress = minf(character.stress + stress_rate * 0.3, 100.0)

	# 精力消耗
	character.energy = maxf(character.energy - 3.0, 0.0)

	# 工作表現波動
	var stamina_factor := character.get_effective_stat("stamina") / 50.0
	var energy_factor := character.energy / 100.0
	character.job_performance = clampf(
		character.job_performance + randf_range(-2.0, 3.0) * stamina_factor * energy_factor,
		0.0, 100.0
	)

func _on_month_passed(_month: int) -> void:
	if not GameManager.is_game_started:
		return

	var character := GameManager.character
	if character.current_job.is_empty():
		return

	# 發月薪
	var base_salary: float = character.current_job.get("base_salary", 0.0)
	var performance_bonus := base_salary * (character.job_performance / 100.0 - 0.5) * 0.2
	var total_salary := base_salary + performance_bonus
	character.add_money(total_salary)

	EventBus.income_changed.emit(total_salary)

func get_promotion_progress() -> float:
	var character := GameManager.character
	if character.current_job.is_empty():
		return 0.0
	var exp_needed: float = character.current_job.get("experience_needed", 1.0)
	return minf(_work_experience_accumulated / exp_needed * 100.0, 100.0)

func get_save_data() -> Dictionary:
	return {
		"work_experience_accumulated": _work_experience_accumulated,
		"days_worked": _days_worked,
	}

func load_save_data(data: Dictionary) -> void:
	_work_experience_accumulated = data.get("work_experience_accumulated", 0.0)
	_days_worked = data.get("days_worked", 0)
