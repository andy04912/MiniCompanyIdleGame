class_name PrestigeSystem
extends Node
## 轉生系統 - 帶著部分能力重新開始

const MIN_PRESTIGE_AGE: int = 40  # 最低轉生年齡
const PRESTIGE_MONEY_REQUIREMENT: float = 100000.0  # 最低總收入要求

func can_prestige() -> bool:
	var character := GameManager.character
	var age := TimeManager.get_age()

	if age < MIN_PRESTIGE_AGE:
		return false
	if character.total_earned < PRESTIGE_MONEY_REQUIREMENT:
		return false

	return true

func get_prestige_info() -> Dictionary:
	var character := GameManager.character
	var age := TimeManager.get_age()

	# 計算轉生加成
	var stats_total := character.get_total_stats()
	var money_factor := log(maxf(character.total_earned, 1.0)) / log(10.0)  # log10
	var age_factor := float(age) / 50.0
	var company_factor := 1.0
	if character.has_company:
		company_factor += character.company.get("tier", 0) * 0.5

	var prestige_multiplier := money_factor * age_factor * company_factor * 0.1
	var new_prestige_count := character.prestige_count + 1

	return {
		"prestige_count": new_prestige_count,
		"intelligence_bonus": character.prestige_bonuses.get("intelligence_bonus", 0.0) + character.intelligence * prestige_multiplier * 0.1,
		"charisma_bonus": character.prestige_bonuses.get("charisma_bonus", 0.0) + character.charisma * prestige_multiplier * 0.1,
		"stamina_bonus": character.prestige_bonuses.get("stamina_bonus", 0.0) + character.stamina * prestige_multiplier * 0.1,
		"luck_bonus": character.prestige_bonuses.get("luck_bonus", 0.0) + character.luck * prestige_multiplier * 0.1,
		"leadership_bonus": character.prestige_bonuses.get("leadership_bonus", 0.0) + character.leadership * prestige_multiplier * 0.1,
		"creativity_bonus": character.prestige_bonuses.get("creativity_bonus", 0.0) + character.creativity * prestige_multiplier * 0.1,
		"starting_money_bonus": minf(character.total_earned * 0.01, 50000.0),
		"exp_multiplier": 1.0 + new_prestige_count * 0.1,
		"total_earned_this_life": character.total_earned,
		"age_at_prestige": age,
		"company_tier": character.company.get("tier", -1) if character.has_company else -1,
	}

func do_prestige() -> Dictionary:
	if not can_prestige():
		EventBus.show_notification.emit("還不能轉生！", "negative")
		return {}

	var prestige_info := get_prestige_info()

	# 儲存轉生資料
	SaveManager.save_prestige_data(prestige_info)

	# 重置所有遊戲狀態（角色、子系統）
	GameManager.reset_all()

	# 重置遊戲時間
	TimeManager.current_year = 2026
	TimeManager.current_month = 6
	TimeManager.current_day = 1
	TimeManager.total_days_played = 0

	# 暫停時間直到新遊戲開始
	TimeManager.is_paused = true

	# 刪除一般存檔
	SaveManager.delete_save()

	EventBus.prestige_triggered.emit(prestige_info)
	EventBus.show_notification.emit(
		"轉生成功！第 %d 次人生開始！" % prestige_info["prestige_count"],
		"positive"
	)

	return prestige_info

func get_prestige_description() -> String:
	var character := GameManager.character
	if not can_prestige():
		var age := TimeManager.get_age()
		var reasons: PackedStringArray = []
		if age < MIN_PRESTIGE_AGE:
			reasons.append("年齡需達到 %d 歲（目前 %d 歲）" % [MIN_PRESTIGE_AGE, age])
		if character.total_earned < PRESTIGE_MONEY_REQUIREMENT:
			reasons.append("總收入需達到 %s（目前 %s）" % [
				GameManager.format_money(PRESTIGE_MONEY_REQUIREMENT),
				GameManager.format_money(character.total_earned)
			])
		return "轉生條件不足：\n" + "\n".join(reasons)

	var info := get_prestige_info()
	return """轉生後將獲得：
智力加成: +%.1f
魅力加成: +%.1f
體力加成: +%.1f
運氣加成: +%.1f
領導力加成: +%.1f
創造力加成: +%.1f
初始資金: +%s
經驗倍率: x%.1f""" % [
		info["intelligence_bonus"],
		info["charisma_bonus"],
		info["stamina_bonus"],
		info["luck_bonus"],
		info["leadership_bonus"],
		info["creativity_bonus"],
		GameManager.format_money(info["starting_money_bonus"]),
		info["exp_multiplier"],
	]
