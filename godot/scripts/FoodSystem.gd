class_name FoodSystem
extends Node

signal food_used(food_id: String, gu_id: String, restore_amount: float)
const GRAINS := {
	"iron_bone_care":{"name":"铁骨蛊专用供养（食材未核实，一日份）","restore":100.0,"type":"food","designed":true},
	"jade_bone_care":{"name":"玉骨蛊专用供养（食材未核实，一日份）","restore":100.0,"type":"food","designed":true},
	"vitality_leaf_care":{"name":"生机叶专用供养（食材未核实，一日份）","restore":100.0,"type":"food","designed":true},
	"self_reliance_care":{"name":"自力更生蛊专用供养（食材未核实，一日份）","restore":100.0,"type":"food","designed":true},
	"tempered_sinew_care":{"name":"锻筋金蚕蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"clot_thread_care":{"name":"凝血丝蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"numb_ant_care":{"name":"麻感蚁蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"lucid_larva_care":{"name":"醒神幼蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"sinew_spring_care":{"name":"弹筋蛐蛐蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"feather_marrow_care":{"name":"轻髓羽蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"ballast_bone_care":{"name":"沉骨甲蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"scar_crust_care":{"name":"护痂蜗蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"red_pulse_care":{"name":"赤脉蛭蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"lung_bell_care":{"name":"润肺铃蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"bitter_liver_care":{"name":"苦胆蝉蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"warm_muscle_care":{"name":"温肌绒蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"nerve_lantern_care":{"name":"通络灯蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"clear_cornea_care":{"name":"澄膜蜉蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"ear_suture_care":{"name":"缝耳蝠蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"joint_mender_care":{"name":"续节竹蛊专用调养料（原创，一日份）","restore":100.0,"type":"food","designed":true},
	"clear_origin_silkworm_care":{"name":"清源玉露（清源玉蚕蛊一日份）","restore":100.0,"type":"food","designed":true},
	"deep_spring_butterfly_care":{"name":"玄泉苔浆（玄泉蝶蛊一日份）","restore":100.0,"type":"food","designed":true},
	"marrow_lotus_beetle_care":{"name":"莲髓玉粉（洗髓莲甲蛊一日份）","restore":100.0,"type":"food","designed":true},
	"nine_aurora_cocoon_care":{"name":"九华花蜜（九华灵茧蛊一日份）","restore":100.0,"type":"food","designed":true},
	"bronze_relic_care":{"name":"青铜舍利蛊专用供养（食材未核实，一日份）","restore":100.0,"type":"food","designed":true},
	"red_iron_relic_care":{"name":"赤铁舍利蛊专用供养（食材未核实，一日份）","restore":100.0,"type":"food","designed":true},
	"silver_relic_care":{"name":"白银舍利蛊专用供养（食材未核实，一日份）","restore":100.0,"type":"food","designed":true},
	"gold_relic_care":{"name":"黄金舍利蛊专用供养（食材未核实，一日份）","restore":100.0,"type":"food","designed":true},
	"purple_relic_care":{"name":"紫晶舍利蛊专用供养（食材未核实，一日份）","restore":100.0,"type":"food","designed":true},
	"quiet_incense_moth_care":{"name":"静香草粉（静香蛾蛊一日份）","restore":100.0,"type":"food","designed":true},
	"wall_polish_snail_care":{"name":"磨壁矿乳（磨壁螺蛊一日份）","restore":100.0,"type":"food","designed":true},
	"copper_fletch_care":{"name":"铜翎矿粉（铜翎蛊一日份）","restore":100.0,"type":"food","designed":true},
	"sand_fang_care":{"name":"沙牙石髓（沙牙蛊一日份）","restore":100.0,"type":"food","designed":true},
	"rain_needle_care":{"name":"雨针水露（雨针蜓蛊一日份）","restore":100.0,"type":"food","designed":true},
	"obsidian_mantis_care":{"name":"玄刃铁砂（玄刃螳蛊一日份）","restore":100.0,"type":"food","designed":true},
	"storm_hornet_care":{"name":"暴岚花粉（暴岚蜂蛊一日份）","restore":100.0,"type":"food","designed":true},
	"sun_ember_scarab_care":{"name":"日烬炭蜜（日烬金龟蛊一日份）","restore":100.0,"type":"food","designed":true},
	"glacier_centipede_care":{"name":"冰魄寒髓（冰魄蜈蛊一日份）","restore":100.0,"type":"food","designed":true},
	"bark_bastion_care":{"name":"厚栎树脂（厚栎甲蛊一日份）","restore":100.0,"type":"food","designed":true},
	"quartz_tortoise_care":{"name":"晶垒石乳（晶垒蛊一日份）","restore":100.0,"type":"food","designed":true},
	"thunder_insulator_care":{"name":"绝雷绒苔（绝雷绒蛊一日份）","restore":100.0,"type":"food","designed":true},
	"basalt_heart_care":{"name":"玄岩矿髓（玄岩心蛊一日份）","restore":100.0,"type":"food","designed":true},
	"prism_aegis_care":{"name":"虹棱晶粉（虹棱甲蛊一日份）","restore":100.0,"type":"food","designed":true},
	"scar_stitch_care":{"name":"缝痕桑汁（缝痕蚕蛊一日份）","restore":100.0,"type":"food","designed":true},
	"red_dew_tick_care":{"name":"赤露枣浆（赤露蜱蛊一日份）","restore":100.0,"type":"food","designed":true},
	"calm_bell_moth_care":{"name":"安神铃花蜜（安神铃蛾蛊一日份）","restore":100.0,"type":"food","designed":true},
	"purifying_lacewing_care":{"name":"涤秽叶露（涤秽纱蛊一日份）","restore":100.0,"type":"food","designed":true},
	"return_spring_silk_care":{"name":"回春嫩桑乳（回春绫蛊一日份）","restore":100.0,"type":"food","designed":true},
	"grass_skipper_care":{"name":"草梢嫩芽（草梢跃蛊一日份）","restore":100.0,"type":"food","designed":true},
	"river_fin_care":{"name":"河鳍水藻（河鳍蛊一日份）","restore":100.0,"type":"food","designed":true},
	"gale_kite_moth_care":{"name":"风鸢蕨粉（风鸢蛾蛊一日份）","restore":100.0,"type":"food","designed":true},
	"shadow_step_spider_care":{"name":"影步菌露（影步蛛蛊一日份）","restore":100.0,"type":"food","designed":true},
	"lantern_antenna_care":{"name":"灯须花蜜（灯须蛊一日份）","restore":100.0,"type":"food","designed":true},
	"ore_echo_cicada_care":{"name":"矿鸣菌髓（矿鸣蝉蛊一日份）","restore":100.0,"type":"food","designed":true},
	"horizon_owl_moth_care":{"name":"望野蕈粉（望野枭蛾蛊一日份）","restore":100.0,"type":"food","designed":true},
	"deep_resonance_beetle_care":{"name":"深鸣岩乳（深鸣甲蛊一日份）","restore":100.0,"type":"food","designed":true},
	"reed_cutter_care":{"name":"芦刃苇髓（芦刃蛊一日份）","restore":100.0,"type":"food","designed":true},
	"flint_mason_care":{"name":"燧石细砂（燧石匠蛊一日份）","restore":100.0,"type":"food","designed":true},
	"amber_resin_ant_care":{"name":"琥脂树胶（琥脂蚁蛊一日份）","restore":100.0,"type":"food","designed":true},
	"mountain_borer_care":{"name":"山髓矿乳（山髓钻蛊一日份）","restore":100.0,"type":"food","designed":true},
	"golden_splinter_care":{"name":"金粉蜂蜜（金屑蛊一日份）","restore":100.0,"type":"food","designed":true},
	"stone_pellet_care":{"name":"碎石髓（崩石蛊一日份）","restore":100.0,"type":"food","designed":true},
	"wind_shear_care":{"name":"风铃草粉（剪风蛊一日份）","restore":100.0,"type":"food","designed":true},
	"venom_gnat_care":{"name":"苦藤毒露（碧毒蚋一日份）","restore":100.0,"type":"food","designed":true},
	"red_lotus_moth_care":{"name":"赤莲炭粉（红莲蛾一日份）","restore":100.0,"type":"food","designed":true},
	"ice_lance_care":{"name":"冰晶寒露（冰棱蛊一日份）","restore":100.0,"type":"food","designed":true},
	"thunder_pupa_care":{"name":"雷纹矿砂（雷芽蛊一日份）","restore":100.0,"type":"food","designed":true},
	"thorn_seed_care":{"name":"刺藤籽浆（棘籽蛊一日份）","restore":100.0,"type":"food","designed":true},
	"iron_drill_care":{"name":"磁铁矿粉（铁钻蛊一日份）","restore":100.0,"type":"food","designed":true},
	"rime_wing_care":{"name":"霜蕨露（雾凇蛊一日份）","restore":100.0,"type":"food","designed":true},
	"blood_suture_care":{"name":"红枣血芝浆（血络蛊一日份）","restore":100.0,"type":"food","designed":true},
	"warm_pupa_care":{"name":"暖姜蜜（暖脉蛊一日份）","restore":100.0,"type":"food","designed":true},
	"rain_pearl_care":{"name":"雨珠苔汁（雨珠蛊一日份）","restore":100.0,"type":"food","designed":true},
	"vigor_grub_care":{"name":"谷芽蜜（回劲蛊一日份）","restore":100.0,"type":"food","designed":true},
	"spring_cocoon_care":{"name":"春芽桑露（春茧蛊一日份）","restore":100.0,"type":"food","designed":true},
	"reed_armor_care":{"name":"芦苇髓（苇甲蛊一日份）","restore":100.0,"type":"food","designed":true},
	"mirror_scale_care":{"name":"银鳞矿粉（镜鳞蛊一日份）","restore":100.0,"type":"food","designed":true},
	"cinder_coat_care":{"name":"冷炭灰蜜（灰烬衣蛊一日份）","restore":100.0,"type":"food","designed":true},
	"frost_ward_care":{"name":"雪绒苔粉（寒绒蛊一日份）","restore":100.0,"type":"food","designed":true},
	"quick_cricket_care":{"name":"疾草籽（疾踵蛊一日份）","restore":100.0,"type":"food","designed":true},
	"cloud_locust_care":{"name":"云蕨嫩芽（云翅蝗一日份）","restore":100.0,"type":"food","designed":true},
	"water_skater_care":{"name":"水藻露（踏波蛊一日份）","restore":100.0,"type":"food","designed":true},
	"mist_butterfly_care":{"name":"烟叶细粉（烟叶蝶一日份）","restore":100.0,"type":"food","designed":true},
	"far_sight_care":{"name":"鹰眼蕈粉（远睛蛊一日份）","restore":100.0,"type":"food","designed":true},
	"earth_cicada_care":{"name":"岩隙菌粉（地听蝉一日份）","restore":100.0,"type":"food","designed":true},
	"scent_ant_care":{"name":"木须菌露（寻材蚁一日份）","restore":100.0,"type":"food","designed":true},
	"ore_mandible_care":{"name":"砂铁菌粉（碎矿颚蛊一日份）","restore":100.0,"type":"food","designed":true},
	"timber_mantis_care":{"name":"青木树髓（伐木螳一日份）","restore":100.0,"type":"food","designed":true},
	"gather_scarab_care":{"name":"腐叶菌饼（拾荒蜣一日份）","restore":100.0,"type":"food","designed":true},
	"burrow_grub_care":{"name":"岩髓砂浆（凿岩蛊一日份）","restore":100.0,"type":"food","designed":true},
	"soothing_moth_care":{"name":"舒筋花蜜（舒筋蛊一日份）","restore":100.0,"type":"food","designed":true},
	"stream_gu_care":{"name":"溪露与水藻（溪流蛊一日份）","restore":100.0,"type":"food","designed":true},
	"ember_moth_care":{"name":"炭蜜（焰星蛊一日份）","restore":100.0,"type":"food","designed":true},
	"frost_midge_care":{"name":"寒露（霜针蛊一日份）","restore":100.0,"type":"food","designed":true},
	"vine_spider_care":{"name":"青藤汁（藤缚蛊一日份）","restore":100.0,"type":"food","designed":true},
	"mending_silk_care":{"name":"桑叶露（青丝缝伤蛊一日份）","restore":100.0,"type":"food","designed":true},
	"resin_beetle_care":{"name":"松脂（松脂止血蛊一日份）","restore":100.0,"type":"food","designed":true},
	"dew_moth_care":{"name":"晨露（净露蛊一日份）","restore":100.0,"type":"food","designed":true},
	"wind_moth_care":{"name":"清风花粉（逐风蛊一日份）","restore":100.0,"type":"food","designed":true},
	"night_firefly_care":{"name":"夜蕈孢粉（萤瞳蛊一日份）","restore":100.0,"type":"food","designed":true},
	"echo_cicada_care":{"name":"竹露（回声蛊一日份）","restore":100.0,"type":"food","designed":true},
	"gravel_shell_care":{"name":"细砾矿粉（砾壳蛊一日份）","restore":100.0,"type":"food","designed":true},
	"bamboo_saw_care":{"name":"嫩竹髓（竹锯蛊一日份）","restore":100.0,"type":"food","designed":true},
	"veil_leaf_care":{"name":"枯叶粉（枯叶隐息蛊一日份）","restore":100.0,"type":"food","designed":true},
	"moon_glow_care":{"name":"月芒蛊专用供养（一日份）","restore":100.0,"type":"food"},
	"moon_raiment_care":{"name":"月霓裳专用供养（一日份）","restore":100.0,"type":"food"},
	"copper_skin_care":{"name":"铜皮蛊专用供养（一日份）","restore":100.0,"type":"food"},
	"iron_skin_care":{"name":"铁皮蛊专用供养（一日份）","restore":100.0,"type":"food"},
	"stone_skin_care":{"name":"石皮蛊专用供养（一日份）","restore":100.0,"type":"food"},
	"beast_skin_care":{"name":"兽皮蛊专用供养（一日份）","restore":100.0,"type":"food"},
	"brute_longhorn_care":{"name":"蛮力天牛蛊专用供养（一日份）","restore":100.0,"type":"food"},
	"yellow_camel_care":{"name":"黄骆天牛蛊专用供养（一日份）","restore":100.0,"type":"food"},
	"dragon_cricket_care":{"name":"龙丸蛐蛐蛊专用供养（一日份）","restore":100.0,"type":"food"},
	"moon_petals":{"name":"月兰花瓣","restore":25.0,"type":"food"},
	"bamboo_wine":{"name":"青竹酒（一坛）","restore":100.0,"type":"food"},
	"jade":{"name":"玉石（二两）","restore":100.0,"type":"food"},
	"pork_ration":{"name":"整猪肉（一头成年猪份）","restore":100.0,"type":"food"},
	"light_care":{"name":"小光蛊专用供养（一日份）","restore":100.0,"type":"food"},
}
var hunger_system: HungerSystem

func _ready() -> void:
	hunger_system=get_node_or_null("/root/Hunger")

func feed_gu(gu_id: String, food_id: String, _dao: String = "") -> bool:
	var gus := get_node_or_null("/root/Gus")
	var gu: GuVirtual = gus.get_gu_by_id(gu_id) if gus else null
	if gu==null or gu.dead or gu.preferred_food!=food_id or not GRAINS.has(food_id): return false
	# 白玉二十日食八两；每份玉石二两，四份供满一个周期。
	var restore := 25.0 if gu.template_id=="white_jade" and food_id=="jade" else float(GRAINS[food_id].restore)
	if not hunger_system.feed_gu(gu_id,restore): return false
	food_used.emit(food_id,gu_id,restore)
	return true

func calculate_restore(food_id: String, _dao: String = "") -> float:
	return float(GRAINS.get(food_id,{}).get("restore",0))

func get_food_name(food_id: String) -> String:
	return String(GRAINS.get(food_id,{}).get("name",food_id))

func get_food_dao(_food_id: String) -> String:
	return ""

func get_food_type(_food_id: String) -> String:
	return "food"

func get_food_description(food_id: String, _dao: String = "") -> String:
	if GRAINS.get(food_id,{}).get("designed",false): return get_food_name(food_id)+"。本作设计的专属配方，一份供养一游戏日；三寨商铺均有售，每份 1 元石，不能通喂其他蛊。"
	if food_id.ends_with("_care"): return get_food_name(food_id)+"。专属供养的试玩抽象；具体食材尚待核实，一日份与售价为模拟参数，不是原著食谱。"
	if food_id=="light_care": return "小光蛊供养的试玩抽象；具体食材尚待原著核实，一日份为模拟参数。不能喂给其他蛊。"
	return get_food_name(food_id)+"。只可喂给以此为食的蛊虫；不匹配不会消耗物品。"
