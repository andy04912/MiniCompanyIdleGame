class_name CompanyDatabase
extends RefCounted
## 公司/事業資料庫

enum CompanyTier {
	MICRO,       # 微型企業（個人工作室）
	SMALL,       # 小型公司
	MEDIUM,      # 中型公司
	LARGE,       # 大型公司
	CHAIN,       # 連鎖企業
	CORPORATION, # 企業集團
	CONGLOMERATE # 跨國集團
}

enum BusinessType {
	FOOD,        # 餐飲
	TECH,        # 科技
	RETAIL,      # 零售
	SERVICE,     # 服務業
	EDUCATION,   # 教育
}

static func get_tier_name(tier: CompanyTier) -> String:
	match tier:
		CompanyTier.MICRO: return "個人工作室"
		CompanyTier.SMALL: return "小型公司"
		CompanyTier.MEDIUM: return "中型公司"
		CompanyTier.LARGE: return "大型公司"
		CompanyTier.CHAIN: return "連鎖企業"
		CompanyTier.CORPORATION: return "企業集團"
		CompanyTier.CONGLOMERATE: return "跨國集團"
		_: return "未知"

static func get_business_type_name(btype: BusinessType) -> String:
	match btype:
		BusinessType.FOOD: return "餐飲業"
		BusinessType.TECH: return "科技業"
		BusinessType.RETAIL: return "零售業"
		BusinessType.SERVICE: return "服務業"
		BusinessType.EDUCATION: return "教育業"
		_: return "未知"

static func get_startup_options() -> Array[Dictionary]:
	return [
		{
			"type": BusinessType.FOOD,
			"name": "小吃攤",
			"cost": 5000.0,
			"base_revenue": 200.0,
			"requirements": {"服務": 2},
			"description": "從路邊攤開始你的餐飲帝國。",
		},
		{
			"type": BusinessType.TECH,
			"name": "接案工作室",
			"cost": 3000.0,
			"base_revenue": 300.0,
			"requirements": {"程式設計": 3},
			"description": "用你的技術能力接案賺錢。",
		},
		{
			"type": BusinessType.RETAIL,
			"name": "網路商店",
			"cost": 8000.0,
			"base_revenue": 250.0,
			"requirements": {"銷售": 2},
			"description": "在網路上開店賣東西。",
		},
		{
			"type": BusinessType.SERVICE,
			"name": "清潔公司",
			"cost": 4000.0,
			"base_revenue": 180.0,
			"requirements": {"管理": 1},
			"description": "提供清潔服務，門檻低但穩定。",
		},
		{
			"type": BusinessType.EDUCATION,
			"name": "補習班",
			"cost": 10000.0,
			"base_revenue": 350.0,
			"requirements": {"教學": 3, "intelligence": 20},
			"description": "開設自己的補習班。",
		},
	]

static func get_tier_requirements(tier: CompanyTier) -> Dictionary:
	match tier:
		CompanyTier.MICRO:
			return {"revenue": 0, "employees": 0, "branches": 0, "upgrade_cost": 0}
		CompanyTier.SMALL:
			return {"revenue": 3000, "employees": 5, "branches": 1, "upgrade_cost": 30000}
		CompanyTier.MEDIUM:
			return {"revenue": 15000, "employees": 20, "branches": 1, "upgrade_cost": 150000}
		CompanyTier.LARGE:
			return {"revenue": 80000, "employees": 100, "branches": 3, "upgrade_cost": 800000}
		CompanyTier.CHAIN:
			return {"revenue": 300000, "employees": 500, "branches": 10, "upgrade_cost": 3000000}
		CompanyTier.CORPORATION:
			return {"revenue": 1000000, "employees": 2000, "branches": 30, "upgrade_cost": 15000000}
		CompanyTier.CONGLOMERATE:
			return {"revenue": 5000000, "employees": 10000, "branches": 100, "upgrade_cost": 100000000}
		_:
			return {}

static func create_new_company(option: Dictionary) -> Dictionary:
	return {
		"name": option.get("name", "我的公司"),
		"business_type": option.get("type", BusinessType.SERVICE),
		"tier": CompanyTier.MICRO,
		"revenue_per_day": option.get("base_revenue", 100.0),
		"expenses_per_day": option.get("base_revenue", 100.0) * 0.3,
		"employees": 0,
		"max_employees": 3,
		"branches": 1,
		"reputation": 10.0,
		"product_quality": 10.0,
		"marketing_level": 0,
		"total_revenue": 0.0,
		"days_operated": 0,
	}
