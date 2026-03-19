class_name EventBus
extends Node
## 全域事件匯流排 - 用於解耦各系統之間的通訊

# 角色相關
signal character_created(data: Dictionary)
signal stat_changed(stat_name: String, old_value: float, new_value: float)
signal level_up(new_level: int)
signal age_changed(new_age: int)

# 金錢相關
signal money_changed(amount: float)
signal income_changed(amount: float)

# 工作相關
signal job_started(job_data: Dictionary)
signal job_quit()
signal job_promoted(new_title: String)
signal work_experience_gained(amount: float)

# 事業相關
signal company_founded(company_data: Dictionary)
signal company_upgraded(new_tier: String)
signal branch_opened(branch_count: int)
signal revenue_changed(amount: float)

# 教育相關
signal education_started(education_type: String)
signal education_completed(education_type: String)
signal skill_learned(skill_name: String, level: int)

# 關係相關
signal relationship_started(partner_data: Dictionary)
signal married()
signal child_born(child_data: Dictionary)

# 轉生相關
signal prestige_triggered(prestige_data: Dictionary)
signal rebirth_completed(bonuses: Dictionary)

# 遊戲狀態
signal game_saved()
signal game_loaded()
signal game_tick(delta: float)
signal day_passed(day: int)
signal month_passed(month: int)
signal year_passed(year: int)

# UI 相關
signal show_notification(message: String, type: String)
signal panel_switched(panel_name: String)
