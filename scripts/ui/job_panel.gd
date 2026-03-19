extends VBoxContainer
## 工作面板

@onready var current_job_label: Label = %CurrentJobLabel
@onready var salary_label: Label = %SalaryLabel
@onready var performance_bar: ProgressBar = %PerformanceBar
@onready var promotion_bar: ProgressBar = %PromotionBar
@onready var promote_button: Button = %PromoteButton
@onready var quit_button: Button = %QuitButton
@onready var job_list: VBoxContainer = %JobList

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.job_started.connect(_on_job_changed)
	EventBus.job_quit.connect(_on_job_changed)
	EventBus.job_promoted.connect(_on_job_promoted)

	promote_button.pressed.connect(_on_promote_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_update_display()

func _on_day_passed(_day: int) -> void:
	if _day % 5 == 0:  # 每5天更新一次，減少效能消耗
		_update_display()

func _on_job_changed(_data = null) -> void:
	_update_display()
	_refresh_job_list()

func _on_job_promoted(_title: String) -> void:
	_update_display()
	_refresh_job_list()

func _update_display() -> void:
	var c := GameManager.character

	if c.current_job.is_empty():
		current_job_label.text = "目前無工作"
		salary_label.text = ""
		performance_bar.visible = false
		promotion_bar.visible = false
		promote_button.visible = false
		quit_button.visible = false
	else:
		var job: Dictionary = c.current_job
		var type_name := JobDatabase.get_job_type_name(job.get("type", 0) as JobDatabase.JobType)
		current_job_label.text = "【%s】%s" % [type_name, job.get("name", "")]
		salary_label.text = "月薪: %s" % GameManager.format_money(job.get("base_salary", 0))

		performance_bar.visible = true
		performance_bar.value = c.job_performance
		performance_bar.tooltip_text = "工作表現: %.0f%%" % c.job_performance

		promotion_bar.visible = true
		var promo_progress := GameManager.job_system.get_promotion_progress()
		promotion_bar.value = promo_progress
		promotion_bar.tooltip_text = "升遷進度: %.0f%%" % promo_progress

		promote_button.visible = job.get("next_job", "") != ""
		promote_button.disabled = promo_progress < 100.0
		quit_button.visible = true

func _refresh_job_list() -> void:
	for child in job_list.get_children():
		child.queue_free()

	var c := GameManager.character
	var available_jobs := JobDatabase.get_available_jobs(c)

	for job in available_jobs:
		# 不顯示當前工作
		if not c.current_job.is_empty() and job["id"] == c.current_job.get("id", ""):
			continue

		var hbox := HBoxContainer.new()

		var info_label := Label.new()
		var type_name := JobDatabase.get_job_type_name(job.get("type", 0) as JobDatabase.JobType)
		info_label.text = "[%s] %s - 月薪 %s" % [type_name, job["name"], GameManager.format_money(job["base_salary"])]
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.tooltip_text = job.get("description", "")
		hbox.add_child(info_label)

		var apply_btn := Button.new()
		apply_btn.text = "應徵"
		apply_btn.pressed.connect(_on_apply_job.bind(job["id"]))
		hbox.add_child(apply_btn)

		job_list.add_child(hbox)

func _on_apply_job(job_id: String) -> void:
	GameManager.job_system.apply_for_job(job_id)

func _on_promote_pressed() -> void:
	GameManager.job_system.try_promote()

func _on_quit_pressed() -> void:
	GameManager.job_system.quit_job()

# 當面板顯示時刷新工作列表
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_refresh_job_list()
