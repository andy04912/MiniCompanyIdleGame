class_name RelationshipSystem
extends Node
## 關係系統 - 交友、戀愛、結婚、生小孩

var _dating_days: int = 0
var _can_meet_today: bool = true

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)

func reset() -> void:
	_dating_days = 0
	_can_meet_today = true

func try_meet_someone() -> void:
	var character := GameManager.character
	if character.relationship_status != "single":
		EventBus.show_notification.emit("你已經有伴侶了！", "info")
		return

	if not _can_meet_today:
		EventBus.show_notification.emit("今天已經社交過了，明天再試！", "info")
		return

	_can_meet_today = false
	var charisma := character.get_effective_stat("charisma")
	var luck := character.get_effective_stat("luck")
	var success_chance := (charisma + luck) / 200.0 * 0.3  # 最高約30%

	if randf() < success_chance:
		_start_dating(character)
	else:
		character.add_skill_exp("溝通", 0.02)
		EventBus.show_notification.emit("今天沒有遇到合適的對象，下次再試！", "info")

func _start_dating(character: CharacterData) -> void:
	var partner_names_male := ["小明", "志偉", "家豪", "建宏", "俊傑", "冠宇"]
	var partner_names_female := ["小美", "雅婷", "怡君", "佳慧", "詩涵", "欣怡"]

	var partner_name: String
	if character.gender == CharacterData.Gender.MALE:
		partner_name = partner_names_female[randi() % partner_names_female.size()]
	else:
		partner_name = partner_names_male[randi() % partner_names_male.size()]

	character.relationship_status = "dating"
	character.partner = {
		"name": partner_name,
		"affection": 30.0,
		"days_together": 0,
	}
	_dating_days = 0

	EventBus.relationship_started.emit(character.partner)
	EventBus.show_notification.emit("你開始和 %s 交往了！" % partner_name, "positive")

func try_propose() -> bool:
	var character := GameManager.character
	if character.relationship_status != "dating":
		EventBus.show_notification.emit("你需要先有交往對象！", "negative")
		return false

	var affection: float = character.partner.get("affection", 0.0)
	if affection < 80.0:
		EventBus.show_notification.emit("感情還不夠深厚（好感度 %.0f/80）" % affection, "negative")
		return false

	var ring_cost := 5000.0
	var wedding_cost := 20000.0
	var total_cost := ring_cost + wedding_cost

	if character.money < total_cost:
		EventBus.show_notification.emit("資金不足！結婚費用：%s" % GameManager.format_money(total_cost), "negative")
		return false

	character.add_money(-total_cost)
	character.relationship_status = "married"
	character.partner["married_day"] = TimeManager.total_days_played
	character.happiness = minf(character.happiness + 30.0, 100.0)

	EventBus.married.emit()
	EventBus.show_notification.emit("恭喜結婚！和 %s 共度一生！" % character.partner["name"], "positive")
	return true

func try_have_child() -> bool:
	var character := GameManager.character
	if character.relationship_status != "married":
		EventBus.show_notification.emit("需要先結婚才能有小孩！", "negative")
		return false

	if character.children.size() >= 5:
		EventBus.show_notification.emit("已經有5個小孩了！", "info")
		return false

	var age := TimeManager.get_age()
	var success_chance := 0.5
	if age > 35:
		success_chance -= (age - 35) * 0.03
	success_chance = maxf(success_chance, 0.05)

	if randf() > success_chance:
		EventBus.show_notification.emit("暫時沒有好消息，以後再試試。", "info")
		return false

	var child_names_male := ["小寶", "大寶", "阿明", "阿豪", "小安"]
	var child_names_female := ["小花", "小雨", "阿萱", "小晴", "小星"]
	var child_gender: int = randi() % 2
	var child_name: String
	if child_gender == 0:
		child_name = child_names_male[randi() % child_names_male.size()]
	else:
		child_name = child_names_female[randi() % child_names_female.size()]

	var child := {
		"name": child_name,
		"gender": child_gender,
		"birth_year": TimeManager.current_year,
		"birth_day": TimeManager.total_days_played,
	}

	character.children.append(child)
	character.happiness = minf(character.happiness + 20.0, 100.0)

	EventBus.child_born.emit(child)
	EventBus.show_notification.emit("恭喜！%s 出生了！" % child_name, "positive")
	return true

func go_on_date() -> void:
	var character := GameManager.character
	if character.relationship_status == "single":
		EventBus.show_notification.emit("你需要先找到伴侶！", "negative")
		return

	var date_cost := 500.0
	if character.money < date_cost:
		EventBus.show_notification.emit("約會需要 %s！" % GameManager.format_money(date_cost), "negative")
		return

	character.add_money(-date_cost)
	character.partner["affection"] = minf(character.partner.get("affection", 0.0) + 5.0, 100.0)
	character.happiness = minf(character.happiness + 5.0, 100.0)
	character.stress = maxf(character.stress - 5.0, 0.0)

	EventBus.show_notification.emit("和 %s 約會很開心！好感度 +5" % character.partner["name"], "positive")

func _on_day_passed(_day: int) -> void:
	if not GameManager.is_game_started:
		return

	_can_meet_today = true
	var character := GameManager.character

	if character.relationship_status == "dating":
		_dating_days += 1
		character.partner["days_together"] = _dating_days
		# 自然好感度增長
		character.partner["affection"] = minf(
			character.partner.get("affection", 0.0) + 0.2,
			100.0
		)

	elif character.relationship_status == "married":
		# 已婚幸福加成
		character.happiness = minf(character.happiness + 0.3, 100.0)
		character.stress = maxf(character.stress - 0.2, 0.0)

		# 小孩帶來幸福和開銷
		for child in character.children:
			character.happiness = minf(character.happiness + 0.1, 100.0)
			character.add_money(-5.0)  # 養育費

func get_save_data() -> Dictionary:
	return {
		"dating_days": _dating_days,
	}

func load_save_data(data: Dictionary) -> void:
	_dating_days = data.get("dating_days", 0)
