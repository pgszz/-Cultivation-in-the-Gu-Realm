class_name CharacterUI
extends Control

var player: Player
var game: Node
var selected_slot_index := 0
var overview: RichTextLabel
var attributes: RichTextLabel

func _ready() -> void:
	var cols:=HBoxContainer.new()
	UIStyle.fill(cols)
	cols.add_theme_constant_override("separation",18)
	add_child(cols)
	var left:=UIStyle.card(cols,280)
	left.add_child(UIStyle.label("蛊师 · 身体与身份",23,UIStyle.GOLD))
	overview=UIStyle.rich(18)
	left.add_child(overview)
	left.add_child(UIStyle.button("内视空窍与元海 · Q →",func(): game.open_journal("aperture")))
	left.add_child(UIStyle.button("查看随身物品 · I →",func(): game.open_journal("inventory")))
	left.add_child(UIStyle.button("检查身体伤势 · B →",func(): game.open_journal("body")))
	var right:=UIStyle.card(cols,340)
	right.add_child(UIStyle.label("实际行动能力",23,UIStyle.GOLD))
	attributes=UIStyle.rich(17)
	right.add_child(attributes)
	visibility_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if overview==null or player==null: return
	var b:=player.body
	overview.text="[color=#d8bc7c]%s[/color]\n%s资质 · 元海上限 %.0f%%\n\n气血 %.0f / %.0f\n\n随身元石 %d\n外部未炼化蛊 %d\n\n当前为青茅山前期的无名蛊师。\n角色不是方源，不自带春秋蝉或他的传承。" % [player.aperture.realm(),player.aperture.aptitude(),player.max_yuan,player.hp,player.max_hp,player.crystals,player.captured.size()]
	attributes.text="徒手攻击 %.1f\n移动速度 %.0f\n攻击速度 %.0f%%\n精准度 %.0f%%\n视野半径 %.0f\n\n疾步：%s\n催蛊：%s\n\n[color=#93a99f]升转改变真元品质，不自动增加肉身攻击、防御或修复伤势。口手受伤也不是所有蛊虫的通用禁用条件。[/color]" % [player.atk+player.atk_bonus,(player.speed+player.spd_bonus)*b.get_move_multiplier(),b.get_attack_speed_multiplier()*100,b.get_accuracy()*100,game.fog.radius_world(),"可用" if b.can_dash() else "腿伤受限","可用" if b.can_cast() else "意识或生命状态受限"]

func select_gu(index: int) -> void:
	selected_slot_index=index
	var gu: GuVirtual=game.equipped_gu(index)
	if gu: game.aperture_ui.select_gu(gu.id)

func update_gu_slots() -> void:
	refresh()
