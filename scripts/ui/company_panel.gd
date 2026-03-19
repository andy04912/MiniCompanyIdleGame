extends VBoxContainer
## 公司經營面板

@onready var no_company_container: VBoxContainer = %NoCompanyContainer
@onready var company_container: VBoxContainer = %CompanyContainer
@onready var startup_list: VBoxContainer = %StartupList

# 公司資訊
@onready var company_name_label: Label = %CompanyNameLabel
@onready var company_tier_label: Label = %CompanyTierLabel
@onready var revenue_label: Label = %RevenueLabel
@onready var expenses_label: Label = %ExpensesLabel
@onready var profit_label: Label = %ProfitLabel
@onready var employees_label: Label = %EmployeesLabel
@onready var branches_label: Label = %BranchesLabel
@onready var quality_label: Label = %QualityLabel
@onready var reputation_label: Label = %ReputationLabel

# 操作按鈕
@onready var hire_button: Button = %HireButton
@onready var upgrade_button: Button = %UpgradeButton
@onready var branch_button: Button = %BranchButton
@onready var marketing_button: Button = %MarketingButton
@onready var improve_button: Button = %ImproveButton

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.company_founded.connect(_on_company_founded)

	hire_button.pressed.connect(func(): GameManager.company_system.hire_employee(); _update_display())
	upgrade_button.pressed.connect(func(): GameManager.company_system.upgrade_company(); _update_display())
	branch_button.pressed.connect(func(): GameManager.company_system.open_branch(); _update_display())
	marketing_button.pressed.connect(func(): GameManager.company_system.invest_marketing(); _update_display())
	improve_button.pressed.connect(func(): GameManager.company_system.improve_product(); _update_display())

	_update_display()

func _on_day_passed(_day: int) -> void:
	if _day % 5 == 0:
		_update_display()

func _on_company_founded(_data: Dictionary) -> void:
	_update_display()

func _update_display() -> void:
	var c := GameManager.character

	if not c.has_company:
		no_company_container.visible = true
		company_container.visible = false
		_refresh_startup_list()
	else:
		no_company_container.visible = false
		company_container.visible = true
		_update_company_info()

func _refresh_startup_list() -> void:
	for child in startup_list.get_children():
		child.queue_free()

	var options := CompanyDatabase.get_startup_options()
	for option in options:
		var hbox := HBoxContainer.new()

		var info := Label.new()
		info.text = "%s - 創業資金: %s" % [option["name"], GameManager.format_money(option["cost"])]
		info.tooltip_text = option.get("description", "")
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info)

		var btn := Button.new()
		btn.text = "創業"
		btn.pressed.connect(_on_found_company.bind(option))
		hbox.add_child(btn)

		startup_list.add_child(hbox)

func _update_company_info() -> void:
	var company: Dictionary = GameManager.character.company

	var type_name := CompanyDatabase.get_business_type_name(company.get("business_type", 0) as CompanyDatabase.BusinessType)
	company_name_label.text = "%s（%s）" % [company.get("name", ""), type_name]

	var tier_name := CompanyDatabase.get_tier_name(company.get("tier", 0) as CompanyDatabase.CompanyTier)
	company_tier_label.text = "規模: %s" % tier_name

	var daily_revenue: float = company.get("revenue_per_day", 0.0)
	var daily_expenses: float = company.get("expenses_per_day", 0.0)
	var daily_profit := daily_revenue - daily_expenses

	revenue_label.text = "日營收: %s" % GameManager.format_money(daily_revenue)
	expenses_label.text = "日支出: %s" % GameManager.format_money(daily_expenses)
	profit_label.text = "日利潤: %s" % GameManager.format_money(daily_profit)

	if daily_profit >= 0:
		profit_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		profit_label.add_theme_color_override("font_color", Color.RED)

	employees_label.text = "員工: %d / %d" % [company.get("employees", 0), company.get("max_employees", 3)]
	branches_label.text = "分店: %d" % company.get("branches", 1)
	quality_label.text = "品質: %.0f" % company.get("product_quality", 10.0)
	reputation_label.text = "信譽: %.0f" % company.get("reputation", 10.0)

func _on_found_company(option: Dictionary) -> void:
	GameManager.company_system.found_company(option)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_update_display()
