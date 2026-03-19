extends SceneTree
## 單元測試腳本
## 用法: godot --headless --script res://tests/test_runner.gd

var _pass_count: int = 0
var _fail_count: int = 0
var _current_test: String = ""

func _init() -> void:
	print("\n========================================")
	print("  人生模擬器 - 單元測試")
	print("========================================\n")

	# 等待 autoloads 初始化
	await process_frame
	await process_frame

	test_character_data()
	test_job_database()
	test_company_database()
	test_time_manager()
	test_game_manager_new_game()
	test_job_system()
	test_company_system()
	test_education_system()
	test_relationship_system()
	test_prestige_system()
	test_save_manager()
	test_money_format()

	print("\n========================================")
	print("  結果: %d 通過, %d 失敗" % [_pass_count, _fail_count])
	print("========================================\n")

	if _fail_count > 0:
		quit(1)
	else:
		quit(0)

# ===== 斷言工具 =====

func assert_eq(a, b, msg: String = "") -> void:
	if a == b:
		_pass_count += 1
	else:
		_fail_count += 1
		var desc := msg if msg != "" else ""
		print("  FAIL [%s] %s: %s != %s" % [_current_test, desc, str(a), str(b)])

func assert_true(condition: bool, msg: String = "") -> void:
	if condition:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s] %s: expected true" % [_current_test, msg])

func assert_false(condition: bool, msg: String = "") -> void:
	assert_true(not condition, msg)

func assert_gt(a: float, b: float, msg: String = "") -> void:
	if a > b:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s] %s: %s not > %s" % [_current_test, msg, str(a), str(b)])

func assert_gte(a: float, b: float, msg: String = "") -> void:
	if a >= b:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s] %s: %s not >= %s" % [_current_test, msg, str(a), str(b)])

func assert_lt(a: float, b: float, msg: String = "") -> void:
	if a < b:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s] %s: %s not < %s" % [_current_test, msg, str(a), str(b)])

func begin_test(name: String) -> void:
	_current_test = name
	print("TEST: %s" % name)

# ===== CharacterData =====

func test_character_data() -> void:
	begin_test("CharacterData 基本屬性")

	var c := CharacterData.new()
	assert_eq(c.character_name, "", "預設名稱為空")
	assert_eq(c.gender, CharacterData.Gender.MALE, "預設性別為男")
	assert_eq(c.money, 5000.0, "初始金錢 5000")
	assert_eq(c.intelligence, 10.0, "初始智力 10")
	assert_eq(c.happiness, 50.0, "初始幸福 50")
	assert_eq(c.health, 100.0, "初始健康 100")
	assert_eq(c.prestige_count, 0, "初始轉生次數 0")

	# 測試 get_effective_stat
	c.intelligence = 20.0
	c.prestige_bonuses["intelligence_bonus"] = 5.0
	assert_eq(c.get_effective_stat("intelligence"), 25.0, "有效智力 = 20 + 5")

	# 測試 add_money
	c.money = 1000.0
	c.total_earned = 0.0
	c.add_money(500.0)
	assert_eq(c.money, 1500.0, "加錢後餘額")
	assert_eq(c.total_earned, 500.0, "total_earned 增加")

	c.add_money(-200.0)
	assert_eq(c.money, 1300.0, "扣錢後餘額")
	assert_eq(c.total_earned, 500.0, "扣錢不影響 total_earned")

	# 測試 skill 系統
	c.add_skill_exp("程式設計", 1.5)
	assert_eq(c.get_skill_level("程式設計"), 1, "技能等級 = floor(1.5) = 1")
	c.add_skill_exp("程式設計", 1.5)
	assert_eq(c.get_skill_level("程式設計"), 3, "技能等級 = floor(3.0) = 3")
	assert_eq(c.get_skill_level("不存在"), 0, "不存在的技能 = 0")

	# 測試 get_total_stats
	c.intelligence = 10.0
	c.charisma = 10.0
	c.stamina = 10.0
	c.luck = 10.0
	c.leadership = 5.0
	c.creativity = 5.0
	assert_eq(c.get_total_stats(), 50.0, "總屬性加總")

	# 測試 prestige exp multiplier
	c.prestige_bonuses["exp_multiplier"] = 2.0
	c.skills = {}  # 清空技能
	c.add_skill_exp("測試", 1.0)
	assert_eq(c.skills.get("測試", 0.0), 2.0, "exp_multiplier 生效")

	# 測試 save/load
	c.character_name = "測試角色"
	c.gender = CharacterData.Gender.FEMALE
	var saved := c.get_save_data()
	var c2 := CharacterData.new()
	c2.load_save_data(saved)
	assert_eq(c2.character_name, "測試角色", "存讀名稱")
	assert_eq(c2.gender, CharacterData.Gender.FEMALE, "存讀性別")

# ===== JobDatabase =====

func test_job_database() -> void:
	begin_test("JobDatabase 工作資料庫")

	var all_jobs := JobDatabase.get_all_jobs()
	assert_gt(float(all_jobs.size()), 0.0, "有工作資料")

	# 測試取得特定工作
	var job := JobDatabase.get_job_by_id("pt_convenience")
	assert_eq(job.get("name", ""), "便利商店店員", "便利商店工作名稱")
	assert_gt(job.get("base_salary", 0.0), 0.0, "有薪水")

	# 測試不存在的工作
	var no_job := JobDatabase.get_job_by_id("不存在")
	assert_true(no_job.is_empty(), "不存在的工作回傳空")

	# 測試新角色可用工作（應該有無需求的工作）
	var c := CharacterData.new()
	var available := JobDatabase.get_available_jobs(c)
	assert_gt(float(available.size()), 0.0, "新角色有可用工作")

	# 確認便利商店和外送員不需要任何需求
	var has_convenience := false
	var has_delivery := false
	for j in available:
		if j["id"] == "pt_convenience":
			has_convenience = true
		if j["id"] == "pt_delivery":
			has_delivery = true
	assert_true(has_convenience, "便利商店對新角色可用")
	assert_true(has_delivery, "外送員對新角色可用")

	# 測試高需求工作不對新角色開放
	var vp_job := JobDatabase.get_job_by_id("ex_vp")
	assert_false(JobDatabase._meets_requirements(c, vp_job), "副總裁對新角色不可用")

	# 測試 type name
	assert_eq(JobDatabase.get_job_type_name(JobDatabase.JobType.PART_TIME), "打工", "打工類型名")
	assert_eq(JobDatabase.get_job_type_name(JobDatabase.JobType.EXECUTIVE), "高管", "高管類型名")

# ===== CompanyDatabase =====

func test_company_database() -> void:
	begin_test("CompanyDatabase 公司資料庫")

	# 測試創業選項
	var options := CompanyDatabase.get_startup_options()
	assert_gt(float(options.size()), 0.0, "有創業選項")

	# 測試建立公司
	var option := options[0]
	var company := CompanyDatabase.create_new_company(option)
	assert_true(company.has("name"), "公司有名稱")
	assert_true(company.has("base_revenue_per_day"), "公司有基礎日營收")
	assert_true(company.has("revenue_per_day"), "公司有日營收")
	assert_eq(company["tier"], CompanyDatabase.CompanyTier.MICRO, "新公司是微型")
	assert_eq(company["employees"], 0, "新公司無員工")
	assert_eq(company["branches"], 1, "新公司1間店")

	# 測試 tier 名稱
	assert_eq(CompanyDatabase.get_tier_name(CompanyDatabase.CompanyTier.MICRO), "個人工作室", "微型名稱")
	assert_eq(CompanyDatabase.get_tier_name(CompanyDatabase.CompanyTier.CONGLOMERATE), "跨國集團", "跨國名稱")

	# 測試升級需求
	var reqs := CompanyDatabase.get_tier_requirements(CompanyDatabase.CompanyTier.SMALL)
	assert_true(reqs.has("upgrade_cost"), "有升級費用")
	assert_gt(reqs.get("upgrade_cost", 0.0), 0.0, "升級費用 > 0")

# ===== TimeManager =====

func test_time_manager() -> void:
	begin_test("TimeManager 時間管理")

	# 測試初始狀態
	assert_eq(TimeManager.current_year, 2026, "初始年 2026")
	assert_eq(TimeManager.current_month, 6, "初始月 6")
	assert_eq(TimeManager.current_day, 1, "初始日 1")

	# 測試日期字串
	var date_str := TimeManager.get_date_string()
	assert_true(date_str.contains("2026"), "日期包含年份")

	# 測試速度切換
	TimeManager.current_speed_index = 1
	TimeManager.game_speed = TimeManager.speed_multipliers[1]
	TimeManager.cycle_speed()
	assert_eq(TimeManager.current_speed_index, 2, "速度切換")
	assert_eq(TimeManager.game_speed, TimeManager.speed_multipliers[2], "速度值更新")

	# 測試暫停
	TimeManager.toggle_pause()
	assert_true(TimeManager.is_paused, "已暫停")
	assert_eq(TimeManager.get_speed_text(), "暫停", "暫停文字")
	TimeManager.toggle_pause()
	assert_false(TimeManager.is_paused, "已恢復")

	# 測試 save/load
	TimeManager.current_year = 2030
	TimeManager.current_month = 3
	TimeManager.current_day = 15
	TimeManager.total_days_played = 500
	var saved := TimeManager.get_save_data()
	TimeManager.current_year = 2026
	TimeManager.current_month = 6
	TimeManager.current_day = 1
	TimeManager.total_days_played = 0
	TimeManager.load_save_data(saved)
	assert_eq(TimeManager.current_year, 2030, "讀取年份")
	assert_eq(TimeManager.current_month, 3, "讀取月份")
	assert_eq(TimeManager.total_days_played, 500, "讀取天數")

	# 重置到初始狀態
	TimeManager.current_year = 2026
	TimeManager.current_month = 6
	TimeManager.current_day = 1
	TimeManager.total_days_played = 0
	TimeManager.current_speed_index = 1
	TimeManager.game_speed = TimeManager.speed_multipliers[1]
	TimeManager.is_paused = false

# ===== GameManager =====

func test_game_manager_new_game() -> void:
	begin_test("GameManager 新遊戲")

	# 開始新遊戲
	GameManager.start_new_game("測試玩家", CharacterData.Gender.FEMALE)
	assert_true(GameManager.is_game_started, "遊戲已開始")
	assert_eq(GameManager.character.character_name, "測試玩家", "角色名稱")
	assert_eq(GameManager.character.gender, CharacterData.Gender.FEMALE, "角色性別")
	assert_eq(GameManager.character.birth_year, 2026 - 22, "出生年份")

	# 測試 reset_all
	GameManager.character.money = 99999.0
	GameManager.character.intelligence = 50.0
	GameManager.reset_all()
	assert_false(GameManager.is_game_started, "重置後遊戲未開始")
	assert_eq(GameManager.character.money, 5000.0, "重置後金錢回到初始")
	assert_eq(GameManager.character.intelligence, 10.0, "重置後智力回到初始")

	# 測試帶轉生開新遊戲
	var bonuses := {
		"prestige_count": 3,
		"intelligence_bonus": 5.0,
		"starting_money_bonus": 10000.0,
		"exp_multiplier": 1.3,
	}
	GameManager.start_new_game_with_prestige("轉生角色", CharacterData.Gender.MALE, bonuses)
	assert_eq(GameManager.character.prestige_count, 3, "轉生次數")
	assert_eq(GameManager.character.money, 15000.0, "初始金錢 + 轉生加成")
	assert_eq(GameManager.character.prestige_bonuses.get("exp_multiplier", 1.0), 1.3, "經驗倍率")

	# 測試 format_money
	assert_eq(GameManager.format_money(500), "$500", "格式化: $500")
	assert_eq(GameManager.format_money(15000), "1.5萬", "格式化: 1.5萬")
	assert_eq(GameManager.format_money(12345678), "1235萬", "格式化: 大數字萬")
	assert_eq(GameManager.format_money(1500000000), "15.00億", "格式化: 億")

	# 清理
	GameManager.reset_all()

func test_money_format() -> void:
	begin_test("GameManager format_money 邊界測試")
	assert_eq(GameManager.format_money(0), "$0", "0元")
	assert_eq(GameManager.format_money(-500), "$-500", "負數")
	assert_eq(GameManager.format_money(9999), "$9999", "接近萬")
	assert_eq(GameManager.format_money(10000), "1.0萬", "剛好萬")
	assert_eq(GameManager.format_money(10000000), "1000萬", "剛好千萬")
	assert_eq(GameManager.format_money(100000000), "1.00億", "剛好億")

# ===== JobSystem =====

func test_job_system() -> void:
	begin_test("JobSystem 工作系統")

	GameManager.start_new_game("工作測試", CharacterData.Gender.MALE)
	var js := GameManager.job_system
	var c := GameManager.character

	# 測試應徵工作
	assert_true(c.current_job.is_empty(), "初始無工作")
	var result := js.apply_for_job("pt_convenience")
	assert_true(result, "便利商店應徵成功")
	assert_false(c.current_job.is_empty(), "有工作了")
	assert_eq(c.current_job.get("name", ""), "便利商店店員", "工作名稱")

	# 測試升遷進度
	assert_eq(js.get_promotion_progress(), 0.0, "初始升遷進度 0")

	# 測試不夠經驗升遷
	assert_false(js.try_promote(), "經驗不足升遷失敗")

	# 測試辭職
	js.quit_job()
	assert_true(c.current_job.is_empty(), "辭職後無工作")

	# 測試應徵需要條件的工作（應失敗）
	var result2 := js.apply_for_job("ft_programmer_senior")
	assert_false(result2, "資深工程師需求不足")

	# 測試 reset
	js.apply_for_job("pt_convenience")
	js.reset()
	assert_eq(js._work_experience_accumulated, 0.0, "重置後經驗歸零")
	assert_eq(js._days_worked, 0, "重置後天數歸零")

	GameManager.reset_all()

# ===== CompanySystem =====

func test_company_system() -> void:
	begin_test("CompanySystem 公司系統")

	GameManager.start_new_game("公司測試", CharacterData.Gender.MALE)
	var cs := GameManager.company_system
	var c := GameManager.character

	# 新角色不能直接創業（技能不足）
	var options := CompanyDatabase.get_startup_options()
	var food_option: Dictionary = {}
	for opt in options:
		if opt["type"] == CompanyDatabase.BusinessType.FOOD:
			food_option = opt
			break

	# 先給足夠技能和錢
	c.money = 100000.0
	c.skills["服務"] = 5.0
	c.skills["程式設計"] = 5.0

	assert_false(c.has_company, "初始無公司")

	var result := cs.found_company(food_option)
	assert_true(result, "小吃攤創業成功")
	assert_true(c.has_company, "有公司了")
	assert_eq(c.company.get("name", ""), "小吃攤", "公司名稱")
	assert_lt(c.money, 100000.0, "扣了創業費用")

	# 測試僱用員工
	var money_before := c.money
	var hire_result := cs.hire_employee()
	assert_true(hire_result, "僱用成功")
	assert_eq(c.company["employees"], 1, "1個員工")
	assert_lt(c.money, money_before, "扣了僱用費用")

	# 測試 base_revenue 不被 _recalculate_revenue 覆蓋
	var base_rev: float = c.company["base_revenue_per_day"]
	cs._recalculate_revenue()
	assert_eq(c.company["base_revenue_per_day"], base_rev, "base_revenue 不變")
	var rev_after_first: float = c.company["revenue_per_day"]
	cs._recalculate_revenue()
	# 呼叫兩次結果應相同（修復前會複利）
	assert_eq(c.company["revenue_per_day"], rev_after_first, "重算營收結果穩定")

	# 測試日利潤
	var profit := cs.get_daily_profit()
	assert_gt(profit, 0.0, "日利潤 > 0")

	# 測試開分店
	var branch_result := cs.open_branch()
	assert_true(branch_result, "開分店成功")
	assert_eq(c.company["branches"], 2, "2間店")

	GameManager.reset_all()

# ===== EducationSystem =====

func test_education_system() -> void:
	begin_test("EducationSystem 教育系統")

	GameManager.start_new_game("教育測試", CharacterData.Gender.FEMALE)
	var es := GameManager.education_system
	var c := GameManager.character

	assert_false(c.has_masters, "初始無碩士")
	assert_false(c.is_studying, "初始未進修")

	# 錢不夠不能讀
	c.money = 100.0
	assert_false(es.start_masters(), "資金不足")

	# 有錢可以讀
	c.money = 50000.0
	assert_true(es.start_masters(), "開始碩士")
	assert_true(c.is_studying, "進修中")
	assert_lt(c.money, 50000.0, "扣了學費")

	# 不能同時讀兩個
	assert_false(es.start_masters(), "不能同時讀兩個")

	# 測試退學
	es.drop_out()
	assert_false(c.is_studying, "退學後不再進修")
	assert_eq(c.study_progress, 0.0, "退學後進度歸零")

	# 測試 reset
	es.reset()
	assert_eq(es._study_days, 0, "重置後學習天數歸零")

	GameManager.reset_all()

# ===== RelationshipSystem =====

func test_relationship_system() -> void:
	begin_test("RelationshipSystem 感情系統")

	GameManager.start_new_game("感情測試", CharacterData.Gender.MALE)
	var rs := GameManager.relationship_system
	var c := GameManager.character

	assert_eq(c.relationship_status, "single", "初始單身")
	assert_true(c.partner.is_empty(), "無伴侶")
	assert_true(c.children.is_empty(), "無小孩")

	# 求婚前要先交往
	assert_false(rs.try_propose(), "單身不能求婚")

	# 生小孩要先結婚
	assert_false(rs.try_have_child(), "未婚不能生小孩")

	# 模擬交往
	c.relationship_status = "dating"
	c.partner = {"name": "測試伴侶", "affection": 50.0, "days_together": 0}

	# 好感不夠不能求婚
	assert_false(rs.try_propose(), "好感不足")

	# 好感夠 + 有錢可以求婚
	c.partner["affection"] = 90.0
	c.money = 50000.0
	assert_true(rs.try_propose(), "求婚成功")
	assert_eq(c.relationship_status, "married", "已婚")

	# 結婚後可以嘗試生小孩
	# （因為隨機性，可能成功也可能失敗，只測試不會出錯）
	var initial_children := c.children.size()
	rs.try_have_child()
	assert_gte(float(c.children.size()), float(initial_children), "子女數不減少")

	# 測試 reset
	rs.reset()
	assert_eq(rs._dating_days, 0, "重置後約會天數歸零")

	GameManager.reset_all()

# ===== PrestigeSystem =====

func test_prestige_system() -> void:
	begin_test("PrestigeSystem 轉生系統")

	GameManager.start_new_game("轉生測試", CharacterData.Gender.MALE)
	var ps := GameManager.prestige_system
	var c := GameManager.character

	# 新角色不能轉生
	assert_false(ps.can_prestige(), "新角色不能轉生")

	# 描述應包含條件不足訊息
	var desc := ps.get_prestige_description()
	assert_true(desc.contains("不足"), "描述包含條件不足")

	# 設定符合條件的狀態
	TimeManager.current_year = 2070  # 年齡 = 44歲
	c.total_earned = 200000.0

	assert_true(ps.can_prestige(), "符合條件可轉生")

	# 取得轉生資訊
	var info := ps.get_prestige_info()
	assert_eq(info["prestige_count"], 1, "第1次轉生")
	assert_gt(info.get("exp_multiplier", 0.0), 1.0, "經驗倍率 > 1")
	assert_gt(info.get("starting_money_bonus", 0.0), 0.0, "有初始資金加成")

	# 重置
	TimeManager.current_year = 2026
	TimeManager.current_month = 6
	TimeManager.current_day = 1
	TimeManager.total_days_played = 0
	GameManager.reset_all()

# ===== SaveManager =====

func test_save_manager() -> void:
	begin_test("SaveManager 存檔管理")

	GameManager.start_new_game("存檔測試", CharacterData.Gender.FEMALE)
	GameManager.character.money = 12345.0
	GameManager.character.intelligence = 30.0

	# 儲存
	SaveManager.save_game()
	assert_true(SaveManager.has_save(), "存檔存在")

	# 修改後讀取
	GameManager.character.money = 0.0
	GameManager.character.intelligence = 0.0
	var loaded := SaveManager.load_game()
	assert_true(loaded, "讀取成功")
	assert_eq(GameManager.character.money, 12345.0, "金錢還原")
	assert_eq(GameManager.character.intelligence, 30.0, "智力還原")

	# 刪除存檔
	SaveManager.delete_save()
	assert_false(SaveManager.has_save(), "存檔已刪除")

	# 轉生資料
	var prestige_data := {"prestige_count": 2, "exp_multiplier": 1.2}
	SaveManager.save_prestige_data(prestige_data)
	var loaded_prestige := SaveManager.load_prestige_data()
	assert_eq(loaded_prestige.get("prestige_count", 0), 2, "轉生次數還原")

	GameManager.reset_all()
