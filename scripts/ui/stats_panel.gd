extends VBoxContainer
## 角色狀態面板

@onready var intelligence_bar: ProgressBar = %IntelligenceBar
@onready var charisma_bar: ProgressBar = %CharismaBar
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var luck_bar: ProgressBar = %LuckBar
@onready var leadership_bar: ProgressBar = %LeadershipBar
@onready var creativity_bar: ProgressBar = %CreativityBar

@onready var happiness_bar: ProgressBar = %HappinessBar
@onready var health_bar: ProgressBar = %HealthBar
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var stress_bar: ProgressBar = %StressBar

@onready var skills_container: VBoxContainer = %SkillsContainer

@onready var education_label: Label = %EducationLabel
@onready var relationship_label: Label = %RelationshipLabel
@onready var children_label: Label = %ChildrenLabel
@onready var prestige_label: Label = %StatsPrestigeLabel

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)

func _on_day_passed(_day: int) -> void:
	_update_display()

func _update_display() -> void:
	var c := GameManager.character

	# 主要屬性
	_update_bar(intelligence_bar, c.get_effective_stat("intelligence"), "智力")
	_update_bar(charisma_bar, c.get_effective_stat("charisma"), "魅力")
	_update_bar(stamina_bar, c.get_effective_stat("stamina"), "體力")
	_update_bar(luck_bar, c.get_effective_stat("luck"), "運氣")
	_update_bar(leadership_bar, c.get_effective_stat("leadership"), "領導力")
	_update_bar(creativity_bar, c.get_effective_stat("creativity"), "創造力")

	# 狀態
	_update_bar(happiness_bar, c.happiness, "幸福")
	_update_bar(health_bar, c.health, "健康")
	_update_bar(energy_bar, c.energy, "精力")
	_update_bar(stress_bar, c.stress, "壓力")

	# 技能
	for child in skills_container.get_children():
		child.queue_free()

	for skill_name in c.skills:
		var level := c.get_skill_level(skill_name)
		var progress := c.skills[skill_name] - float(level)
		var label := Label.new()
		label.text = "%s Lv.%d (%.0f%%)" % [skill_name, level, progress * 100.0]
		skills_container.add_child(label)

	# 教育
	if c.is_studying:
		education_label.text = "學歷: 碩士在讀 (%.0f%%)" % c.study_progress
	elif c.has_masters:
		education_label.text = "學歷: 碩士"
	else:
		education_label.text = "學歷: 大學"

	# 關係
	match c.relationship_status:
		"single":
			relationship_label.text = "感情: 單身"
		"dating":
			relationship_label.text = "感情: 交往中 - %s (好感 %.0f)" % [c.partner.get("name", ""), c.partner.get("affection", 0)]
		"married":
			relationship_label.text = "感情: 已婚 - %s" % c.partner.get("name", "")

	# 小孩
	if c.children.is_empty():
		children_label.text = "子女: 無"
	else:
		var names: PackedStringArray = []
		for child in c.children:
			names.append(child.get("name", ""))
		children_label.text = "子女: %s" % ", ".join(names)

	# 轉生
	if c.prestige_count > 0:
		prestige_label.text = "轉生次數: %d | 經驗倍率: x%.1f" % [c.prestige_count, c.prestige_bonuses.get("exp_multiplier", 1.0)]
		prestige_label.visible = true
	else:
		prestige_label.visible = false

func _update_bar(bar: ProgressBar, value: float, label_text: String) -> void:
	bar.value = value
	bar.max_value = 100.0
	# ProgressBar 的 tooltip
	bar.tooltip_text = "%s: %.1f" % [label_text, value]
