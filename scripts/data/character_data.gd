class_name CharacterData
extends RefCounted
## 角色資料模型

enum Gender { MALE, FEMALE }

# 基本資料
var character_name: String = ""
var gender: Gender = Gender.MALE
var birth_year: int = 2004  # 預設22歲大學畢業

# 屬性（1-100）
var intelligence: float = 10.0   # 智力 - 影響學習速度、經營決策
var charisma: float = 10.0      # 魅力 - 影響社交、銷售、招聘
var stamina: float = 10.0       # 體力 - 影響工作效率、可工作時數
var luck: float = 10.0          # 運氣 - 影響隨機事件、投資收益
var leadership: float = 5.0     # 領導力 - 影響管理效率、員工忠誠度
var creativity: float = 5.0     # 創造力 - 影響產品創新、行銷效果

# 技能等級
var skills: Dictionary = {}  # { "程式設計": 3, "行銷": 1, ... }

# 狀態
var happiness: float = 50.0     # 幸福度 0-100
var health: float = 100.0       # 健康度 0-100
var energy: float = 100.0       # 精力 0-100
var stress: float = 0.0         # 壓力 0-100

# 金錢
var money: float = 5000.0       # 現金（大學畢業初始）
var total_earned: float = 0.0   # 總共賺過的錢

# 教育
var has_masters: bool = false
var is_studying: bool = false
var study_progress: float = 0.0  # 0-100

# 工作
var current_job: Dictionary = {}  # 空 = 無工作
var work_experience: float = 0.0
var job_performance: float = 50.0

# 事業
var has_company: bool = false
var company: Dictionary = {}

# 關係
var relationship_status: String = "single"  # single, dating, married
var partner: Dictionary = {}
var children: Array[Dictionary] = []

# 轉生相關
var prestige_count: int = 0
var prestige_bonuses: Dictionary = {
	"intelligence_bonus": 0.0,
	"charisma_bonus": 0.0,
	"stamina_bonus": 0.0,
	"luck_bonus": 0.0,
	"leadership_bonus": 0.0,
	"creativity_bonus": 0.0,
	"starting_money_bonus": 0.0,
	"exp_multiplier": 1.0,
}

func get_effective_stat(stat_name: String) -> float:
	var base_value: float = get(stat_name)
	var bonus_key := stat_name + "_bonus"
	var bonus: float = prestige_bonuses.get(bonus_key, 0.0)
	return base_value + bonus

func get_total_stats() -> float:
	return intelligence + charisma + stamina + luck + leadership + creativity

func add_money(amount: float) -> void:
	money += amount
	if amount > 0:
		total_earned += amount
	EventBus.money_changed.emit(money)

func add_skill_exp(skill_name: String, amount: float) -> void:
	if skill_name not in skills:
		skills[skill_name] = 0.0
	var old_level := int(skills[skill_name])
	skills[skill_name] += amount * prestige_bonuses.get("exp_multiplier", 1.0)
	var new_level := int(skills[skill_name])
	if new_level > old_level:
		EventBus.skill_learned.emit(skill_name, new_level)

func get_skill_level(skill_name: String) -> int:
	return int(skills.get(skill_name, 0.0))

func get_save_data() -> Dictionary:
	return {
		"character_name": character_name,
		"gender": gender,
		"birth_year": birth_year,
		"intelligence": intelligence,
		"charisma": charisma,
		"stamina": stamina,
		"luck": luck,
		"leadership": leadership,
		"creativity": creativity,
		"skills": skills,
		"happiness": happiness,
		"health": health,
		"energy": energy,
		"stress": stress,
		"money": money,
		"total_earned": total_earned,
		"has_masters": has_masters,
		"is_studying": is_studying,
		"study_progress": study_progress,
		"current_job": current_job,
		"work_experience": work_experience,
		"job_performance": job_performance,
		"has_company": has_company,
		"company": company,
		"relationship_status": relationship_status,
		"partner": partner,
		"children": children,
		"prestige_count": prestige_count,
		"prestige_bonuses": prestige_bonuses,
	}

func load_save_data(data: Dictionary) -> void:
	for key in data:
		if key in ["children"]:
			children.clear()
			for child_data in data[key]:
				children.append(child_data)
		elif get(key) != null:
			set(key, data[key])
