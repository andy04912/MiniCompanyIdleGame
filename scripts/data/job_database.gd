class_name JobDatabase
extends RefCounted
## 工作資料庫 - 定義所有可用的工作

# 工作類型
enum JobType { PART_TIME, FULL_TIME, MANAGEMENT, EXECUTIVE }

# 工作資料結構
# {
#   "id": String,
#   "name": String,
#   "type": JobType,
#   "base_salary": float (月薪),
#   "requirements": { "stat_name": min_value, "skill_name": min_level },
#   "experience_needed": float (升職所需經驗),
#   "next_job": String (升職後的工作ID),
#   "skill_gains": { "skill_name": gain_per_day },
#   "stat_gains": { "stat_name": gain_per_day },
#   "stress_rate": float,
#   "description": String,
# }

static func get_all_jobs() -> Dictionary:
	return {
		# ===== 打工 (Part-time) =====
		"pt_convenience": {
			"id": "pt_convenience",
			"name": "便利商店店員",
			"type": JobType.PART_TIME,
			"base_salary": 800.0,
			"requirements": {},
			"experience_needed": 30.0,
			"next_job": "pt_convenience_senior",
			"skill_gains": {"服務": 0.02, "溝通": 0.01},
			"stat_gains": {"charisma": 0.01, "stamina": 0.01},
			"stress_rate": 0.5,
			"description": "在便利商店打工，學習基本服務技能。",
		},
		"pt_convenience_senior": {
			"id": "pt_convenience_senior",
			"name": "便利商店資深店員",
			"type": JobType.PART_TIME,
			"base_salary": 1200.0,
			"requirements": {"服務": 1},
			"experience_needed": 60.0,
			"next_job": "",
			"skill_gains": {"服務": 0.03, "溝通": 0.02, "管理": 0.01},
			"stat_gains": {"charisma": 0.02, "leadership": 0.01},
			"stress_rate": 0.8,
			"description": "資深店員，負責帶新人和簡單管理。",
		},
		"pt_tutor": {
			"id": "pt_tutor",
			"name": "家教老師",
			"type": JobType.PART_TIME,
			"base_salary": 1500.0,
			"requirements": {"intelligence": 15},
			"experience_needed": 40.0,
			"next_job": "pt_tutor_senior",
			"skill_gains": {"教學": 0.03, "溝通": 0.02},
			"stat_gains": {"intelligence": 0.02, "charisma": 0.01},
			"stress_rate": 0.3,
			"description": "教導學生課業，提升教學和溝通能力。",
		},
		"pt_tutor_senior": {
			"id": "pt_tutor_senior",
			"name": "補習班講師",
			"type": JobType.PART_TIME,
			"base_salary": 2500.0,
			"requirements": {"教學": 2, "intelligence": 20},
			"experience_needed": 80.0,
			"next_job": "",
			"skill_gains": {"教學": 0.04, "溝通": 0.03},
			"stat_gains": {"intelligence": 0.03, "charisma": 0.02},
			"stress_rate": 0.6,
			"description": "在補習班授課，面對更多學生。",
		},
		"pt_delivery": {
			"id": "pt_delivery",
			"name": "外送員",
			"type": JobType.PART_TIME,
			"base_salary": 1000.0,
			"requirements": {},
			"experience_needed": 20.0,
			"next_job": "",
			"skill_gains": {"服務": 0.01},
			"stat_gains": {"stamina": 0.03},
			"stress_rate": 0.7,
			"description": "騎車送餐，鍛鍊體力但壓力較大。",
		},

		# ===== 正職 (Full-time) =====
		"ft_office_junior": {
			"id": "ft_office_junior",
			"name": "初級辦公室職員",
			"type": JobType.FULL_TIME,
			"base_salary": 3000.0,
			"requirements": {"溝通": 1},
			"experience_needed": 60.0,
			"next_job": "ft_office_senior",
			"skill_gains": {"辦公": 0.03, "溝通": 0.02, "管理": 0.01},
			"stat_gains": {"intelligence": 0.01, "charisma": 0.01},
			"stress_rate": 1.0,
			"description": "一般辦公室工作，穩定但成長有限。",
		},
		"ft_office_senior": {
			"id": "ft_office_senior",
			"name": "資深辦公室職員",
			"type": JobType.FULL_TIME,
			"base_salary": 4500.0,
			"requirements": {"辦公": 2, "溝通": 2},
			"experience_needed": 100.0,
			"next_job": "mg_team_lead",
			"skill_gains": {"辦公": 0.04, "管理": 0.02},
			"stat_gains": {"intelligence": 0.02, "leadership": 0.01},
			"stress_rate": 1.2,
			"description": "資深職員，開始承擔更多責任。",
		},
		"ft_programmer_junior": {
			"id": "ft_programmer_junior",
			"name": "初級工程師",
			"type": JobType.FULL_TIME,
			"base_salary": 4000.0,
			"requirements": {"intelligence": 15},
			"experience_needed": 80.0,
			"next_job": "ft_programmer_senior",
			"skill_gains": {"程式設計": 0.04, "邏輯思維": 0.02},
			"stat_gains": {"intelligence": 0.03, "creativity": 0.01},
			"stress_rate": 1.5,
			"description": "寫程式的碼農生活，高薪但壓力大。",
		},
		"ft_programmer_senior": {
			"id": "ft_programmer_senior",
			"name": "資深工程師",
			"type": JobType.FULL_TIME,
			"base_salary": 7000.0,
			"requirements": {"程式設計": 3, "intelligence": 25},
			"experience_needed": 150.0,
			"next_job": "mg_tech_lead",
			"skill_gains": {"程式設計": 0.05, "邏輯思維": 0.03, "管理": 0.01},
			"stat_gains": {"intelligence": 0.04, "leadership": 0.01},
			"stress_rate": 1.8,
			"description": "資深工程師，技術與管理的橋梁。",
		},
		"ft_sales": {
			"id": "ft_sales",
			"name": "業務專員",
			"type": JobType.FULL_TIME,
			"base_salary": 3500.0,
			"requirements": {"charisma": 15},
			"experience_needed": 60.0,
			"next_job": "ft_sales_senior",
			"skill_gains": {"銷售": 0.04, "溝通": 0.03, "談判": 0.02},
			"stat_gains": {"charisma": 0.03, "stamina": 0.01},
			"stress_rate": 1.5,
			"description": "跑業務拉客戶，底薪加提成。",
		},
		"ft_sales_senior": {
			"id": "ft_sales_senior",
			"name": "資深業務",
			"type": JobType.FULL_TIME,
			"base_salary": 6000.0,
			"requirements": {"銷售": 3, "charisma": 25},
			"experience_needed": 120.0,
			"next_job": "mg_sales_manager",
			"skill_gains": {"銷售": 0.05, "談判": 0.03, "管理": 0.02},
			"stat_gains": {"charisma": 0.04, "leadership": 0.02},
			"stress_rate": 1.8,
			"description": "頂尖業務，準備走向管理層。",
		},

		# ===== 管理層 (Management) =====
		"mg_team_lead": {
			"id": "mg_team_lead",
			"name": "組長",
			"type": JobType.MANAGEMENT,
			"base_salary": 6000.0,
			"requirements": {"管理": 2, "leadership": 15},
			"experience_needed": 150.0,
			"next_job": "mg_department_manager",
			"skill_gains": {"管理": 0.04, "領導": 0.03},
			"stat_gains": {"leadership": 0.03, "charisma": 0.02},
			"stress_rate": 2.0,
			"description": "帶領小團隊，初嚐管理滋味。",
		},
		"mg_tech_lead": {
			"id": "mg_tech_lead",
			"name": "技術主管",
			"type": JobType.MANAGEMENT,
			"base_salary": 9000.0,
			"requirements": {"程式設計": 5, "管理": 2, "leadership": 15},
			"experience_needed": 200.0,
			"next_job": "mg_department_manager",
			"skill_gains": {"程式設計": 0.03, "管理": 0.04, "領導": 0.03},
			"stat_gains": {"intelligence": 0.03, "leadership": 0.03},
			"stress_rate": 2.2,
			"description": "技術團隊的領導者。",
		},
		"mg_sales_manager": {
			"id": "mg_sales_manager",
			"name": "業務經理",
			"type": JobType.MANAGEMENT,
			"base_salary": 8000.0,
			"requirements": {"銷售": 5, "管理": 2, "leadership": 15},
			"experience_needed": 180.0,
			"next_job": "mg_department_manager",
			"skill_gains": {"銷售": 0.03, "管理": 0.04, "領導": 0.03},
			"stat_gains": {"charisma": 0.03, "leadership": 0.03},
			"stress_rate": 2.0,
			"description": "帶領業務團隊衝業績。",
		},
		"mg_department_manager": {
			"id": "mg_department_manager",
			"name": "部門經理",
			"type": JobType.MANAGEMENT,
			"base_salary": 12000.0,
			"requirements": {"管理": 5, "leadership": 25},
			"experience_needed": 300.0,
			"next_job": "ex_director",
			"skill_gains": {"管理": 0.05, "領導": 0.04, "策略": 0.02},
			"stat_gains": {"leadership": 0.04, "intelligence": 0.02},
			"stress_rate": 2.5,
			"description": "管理整個部門，責任重大。",
		},

		# ===== 高管 (Executive) =====
		"ex_director": {
			"id": "ex_director",
			"name": "總監",
			"type": JobType.EXECUTIVE,
			"base_salary": 18000.0,
			"requirements": {"管理": 8, "領導": 5, "leadership": 35},
			"experience_needed": 500.0,
			"next_job": "ex_vp",
			"skill_gains": {"管理": 0.05, "領導": 0.05, "策略": 0.04},
			"stat_gains": {"leadership": 0.05, "intelligence": 0.03},
			"stress_rate": 3.0,
			"description": "高階管理，為創業鋪路。",
		},
		"ex_vp": {
			"id": "ex_vp",
			"name": "副總裁",
			"type": JobType.EXECUTIVE,
			"base_salary": 30000.0,
			"requirements": {"管理": 10, "領導": 8, "策略": 5, "leadership": 45},
			"experience_needed": 800.0,
			"next_job": "",
			"skill_gains": {"管理": 0.05, "領導": 0.05, "策略": 0.05},
			"stat_gains": {"leadership": 0.05, "intelligence": 0.03, "charisma": 0.03},
			"stress_rate": 3.5,
			"description": "企業高層，擁有豐富的經營經驗。",
		},
	}

static func get_available_jobs(character: CharacterData) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var all_jobs := get_all_jobs()

	for job_id in all_jobs:
		var job: Dictionary = all_jobs[job_id]
		if _meets_requirements(character, job):
			available.append(job)

	return available

static func _meets_requirements(character: CharacterData, job: Dictionary) -> bool:
	var reqs: Dictionary = job.get("requirements", {})
	for req_key in reqs:
		var req_value: float = reqs[req_key]
		# 檢查是否為屬性或技能
		if req_key in ["intelligence", "charisma", "stamina", "luck", "leadership", "creativity"]:
			if character.get_effective_stat(req_key) < req_value:
				return false
		else:
			if character.get_skill_level(req_key) < int(req_value):
				return false
	return true

static func get_job_by_id(job_id: String) -> Dictionary:
	var all_jobs := get_all_jobs()
	return all_jobs.get(job_id, {})

static func get_job_type_name(job_type: JobType) -> String:
	match job_type:
		JobType.PART_TIME: return "打工"
		JobType.FULL_TIME: return "正職"
		JobType.MANAGEMENT: return "管理層"
		JobType.EXECUTIVE: return "高管"
		_: return "未知"
