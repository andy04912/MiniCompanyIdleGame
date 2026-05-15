class_name CompanySystem
extends Node
## 公司經營系統

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.month_passed.connect(_on_month_passed)

func reset() -> void:
	pass  # Company state lives in character.company, reset via CharacterData

func found_company(option: Dictionary) -> bool:
	var character := GameManager.character

	# 檢查資金
	var cost: float = option.get("cost", 0.0)
	if character.money < cost:
		EventBus.show_notification.emit("資金不足！需要 %s" % GameManager.format_money(cost), "negative")
		return false

	# 檢查需求
	var reqs: Dictionary = option.get("requirements", {})
	for req_key in reqs:
		var req_val: float = reqs[req_key]
		if req_key in ["intelligence", "charisma", "stamina", "luck", "leadership", "creativity"]:
			if character.get_effective_stat(req_key) < req_val:
				EventBus.show_notification.emit("能力不足！%s 需要達到 %.0f" % [req_key, req_val], "negative")
				return false
		else:
			if character.get_skill_level(req_key) < int(req_val):
				EventBus.show_notification.emit("技能不足！%s 需要達到 %d 級" % [req_key, int(req_val)], "negative")
				return false

	# 扣錢創業
	character.add_money(-cost)
	character.has_company = true
	character.company = CompanyDatabase.create_new_company(option)

	EventBus.company_founded.emit(character.company)
	EventBus.show_notification.emit("恭喜創業成功！%s 正式成立！" % character.company["name"], "positive")
	return true

func hire_employee() -> bool:
	var character := GameManager.character
	if not character.has_company:
		return false

	var company: Dictionary = character.company
	if company["employees"] >= company["max_employees"]:
		EventBus.show_notification.emit("已達到最大員工數量！需要升級公司。", "negative")
		return false

	var hire_cost: float = 500.0 + float(company["employees"]) * 200.0
	if character.money < hire_cost:
		EventBus.show_notification.emit("資金不足！僱用費用：%s" % GameManager.format_money(hire_cost), "negative")
		return false

	character.add_money(-hire_cost)
	company["employees"] += 1
	company["expenses_per_day"] += 30.0  # 員工日薪
	_recalculate_revenue()

	EventBus.show_notification.emit("成功僱用新員工！目前共 %d 人" % company["employees"], "positive")
	return true

func upgrade_company() -> bool:
	var character := GameManager.character
	if not character.has_company:
		return false

	var company: Dictionary = character.company
	var current_tier: int = company["tier"]
	var next_tier: int = current_tier + 1

	if next_tier > CompanyDatabase.CompanyTier.CONGLOMERATE:
		EventBus.show_notification.emit("已經是最高等級了！", "info")
		return false

	var requirements := CompanyDatabase.get_tier_requirements(next_tier as CompanyDatabase.CompanyTier)
	var upgrade_cost: float = requirements.get("upgrade_cost", 0.0)

	if character.money < upgrade_cost:
		EventBus.show_notification.emit("資金不足！升級費用：%s" % GameManager.format_money(upgrade_cost), "negative")
		return false

	var min_employees: int = requirements.get("employees", 0)
	if company["employees"] < min_employees:
		EventBus.show_notification.emit("員工數不足！需要至少 %d 人" % min_employees, "negative")
		return false

	# 升級
	character.add_money(-upgrade_cost)
	company["tier"] = next_tier
	company["max_employees"] = _get_max_employees(next_tier)

	var tier_name := CompanyDatabase.get_tier_name(next_tier as CompanyDatabase.CompanyTier)
	EventBus.company_upgraded.emit(tier_name)
	EventBus.show_notification.emit("公司升級為【%s】！" % tier_name, "positive")
	return true

func open_branch() -> bool:
	var character := GameManager.character
	if not character.has_company:
		return false

	var company: Dictionary = character.company
	var branch_cost: float = 10000.0 * (float(company["branches"]) + 1.0) * (1.0 + float(company["tier"]) * 0.5)

	if character.money < branch_cost:
		EventBus.show_notification.emit("資金不足！開分店費用：%s" % GameManager.format_money(branch_cost), "negative")
		return false

	character.add_money(-branch_cost)
	company["branches"] += 1
	_recalculate_revenue()

	EventBus.branch_opened.emit(company["branches"])
	EventBus.show_notification.emit("新分店開張！目前共 %d 間" % company["branches"], "positive")
	return true

func invest_marketing() -> bool:
	var character := GameManager.character
	if not character.has_company:
		return false

	var company: Dictionary = character.company
	var marketing_cost: float = 2000.0 * (float(company["marketing_level"]) + 1.0)

	if character.money < marketing_cost:
		EventBus.show_notification.emit("資金不足！行銷費用：%s" % GameManager.format_money(marketing_cost), "negative")
		return false

	character.add_money(-marketing_cost)
	company["marketing_level"] += 1
	_recalculate_revenue()

	EventBus.show_notification.emit("行銷升級！顧客將會增加。", "positive")
	return true

func improve_product() -> bool:
	var character := GameManager.character
	if not character.has_company:
		return false

	var company: Dictionary = character.company
	var improve_cost: float = 1500.0 * (1.0 + float(company["product_quality"]) / 10.0)

	if character.money < improve_cost:
		EventBus.show_notification.emit("資金不足！", "negative")
		return false

	character.add_money(-improve_cost)
	company["product_quality"] = minf(company["product_quality"] + 5.0, 100.0)
	_recalculate_revenue()

	EventBus.show_notification.emit("產品品質提升至 %.0f！" % company["product_quality"], "positive")
	return true

func _recalculate_revenue() -> void:
	var character := GameManager.character
	if not character.has_company:
		return

	var company: Dictionary = character.company
	var base: float = company.get("base_revenue_per_day", 100.0)

	# 員工加成
	var employee_bonus: float = 1.0 + float(company["employees"]) * 0.15

	# 分店加成
	var branch_bonus := float(company["branches"])

	# 行銷加成
	var marketing_bonus: float = 1.0 + float(company["marketing_level"]) * 0.1

	# 品質加成
	var quality_bonus: float = 1.0 + float(company["product_quality"]) / 100.0

	# 領導力加成
	var leadership_bonus := 1.0 + character.get_effective_stat("leadership") / 200.0

	company["revenue_per_day"] = base * employee_bonus * branch_bonus * marketing_bonus * quality_bonus * leadership_bonus

func _on_day_passed(_day: int) -> void:
	if not GameManager.is_game_started:
		return

	var character := GameManager.character
	if not character.has_company:
		return

	var company: Dictionary = character.company
	company["days_operated"] += 1

	# 信譽緩慢增長
	company["reputation"] = minf(company["reputation"] + 0.1, 100.0)

func _on_month_passed(_month: int) -> void:
	if not GameManager.is_game_started:
		return

	var character := GameManager.character
	if not character.has_company:
		return

	var company: Dictionary = character.company

	# 月營收計算
	var monthly_revenue: float = company["revenue_per_day"] * 30.0
	var monthly_expenses: float = company["expenses_per_day"] * 30.0
	var monthly_profit := monthly_revenue - monthly_expenses

	company["total_revenue"] += monthly_revenue
	character.add_money(monthly_profit)

	EventBus.revenue_changed.emit(monthly_profit)

	# 管理技能成長
	character.add_skill_exp("管理", 0.5)
	character.add_skill_exp("領導", 0.3)

func _get_max_employees(tier: int) -> int:
	match tier:
		CompanyDatabase.CompanyTier.MICRO: return 3
		CompanyDatabase.CompanyTier.SMALL: return 15
		CompanyDatabase.CompanyTier.MEDIUM: return 50
		CompanyDatabase.CompanyTier.LARGE: return 200
		CompanyDatabase.CompanyTier.CHAIN: return 1000
		CompanyDatabase.CompanyTier.CORPORATION: return 5000
		CompanyDatabase.CompanyTier.CONGLOMERATE: return 50000
		_: return 3

func get_daily_profit() -> float:
	var character := GameManager.character
	if not character.has_company:
		return 0.0
	return character.company.get("revenue_per_day", 0.0) - character.company.get("expenses_per_day", 0.0)

func get_save_data() -> Dictionary:
	return {}

func load_save_data(_data: Dictionary) -> void:
	if GameManager.character.has_company:
		_recalculate_revenue()
