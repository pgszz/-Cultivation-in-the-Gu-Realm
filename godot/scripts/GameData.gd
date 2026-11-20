class_name GameData
extends RefCounted

## 全局常量、蛊虫数据库、转数表。

const TILE := 32
const MAP_W := 480
const MAP_H := 360
const MAP_VERSION := 7
# 三寨距离是自由探索布局，不是原著测绘比例。
const BAI_VILLAGE := Vector2(360 * TILE, 64 * TILE)
const XIONG_VILLAGE := Vector2(248 * TILE, 304 * TILE)

const VILLAGE := Vector2i(14, 30)
const FURNACE := Vector2(15 * TILE + 16, 28 * TILE + 16)
const BONFIRE := Vector2(12 * TILE + 16, 31 * TILE + 16)

const T_GRASS := 0
const T_DIRT := 1
const T_WATER := 2
const T_ROCK := 3
const T_TREE := 4
const T_FLOWER := 5
const T_RUIN := 6

const EL_COLOR := {
	"metal": Color("#d9c46a"),
	"wood": Color("#5fbf6a"),
	"water": Color("#4aa3df"),
	"fire": Color("#e8663a"),
	"earth": Color("#b08a4f"),
	"thunder": Color("#b07be8"),
	"wind": Color("#7fd6c2"),
	"none": Color("#cfd8cf"),
}

const EL_NAME := {
	"metal": "金", "wood": "木", "water": "水", "fire": "火",
	"earth": "土", "thunder": "雷", "wind": "风", "none": "无",
}

# 原著条目保留正文依据；新增原创和改编以 origin 明示，不从旧表推定原著规则。
const GU := {
	"iron_bone": {"name":"铁骨蛊","rank":3,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374792"],"preferred_food":"iron_bone_care","origin":"原著蛊虫·规则改编","shop":"xiong_shop","rarity":"罕见（游戏）","hint":"骨骼永久强化：头颈、胸腹、骨盆及四肢的部位伤害 ×0.80；气血伤害不变。消耗一只，疼痛 +65。与玉骨互斥；静处、疼痛低于 35、血量至少 70 才可用。","skill":{"kind":"body_change","effect":"bone","cost":3000,"cd":0,"dmg":0,"element":"none","name":"铁骨蛊","consumed":true,"bone_factor":0.8,"pain":65,"color":Color("485e69")},"color":Color("485e69"),"flavor":"原著名称与核心用途见肉身状态蛊专题；数值、商铺投放、使用限制是游戏改编。"},
	"jade_bone": {"name":"玉骨蛊","rank":3,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374785"],"preferred_food":"jade_bone_care","origin":"原著蛊虫·规则改编","shop":"bai_shop","rarity":"罕见（游戏）","hint":"骨骼永久强化：头颈、胸腹、骨盆及四肢的部位伤害 ×0.70；气血伤害不变。消耗一只，疼痛 +65。与铁骨互斥；静处、疼痛低于 35、血量至少 70 才可用。","skill":{"kind":"body_change","effect":"bone","cost":3000,"cd":0,"dmg":0,"element":"none","name":"玉骨蛊","consumed":true,"bone_factor":0.7,"pain":65,"color":Color("9acdb2")},"color":Color("9acdb2"),"flavor":"原著名称与核心用途见肉身状态蛊专题；数值、商铺投放、使用限制是游戏改编。"},
	"vitality_leaf": {"name":"生机叶","rank":1,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374716"],"preferred_food":"vitality_leaf_care","origin":"原著蛊虫·规则改编","shop":"shop","rarity":"常规（游戏）","hint":"消耗一片：气血 +12，所有未毁损部位耐久 +6；不补血、不止血、不再生。无伤时不消耗。","skill":{"kind":"body_change","effect":"leaf","cost":0,"cd":0,"dmg":0,"element":"none","name":"生机叶","consumed":true,"part_rate":6,"hp_rate":12,"color":Color("99c36a")},"color":Color("99c36a"),"flavor":"原著名称与核心用途见肉身状态蛊专题；数值、商铺投放、使用限制是游戏改编。"},
	"self_reliance": {"name":"自力更生蛊","rank":3,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374852"],"preferred_food":"self_reliance_care","origin":"原著蛊虫·规则改编","shop":"xiong_shop","rarity":"罕见（游戏）","hint":"持续 8 秒：每秒恢复气血及最伤的未毁损部位，速率为（基础肉身攻击＋永久豕力）×0.12，最高 6；同时每秒耗体力 2。筋骨强化使疗效降低。","skill":{"kind":"body_change","effect":"self_heal","cost":1200,"cd":28,"dmg":0,"element":"none","name":"自力更生蛊","duration":8,"group":"recovery","stamina_drain":2,"color":Color("927759")},"color":Color("927759"),"flavor":"原著名称与核心用途见肉身状态蛊专题；数值、商铺投放、使用限制是游戏改编。"},
	"tempered_sinew": {"name":"锻筋金蚕蛊","rank":3,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"tempered_sinew_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"罕见（游戏）","hint":"静处每秒锻筋进度 +2.5%，一次最多 20 秒；永久上限 100%。满进度使四肢部位伤害 ×0.85、蛮力新增负担 ×0.65。移动、攻击、受击或打坐中断；预付耗元不返还。","skill":{"kind":"body_change","effect":"training","cost":1200,"cd":28,"dmg":0,"element":"none","name":"锻筋金蚕蛊","duration":20,"group":"training","training_rate":0.025,"color":Color("c9ad65")},"color":Color("c9ad65"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"clot_thread": {"name":"凝血丝蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"clot_thread_care","origin":"原创蛊虫","shop":"shop","rarity":"常规（游戏）","hint":"15 秒内所有伤口失血速度 ×0.45；没有封闭伤口，结束后恢复出血。颈部致命倒计时不受影响。","skill":{"kind":"body_change","effect":"clot","cost":120,"cd":28,"dmg":0,"element":"none","name":"凝血丝蛊","duration":15,"group":"circulation","bleed":0.45,"color":Color("c76d79")},"color":Color("c76d79"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"numb_ant": {"name":"麻感蚁蛊","rank":1,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"numb_ant_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"12 秒内新受伤产生的疼痛 ×0.35；不消除已有疼痛、不降低伤害、不阻止失血昏迷。","skill":{"kind":"body_change","effect":"numb","cost":12,"cd":28,"dmg":0,"element":"none","name":"麻感蚁蛊","duration":12,"group":"nerves","pain_taken":0.35,"color":Color("b5a7d0")},"color":Color("b5a7d0"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"lucid_larva": {"name":"醒神幼蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"lucid_larva_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"常规（游戏）","hint":"12 秒内意识 +2/秒，最高 100；须清醒主动催动，头部重伤仍持续压低意识。","skill":{"kind":"body_change","effect":"lucid","cost":120,"cd":28,"dmg":0,"element":"none","name":"醒神幼蛊","duration":12,"group":"nerves","conscious_rate":2,"color":Color("9ebae5")},"color":Color("9ebae5"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"sinew_spring": {"name":"弹筋蛐蛐蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"sinew_spring_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"10 秒内徒手攻速 ×1.30，每秒体力 -1；双臂须未毁损且至少一臂不重伤。体力耗尽即停，不强化月刃。","skill":{"kind":"body_change","effect":"spring","cost":120,"cd":28,"dmg":0,"element":"none","name":"弹筋蛐蛐蛊","duration":10,"group":"mobility","attack_speed":1.3,"stamina_drain":1,"color":Color("b7cb73")},"color":Color("b7cb73"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"feather_marrow": {"name":"轻髓羽蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"feather_marrow_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"常规（游戏）","hint":"12 秒内移速 ×1.25，但所有部位所受伤害 ×1.20；伤腿与碰撞规则不变。","skill":{"kind":"body_change","effect":"feather","cost":120,"cd":28,"dmg":0,"element":"none","name":"轻髓羽蛊","duration":12,"group":"mobility","move":1.25,"part_damage":1.2,"color":Color("d8dfeb")},"color":Color("d8dfeb"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"ballast_bone": {"name":"沉骨甲蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"ballast_bone_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"15 秒内骨盆与双腿部位伤害 ×0.65，移速 ×0.80；不减少气血伤害、不恢复毁损腿。","skill":{"kind":"body_change","effect":"ballast","cost":120,"cd":28,"dmg":0,"element":"none","name":"沉骨甲蛊","duration":15,"group":"mobility","move":0.8,"part_damage":0.65,"regions":["pelvis","leg_l","leg_r"],"color":Color("8c9095")},"color":Color("8c9095"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"scar_crust": {"name":"护痂蜗蛊","rank":1,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"scar_crust_care","origin":"原创蛊虫","shop":"shop","rarity":"常规（游戏）","hint":"B 页选定一个未毁损部位：15 秒内该部位伤害 ×0.55；只保护选定部位，不补耐久、不封血。","skill":{"kind":"body_change","effect":"crust","cost":12,"cd":28,"dmg":0,"element":"none","name":"护痂蜗蛊","duration":15,"group":"surface","part_damage":0.55,"selected":true,"color":Color("c7a17e")},"color":Color("c7a17e"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"red_pulse": {"name":"赤脉蛭蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"red_pulse_care","origin":"原创蛊虫","shop":"shop","rarity":"常规（游戏）","hint":"10 秒内血量 +1.2/秒，气血 -0.6/秒；气血降至 15 自动停止。血量满或气血不足时不可用，不止血。","skill":{"kind":"body_change","effect":"pulse","cost":120,"cd":28,"dmg":0,"element":"none","name":"赤脉蛭蛊","duration":10,"group":"circulation","blood_rate":1.2,"hp_drain":0.6,"color":Color("c45765")},"color":Color("c45765"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"lung_bell": {"name":"润肺铃蛊","rank":1,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"lung_bell_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"常规（游戏）","hint":"16 秒内体力额外恢复 +5/秒；胸腹须未毁损且耐久高于 30%，失去条件立即结束。","skill":{"kind":"body_change","effect":"lung","cost":12,"cd":28,"dmg":0,"element":"none","name":"润肺铃蛊","duration":16,"group":"breath","stamina_rate":5,"required":["torso"],"color":Color("b7d5cc")},"color":Color("b7d5cc"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"bitter_liver": {"name":"苦胆蝉蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"bitter_liver_care","origin":"原创蛊虫","shop":"shop","rarity":"常规（游戏）","hint":"15 秒内中毒剩余时间额外减少 3 秒/秒；胸腹须高于 30% 耐久。不清除灼烧、不修复伤势。","skill":{"kind":"body_change","effect":"liver","cost":120,"cd":28,"dmg":0,"element":"none","name":"苦胆蝉蛊","duration":15,"group":"metabolism","clear_state":"poison","clear_rate":3,"required":["torso"],"color":Color("a9bd69")},"color":Color("a9bd69"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"warm_muscle": {"name":"温肌绒蛊","rank":1,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"warm_muscle_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"12 秒内迟缓剩余时间额外减少 3 秒/秒；不提供火伤抗性，不解除麻痹。","skill":{"kind":"body_change","effect":"warm","cost":12,"cd":28,"dmg":0,"element":"none","name":"温肌绒蛊","duration":12,"group":"temperature","clear_state":"slow","clear_rate":3,"color":Color("d7ab7c")},"color":Color("d7ab7c"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"nerve_lantern": {"name":"通络灯蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"nerve_lantern_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"常规（游戏）","hint":"12 秒内麻痹剩余时间额外减少 4 秒/秒，但新受伤疼痛 ×1.35。与麻感、醒神互斥。","skill":{"kind":"body_change","effect":"nerve","cost":120,"cd":28,"dmg":0,"element":"none","name":"通络灯蛊","duration":12,"group":"nerves","clear_state":"shock","clear_rate":4,"pain_taken":1.35,"color":Color("dccd83")},"color":Color("dccd83"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"clear_cornea": {"name":"澄膜蜉蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"clear_cornea_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"常规（游戏）","hint":"8 秒内双眼中未毁损的受伤眼耐久 +0.65/秒，视野随真实眼伤恢复；双眼均毁损不能用。受击中断。","skill":{"kind":"body_change","effect":"eyes","cost":120,"cd":28,"dmg":0,"element":"none","name":"澄膜蜉蛊","duration":8,"group":"recovery","part_rate":0.65,"regions":["eye_l","eye_r"],"interrupt_hit":true,"color":Color("9ddad9")},"color":Color("9ddad9"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"ear_suture": {"name":"缝耳蝠蛊","rank":1,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"ear_suture_care","origin":"原创蛊虫","shop":"shop","rarity":"常规（游戏）","hint":"8 秒内未毁损的受伤耳耐久 +0.8/秒、疼痛 -0.5/秒；不凭空增加听觉或视野。受击中断。","skill":{"kind":"body_change","effect":"ears","cost":12,"cd":28,"dmg":0,"element":"none","name":"缝耳蝠蛊","duration":8,"group":"recovery","part_rate":0.8,"pain_rate":-0.5,"regions":["ear_l","ear_r"],"interrupt_hit":true,"color":Color("bba0b3")},"color":Color("bba0b3"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"joint_mender": {"name":"续节竹蛊","rank":2,"dao":"肉身","category":"肉身","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"joint_mender_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"B 页选未毁损的受伤手臂或腿：10 秒内耐久 +1.5/秒、蛮力负担 -2/秒，移速 ×0.75；受击中断，不能接回断肢。","skill":{"kind":"body_change","effect":"joint","cost":120,"cd":28,"dmg":0,"element":"none","name":"续节竹蛊","duration":10,"group":"recovery","selected":true,"part_rate":1.5,"strain_rate":-2,"move":0.75,"allowed":["hand_l","hand_r","leg_l","leg_r"],"interrupt_hit":true,"color":Color("8fb98f")},"color":Color("8fb98f"),"flavor":"本作原创：名称、外形、数值、使用方式与食性都是游戏设计。"},
	"clear_origin_silkworm": {"name":"清源玉蚕蛊","rank":4,"dao":"资质","category":"资质","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"clear_origin_silkworm_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"珍稀（游戏）","hint":"静处修炼 20 秒，每秒资质容量 +0.15 个百分点，本蛊最高 79%；四种资质蛊共享终身 +20 点上限。预付 80 元石；移动、攻击、受击或打坐中断，已付费用不返还。不补真元、不升阶。","skill":{"kind":"aptitude_training","cost":6000,"cd":90,"dmg":0,"element":"none","duration":20,"rate":0.15,"ceiling":79,"stones":80,"name":"清源玉蚕蛊","color":Color("92d9b0")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("92d9b0")},
	"deep_spring_butterfly": {"name":"玄泉蝶蛊","rank":4,"dao":"资质","category":"资质","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"deep_spring_butterfly_care","origin":"原创蛊虫","shop":"shop","rarity":"珍稀（游戏）","hint":"静处修炼 20 秒，每秒资质容量 +0.2 个百分点，本蛊最高 89%；四种资质蛊共享终身 +20 点上限。预付 120 元石；移动、攻击、受击或打坐中断，已付费用不返还。不补真元、不升阶。","skill":{"kind":"aptitude_training","cost":8000,"cd":100,"dmg":0,"element":"none","duration":20,"rate":0.2,"ceiling":89,"stones":120,"name":"玄泉蝶蛊","color":Color("58afbc")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("58afbc")},
	"marrow_lotus_beetle": {"name":"洗髓莲甲蛊","rank":5,"dao":"资质","category":"资质","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"marrow_lotus_beetle_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"珍稀（游戏）","hint":"静处修炼 20 秒，每秒资质容量 +0.25 个百分点，本蛊最高 95%；四种资质蛊共享终身 +20 点上限。预付 180 元石；移动、攻击、受击或打坐中断，已付费用不返还。不补真元、不升阶。","skill":{"kind":"aptitude_training","cost":70000,"cd":120,"dmg":0,"element":"none","duration":20,"rate":0.25,"ceiling":95,"stones":180,"name":"洗髓莲甲蛊","color":Color("d9b8c3")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("d9b8c3")},
	"nine_aurora_cocoon": {"name":"九华灵茧蛊","rank":5,"dao":"资质","category":"资质","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"nine_aurora_cocoon_care","origin":"原创蛊虫","shop":"shop","rarity":"珍稀（游戏）","hint":"静处修炼 20 秒，每秒资质容量 +0.3 个百分点，本蛊最高 99%；四种资质蛊共享终身 +20 点上限。预付 250 元石；移动、攻击、受击或打坐中断，已付费用不返还。不补真元、不升阶。","skill":{"kind":"aptitude_training","cost":90000,"cd":150,"dmg":0,"element":"none","duration":20,"rate":0.3,"ceiling":99,"stones":250,"name":"九华灵茧蛊","color":Color("cbabed")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("cbabed")},
	"bronze_relic": {"name":"青铜舍利蛊","rank":1,"dao":"修炼","category":"修炼","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374670","5374674","5374776","5374777","5375035"],"preferred_food":"bronze_relic_care","origin":"原著蛊虫·规则改编","shop":"shop","rarity":"常规（游戏）","hint":"一次性消耗，仅用于1转蛊师，使当前修为提升一个小阶；巅峰不可用，不能跨转、不能提高资质。本作禁止主动消耗本命舍利。","skill":{"kind":"relic","cost":0,"cd":0,"dmg":0,"element":"none","name":"青铜舍利蛊","color":Color("9d8857")},"flavor":"原著舍利系列：一转青铜、二转赤铁、三转白银、四转黄金、五转紫晶；只提升本转小阶。独立供养抽象、商铺投放、价格和使用保护为本作安排。","color":Color("9d8857")},
	"red_iron_relic": {"name":"赤铁舍利蛊","rank":2,"dao":"修炼","category":"修炼","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374670","5374674","5374776","5374777","5375035"],"preferred_food":"red_iron_relic_care","origin":"原著蛊虫·规则改编","shop":"xiong_shop","rarity":"常规（游戏）","hint":"一次性消耗，仅用于2转蛊师，使当前修为提升一个小阶；巅峰不可用，不能跨转、不能提高资质。本作禁止主动消耗本命舍利。","skill":{"kind":"relic","cost":0,"cd":0,"dmg":0,"element":"none","name":"赤铁舍利蛊","color":Color("b8614c")},"flavor":"原著舍利系列：一转青铜、二转赤铁、三转白银、四转黄金、五转紫晶；只提升本转小阶。独立供养抽象、商铺投放、价格和使用保护为本作安排。","color":Color("b8614c")},
	"silver_relic": {"name":"白银舍利蛊","rank":3,"dao":"修炼","category":"修炼","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374670","5374674","5374776","5374777","5375035"],"preferred_food":"silver_relic_care","origin":"原著蛊虫·规则改编","shop":"bai_shop","rarity":"罕见（游戏）","hint":"一次性消耗，仅用于3转蛊师，使当前修为提升一个小阶；巅峰不可用，不能跨转、不能提高资质。本作禁止主动消耗本命舍利。","skill":{"kind":"relic","cost":0,"cd":0,"dmg":0,"element":"none","name":"白银舍利蛊","color":Color("dae8ea")},"flavor":"原著舍利系列：一转青铜、二转赤铁、三转白银、四转黄金、五转紫晶；只提升本转小阶。独立供养抽象、商铺投放、价格和使用保护为本作安排。","color":Color("dae8ea")},
	"gold_relic": {"name":"黄金舍利蛊","rank":4,"dao":"修炼","category":"修炼","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374670","5374674","5374776","5374777","5375035"],"preferred_food":"gold_relic_care","origin":"原著蛊虫·规则改编","shop":"shop","rarity":"珍稀（游戏）","hint":"一次性消耗，仅用于4转蛊师，使当前修为提升一个小阶；巅峰不可用，不能跨转、不能提高资质。本作禁止主动消耗本命舍利。","skill":{"kind":"relic","cost":0,"cd":0,"dmg":0,"element":"none","name":"黄金舍利蛊","color":Color("ecc560")},"flavor":"原著舍利系列：一转青铜、二转赤铁、三转白银、四转黄金、五转紫晶；只提升本转小阶。独立供养抽象、商铺投放、价格和使用保护为本作安排。","color":Color("ecc560")},
	"purple_relic": {"name":"紫晶舍利蛊","rank":5,"dao":"修炼","category":"修炼","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374670","5374674","5374776","5374777","5375035"],"preferred_food":"purple_relic_care","origin":"原著蛊虫·规则改编","shop":"bai_shop","rarity":"珍稀（游戏）","hint":"一次性消耗，仅用于5转蛊师，使当前修为提升一个小阶；巅峰不可用，不能跨转、不能提高资质。本作禁止主动消耗本命舍利。","skill":{"kind":"relic","cost":0,"cd":0,"dmg":0,"element":"none","name":"紫晶舍利蛊","color":Color("ae8ae4")},"flavor":"原著舍利系列：一转青铜、二转赤铁、三转白银、四转黄金、五转紫晶；只提升本转小阶。独立供养抽象、商铺投放、价格和使用保护为本作安排。","color":Color("ae8ae4")},
	"quiet_incense_moth": {"name":"静香蛾蛊","rank":2,"dao":"修炼","category":"修炼","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"quiet_incense_moth_care","origin":"原创蛊虫","shop":"shop","rarity":"常规（游戏）","hint":"30 秒内温养速度与对应耗元同时 ×1.5；需 J 打坐，不影响跨转冲窍、不产生额外真元。","skill":{"kind":"cultivation","cost":50,"cd":45,"dmg":0,"element":"none","duration":30,"multiplier":1.5,"name":"静香蛾蛊","color":Color("b7a68c")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("b7a68c")},
	"wall_polish_snail": {"name":"磨壁螺蛊","rank":3,"dao":"修炼","category":"修炼","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"wall_polish_snail_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"罕见（游戏）","hint":"30 秒内温养速度与对应耗元同时 ×2.0；需 J 打坐，不影响跨转冲窍、不产生额外真元。","skill":{"kind":"cultivation","cost":600,"cd":45,"dmg":0,"element":"none","duration":30,"multiplier":2.0,"name":"磨壁螺蛊","color":Color("85a69d")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("85a69d")},
	"copper_fletch": {"name":"铜翎蛊","rank":1,"dao":"攻击","category":"攻击","element":"metal","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"copper_fletch_care","origin":"原创蛊虫","shop":"shop","rarity":"常规（游戏）","hint":"发射 2 枚蛊术弹，每枚伤害 11。","skill":{"kind":"utility_projectile","cost":9,"cd":1.2,"dmg":11,"speed":650,"element":"metal","count":2,"spread":0.09,"name":"铜翎蛊","color":Color("b78d5c")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("b78d5c")},
	"sand_fang": {"name":"沙牙蛊","rank":2,"dao":"攻击","category":"攻击","element":"earth","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"sand_fang_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"发射 1 枚蛊术弹，每枚伤害 42。命中附加迟缓 2 秒。","skill":{"kind":"utility_projectile","cost":100,"cd":2.8,"dmg":42,"speed":350,"element":"earth","slow":2,"name":"沙牙蛊","color":Color("bda172")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("bda172")},
	"rain_needle": {"name":"雨针蜓蛊","rank":2,"dao":"攻击","category":"攻击","element":"water","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"rain_needle_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"常规（游戏）","hint":"发射 3 枚蛊术弹，每枚伤害 16。命中附加潮湿 5 秒。","skill":{"kind":"utility_projectile","cost":110,"cd":2,"dmg":16,"speed":700,"element":"water","count":3,"spread":0.07,"wet":5,"name":"雨针蜓蛊","color":Color("8ac9df")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("8ac9df")},
	"obsidian_mantis": {"name":"玄刃螳蛊","rank":3,"dao":"攻击","category":"攻击","element":"metal","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"obsidian_mantis_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"罕见（游戏）","hint":"发射 1 枚蛊术弹，每枚伤害 90。可贯穿目标，贯穿预算 2。","skill":{"kind":"utility_projectile","cost":1000,"cd":2,"dmg":90,"speed":600,"element":"metal","pierce":2,"name":"玄刃螳蛊","color":Color("7d849c")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("7d849c")},
	"storm_hornet": {"name":"暴岚蜂蛊","rank":3,"dao":"攻击","category":"攻击","element":"wind","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"storm_hornet_care","origin":"原创蛊虫","shop":"shop","rarity":"罕见（游戏）","hint":"发射 4 枚蛊术弹，每枚伤害 29。命中附加束缚 1 秒。","skill":{"kind":"utility_projectile","cost":1200,"cd":3,"dmg":29,"speed":650,"element":"wind","count":4,"spread":0.1,"bind":1,"name":"暴岚蜂蛊","color":Color("8cbad3")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("8cbad3")},
	"sun_ember_scarab": {"name":"日烬金龟蛊","rank":4,"dao":"攻击","category":"攻击","element":"fire","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"sun_ember_scarab_care","origin":"原创蛊虫","shop":"shop","rarity":"珍稀（游戏）","hint":"发射 1 枚蛊术弹，每枚伤害 140。命中附加灼烧 5 秒。落点接入已有水火环境反应。","skill":{"kind":"utility_projectile","cost":16000,"cd":4,"dmg":140,"speed":450,"element":"fire","burn":5,"reaction":"fire","name":"日烬金龟蛊","color":Color("eeb95e")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("eeb95e")},
	"glacier_centipede": {"name":"冰魄蜈蛊","rank":5,"dao":"攻击","category":"攻击","element":"water","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"glacier_centipede_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"珍稀（游戏）","hint":"发射 4 枚蛊术弹，每枚伤害 66。命中附加迟缓 5 秒。落点接入已有水霜环境反应。","skill":{"kind":"utility_projectile","cost":180000,"cd":5,"dmg":66,"speed":600,"element":"water","count":4,"spread":0.12,"slow":5,"reaction":"frost","name":"冰魄蜈蛊","color":Color("b9eff6")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("b9eff6")},
	"bark_bastion": {"name":"厚栎甲蛊","rank":2,"dao":"防御","category":"防御","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"bark_bastion_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"护盾最多吸收 85 点伤害，持续 25 秒；同类护盾及皮蛊互斥。","skill":{"kind":"shell","cost":120,"cd":25,"dmg":0,"element":"none","duration":25,"points":85,"name":"厚栎甲蛊","color":Color("8a9b65")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("8a9b65")},
	"quartz_tortoise": {"name":"晶垒蛊","rank":3,"dao":"防御","category":"防御","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"quartz_tortoise_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"罕见（游戏）","hint":"护盾最多吸收 140 点伤害，持续 12 秒；同类护盾及皮蛊互斥。","skill":{"kind":"shell","cost":1500,"cd":30,"dmg":0,"element":"none","duration":12,"points":140,"name":"晶垒蛊","color":Color("b6d9e5")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("b6d9e5")},
	"thunder_insulator": {"name":"绝雷绒蛊","rank":3,"dao":"防御","category":"防御","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"thunder_insulator_care","origin":"原创蛊虫","shop":"shop","rarity":"罕见（游戏）","hint":"16 秒内雷属性伤害降低 70%；不免疫控制或其他伤害。","skill":{"kind":"resist","cost":800,"cd":22,"dmg":0,"element":"none","duration":16,"resist_element":"thunder","reduction":0.7,"name":"绝雷绒蛊","color":Color("9ca4df")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("9ca4df")},
	"basalt_heart": {"name":"玄岩心蛊","rank":4,"dao":"防御","category":"防御","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"basalt_heart_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"珍稀（游戏）","hint":"护盾最多吸收 240 点伤害，持续 18 秒；同类护盾及皮蛊互斥。","skill":{"kind":"shell","cost":18000,"cd":40,"dmg":0,"element":"none","duration":18,"points":240,"name":"玄岩心蛊","color":Color("998575")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("998575")},
	"prism_aegis": {"name":"虹棱甲蛊","rank":5,"dao":"防御","category":"防御","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"prism_aegis_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"珍稀（游戏）","hint":"护盾最多吸收 350 点伤害，持续 12 秒；同类护盾及皮蛊互斥。","skill":{"kind":"shell","cost":200000,"cd":45,"dmg":0,"element":"none","duration":12,"points":350,"name":"虹棱甲蛊","color":Color("b5d8ef")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("b5d8ef")},
	"scar_stitch": {"name":"缝痕蚕蛊","rank":1,"dao":"治疗","category":"治疗","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"scar_stitch_care","origin":"原创蛊虫","shop":"shop","rarity":"常规（游戏）","hint":"修补 B 页选定的未毁损部位，耐久 +10、气血 +4；不再生、不止血。","skill":{"kind":"mend","cost":10,"cd":18,"dmg":0,"element":"none","part_amount":10,"hp_amount":4,"name":"缝痕蚕蛊","color":Color("afe3c9")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("afe3c9")},
	"red_dew_tick": {"name":"赤露蜱蛊","rank":2,"dao":"治疗","category":"治疗","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"red_dew_tick_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"身体血量 +24，最高 100；不修复部位、不止血。","skill":{"kind":"blood_restore","cost":100,"cd":24,"dmg":0,"element":"none","amount":24,"name":"赤露蜱蛊","color":Color("d87877")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("d87877")},
	"calm_bell_moth": {"name":"安神铃蛾蛊","rank":3,"dao":"治疗","category":"治疗","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"calm_bell_moth_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"罕见（游戏）","hint":"意识 +18，最高 100；需清醒时主动催动，不修复头部或肢体。","skill":{"kind":"conscious_restore","cost":700,"cd":28,"dmg":0,"element":"none","amount":18,"name":"安神铃蛾蛊","color":Color("c6b2e8")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("c6b2e8")},
	"purifying_lacewing": {"name":"涤秽纱蛊","rank":4,"dao":"治疗","category":"治疗","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"purifying_lacewing_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"珍稀（游戏）","hint":"清除中毒、灼烧、迟缓与麻痹；不止血、不修复部位、不补气血。","skill":{"kind":"purify","cost":10000,"cd":35,"dmg":0,"element":"none","name":"涤秽纱蛊","color":Color("a8dfd1")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("a8dfd1")},
	"return_spring_silk": {"name":"回春绫蛊","rank":5,"dao":"治疗","category":"治疗","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"return_spring_silk_care","origin":"原创蛊虫","shop":"shop","rarity":"珍稀（游戏）","hint":"16 秒内，B 页选定未毁损部位耐久 +5/秒、气血 +4/秒；受击中断，毁损部位不能再生。","skill":{"kind":"regrowth","cost":120000,"cd":40,"dmg":0,"element":"none","duration":16,"part_rate":5,"hp_rate":4,"name":"回春绫蛊","color":Color("eed6d3")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("eed6d3")},
	"grass_skipper": {"name":"草梢跃蛊","rank":1,"dao":"移动","category":"移动","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"grass_skipper_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"移动速度 ×1.55，持续 4 秒；受伤势与地形影响，不穿墙。","skill":{"kind":"haste","cost":7,"cd":16,"dmg":0,"element":"none","duration":4,"multiplier":1.55,"name":"草梢跃蛊","color":Color("b1ce76")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("b1ce76")},
	"river_fin": {"name":"河鳍蛊","rank":2,"dao":"移动","category":"移动","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"river_fin_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"常规（游戏）","hint":"20 秒内移除游泳减速，仍受伤势、坡度和碰撞限制。","skill":{"kind":"swim","cost":60,"cd":24,"dmg":0,"element":"none","duration":20,"name":"河鳍蛊","color":Color("77c8d0")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("77c8d0")},
	"gale_kite_moth": {"name":"风鸢蛾蛊","rank":3,"dao":"移动","category":"移动","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"gale_kite_moth_care","origin":"原创蛊虫","shop":"shop","rarity":"罕见（游戏）","hint":"移动速度 ×1.65，持续 16 秒；受伤势与地形影响，不穿墙。","skill":{"kind":"haste","cost":900,"cd":26,"dmg":0,"element":"none","duration":16,"multiplier":1.65,"name":"风鸢蛾蛊","color":Color("b3d4e0")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("b3d4e0")},
	"shadow_step_spider": {"name":"影步蛛蛊","rank":4,"dao":"移动","category":"移动","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"shadow_step_spider_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"珍稀（游戏）","hint":"16 秒内敌人侦测你的距离 ×0.15；攻击或受击解除，不清除已有追击。","skill":{"kind":"veil","cost":11000,"cd":25,"dmg":0,"element":"none","duration":16,"detection":0.15,"name":"影步蛛蛊","color":Color("a597be")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("a597be")},
	"lantern_antenna": {"name":"灯须蛊","rank":1,"dao":"侦察","category":"侦察","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"lantern_antenna_care","origin":"原创蛊虫","shop":"shop","rarity":"常规（游戏）","hint":"视野半径 +100 像素，持续 20 秒；随后乘眼部状态倍率，不治眼伤。","skill":{"kind":"vision","cost":5,"cd":25,"dmg":0,"element":"none","duration":20,"bonus":100,"name":"灯须蛊","color":Color("ebd797")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("ebd797")},
	"ore_echo_cicada": {"name":"矿鸣蝉蛊","rank":2,"dao":"侦察","category":"侦察","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"ore_echo_cicada_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"定位地表 2400 像素内最近的可采集木石点，并探明其周围地形；不采集、不显示人物。","skill":{"kind":"prospect","cost":70,"cd":20,"dmg":0,"element":"none","range":2400,"name":"矿鸣蝉蛊","color":Color("c5af83")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("c5af83")},
	"horizon_owl_moth": {"name":"望野枭蛾蛊","rank":3,"dao":"侦察","category":"侦察","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"horizon_owl_moth_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"罕见（游戏）","hint":"视野半径 +400 像素，持续 16 秒；随后乘眼部状态倍率，不治眼伤。","skill":{"kind":"vision","cost":800,"cd":24,"dmg":0,"element":"none","duration":16,"bonus":400,"name":"望野枭蛾蛊","color":Color("a5bb83")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("a5bb83")},
	"deep_resonance_beetle": {"name":"深鸣甲蛊","rank":4,"dao":"侦察","category":"侦察","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"deep_resonance_beetle_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"珍稀（游戏）","hint":"探明地表 1800 像素内地形；已探索不等于当前视野，不显示远处人物。","skill":{"kind":"survey","cost":14000,"cd":36,"dmg":0,"element":"none","range":1800,"name":"深鸣甲蛊","color":Color("82afbd")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("82afbd")},
	"reed_cutter": {"name":"芦刃蛊","rank":1,"dao":"生计","category":"生计","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"reed_cutter_care","origin":"原创蛊虫","shop":"bai_shop","rarity":"常规（游戏）","hint":"20 秒内木料采集 +1、碎石采集 +0；保留刷新冷却，不影响普攻或房屋掉落。","skill":{"kind":"harvest","cost":6,"cd":25,"dmg":0,"element":"none","duration":20,"timber_bonus":1,"rubble_bonus":0,"name":"芦刃蛊","color":Color("a8bf82")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("a8bf82")},
	"flint_mason": {"name":"燧石匠蛊","rank":2,"dao":"生计","category":"生计","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"flint_mason_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"常规（游戏）","hint":"18 秒内木料采集 +0、碎石采集 +5；保留刷新冷却，不影响普攻或房屋掉落。","skill":{"kind":"harvest","cost":90,"cd":28,"dmg":0,"element":"none","duration":18,"timber_bonus":0,"rubble_bonus":5,"name":"燧石匠蛊","color":Color("a3a8b4")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("a3a8b4")},
	"amber_resin_ant": {"name":"琥脂蚁蛊","rank":3,"dao":"生计","category":"生计","element":"none","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"amber_resin_ant_care","origin":"原创蛊虫","shop":"shop","rarity":"罕见（游戏）","hint":"20 秒内木料采集 +4、碎石采集 +4；保留刷新冷却，不影响普攻或房屋掉落。","skill":{"kind":"harvest","cost":1000,"cd":30,"dmg":0,"element":"none","duration":20,"timber_bonus":4,"rubble_bonus":4,"name":"琥脂蚁蛊","color":Color("d4aa6b")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("d4aa6b")},
	"mountain_borer": {"name":"山髓钻蛊","rank":4,"dao":"生计","category":"生计","element":"earth","hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],"preferred_food":"mountain_borer_care","origin":"原创蛊虫","shop":"xiong_shop","rarity":"珍稀（游戏）","hint":"发射 1 枚蛊术弹，每枚伤害 20。地形基础破坏力 210，经材料硬度结算。","skill":{"kind":"utility_projectile","cost":12000,"cd":5,"dmg":20,"speed":350,"element":"earth","terrain_damage":210,"name":"山髓钻蛊","color":Color("ab9c7d")},"flavor":"本作原创蛊虫；名称、外形、食性、效果和数值均为游戏设计。","color":Color("ab9c7d")},
	"golden_splinter": {
		"name":"金屑蛊","rank":1,"dao":"攻击","category":"攻击","element":"metal",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"golden_splinter_care","origin":"原创蛊虫","shop":"shop","hint":"扇射三枚金屑，各伤害 9；近处可命中同一目标。",
		"skill":{"color":Color("e7c86e"),"name":"金屑蛊","kind":"utility_projectile","cost":11,"cd":2.4,"dmg":9,"element":"metal","speed":440,"count":3,"spread":0.16},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("e7c86e")
	},
	"stone_pellet": {
		"name":"崩石蛊","rank":1,"dao":"攻击","category":"攻击","element":"earth",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"stone_pellet_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"投射缓慢石弹，伤害 32；碰墙落点可破坏地形。",
		"skill":{"color":Color("b8a087"),"name":"崩石蛊","kind":"utility_projectile","cost":13,"cd":3,"dmg":32,"element":"earth","speed":260},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("b8a087")
	},
	"wind_shear": {
		"name":"剪风蛊","rank":1,"dao":"攻击","category":"攻击","element":"wind",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"wind_shear_care","origin":"原创蛊虫","shop":"shop","hint":"高速风刃伤害 15，最多贯穿三名生灵；不能穿墙。",
		"skill":{"color":Color("91d8cc"),"name":"剪风蛊","kind":"utility_projectile","cost":14,"cd":2.6,"dmg":15,"element":"wind","speed":620,"pierce":2},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("91d8cc")
	},
	"venom_gnat": {
		"name":"碧毒蚋","rank":1,"dao":"攻击","category":"攻击","element":"wood",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"venom_gnat_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"毒刺伤害 7，使人物或野外生灵中毒 5 秒，每秒追加 4 点伤害。",
		"skill":{"color":Color("a9ce68"),"name":"碧毒蚋","kind":"utility_projectile","cost":11,"cd":4,"dmg":7,"element":"wood","speed":350,"poison":5},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("a9ce68")
	},
	"red_lotus_moth": {
		"name":"红莲蛾","rank":2,"dao":"攻击","category":"攻击","element":"fire",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"red_lotus_moth_care","origin":"原创蛊虫","shop":"shop","hint":"扇射五枚莲火，各伤害 12、灼烧 3 秒；参与灭火、融冰与木质引燃。",
		"skill":{"color":Color("ed725b"),"name":"红莲蛾","kind":"utility_projectile","cost":110,"cd":4.5,"dmg":12,"element":"fire","speed":380,"count":5,"spread":0.14,"burn":3,"reaction":"fire"},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("ed725b")
	},
	"ice_lance": {
		"name":"冰棱蛊","rank":2,"dao":"控制","category":"控制","element":"water",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"ice_lance_care","origin":"原创蛊虫","shop":"bai_shop","hint":"冰棱伤害 28、减速 5 秒；湿身目标冻结 2 秒，落点结霜。",
		"skill":{"color":Color("a2e9f4"),"name":"冰棱蛊","kind":"utility_projectile","cost":100,"cd":4,"dmg":28,"element":"water","speed":590,"slow":5,"reaction":"frost"},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("a2e9f4")
	},
	"thunder_pupa": {
		"name":"雷芽蛊","rank":1,"dao":"控制","category":"控制","element":"thunder",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"thunder_pupa_care","origin":"原创蛊虫","shop":"shop","hint":"雷芽伤害 22，使目标步伐迟滞 0.8 秒（速度降至 20%）；仍可攻击。",
		"skill":{"color":Color("c3a0ed"),"name":"雷芽蛊","kind":"utility_projectile","cost":12,"cd":3.5,"dmg":22,"element":"thunder","speed":520,"bind":0.8},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("c3a0ed")
	},
	"thorn_seed": {
		"name":"棘籽蛊","rank":1,"dao":"控制","category":"控制","element":"wood",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"thorn_seed_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"扇射五枚棘籽，各伤害 5、束缚 1.5 秒；目标仍可攻击。",
		"skill":{"color":Color("91b873"),"name":"棘籽蛊","kind":"utility_projectile","cost":14,"cd":4.5,"dmg":5,"element":"wood","speed":320,"count":5,"spread":0.19,"bind":1.5},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("91b873")
	},
	"iron_drill": {
		"name":"铁钻蛊","rank":2,"dao":"攻击","category":"攻击","element":"metal",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"iron_drill_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"钻刺伤害 24，最多贯穿四名生灵；不能穿过地形。",
		"skill":{"color":Color("97a7b5"),"name":"铁钻蛊","kind":"utility_projectile","cost":120,"cd":3.2,"dmg":24,"element":"metal","speed":470,"pierce":3},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("97a7b5")
	},
	"rime_wing": {
		"name":"雾凇蛊","rank":2,"dao":"控制","category":"控制","element":"water",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"rime_wing_care","origin":"原创蛊虫","shop":"bai_shop","hint":"三枚霜羽各伤害 13、减速 5 秒；湿身冻结、落点结霜。",
		"skill":{"color":Color("d7ebf2"),"name":"雾凇蛊","kind":"utility_projectile","cost":100,"cd":4,"dmg":13,"element":"water","speed":410,"count":3,"spread":0.22,"slow":5,"reaction":"frost"},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("d7ebf2")
	},
	"blood_suture": {
		"name":"血络蛊","rank":1,"dao":"治疗","category":"治疗","element":"wood",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"blood_suture_care","origin":"原创蛊虫","shop":"shop","hint":"补回身体血量 10；不止血、不修复伤残、不解除致命伤。",
		"skill":{"color":Color("d98b8d"),"name":"血络蛊","kind":"blood_restore","cost":15,"cd":20,"dmg":0,"element":"wood","amount":10},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("d98b8d")
	},
	"warm_pupa": {
		"name":"暖脉蛊","rank":1,"dao":"治疗","category":"治疗","element":"fire",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"warm_pupa_care","origin":"原创蛊虫","shop":"bai_shop","hint":"解除自身迟缓与震颤；不恢复腿伤，也不免疫后续控制。",
		"skill":{"color":Color("edc18c"),"name":"暖脉蛊","kind":"clear_slow","cost":6,"cd":8,"dmg":0,"element":"fire"},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("edc18c")
	},
	"rain_pearl": {
		"name":"雨珠蛊","rank":1,"dao":"治疗","category":"治疗","element":"water",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"rain_pearl_care","origin":"原创蛊虫","shop":"bai_shop","hint":"立即熄灭身上灼烧；不恢复已经造成的伤势。",
		"skill":{"color":Color("8ecede"),"name":"雨珠蛊","kind":"extinguish","cost":6,"cd":8,"dmg":0,"element":"water"},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("8ecede")
	},
	"vigor_grub": {
		"name":"回劲蛊","rank":1,"dao":"辅助","category":"辅助","element":"earth",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"vigor_grub_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"恢复 30 体力，上限 100；不消除拉伤和身体负担。",
		"skill":{"color":Color("d8bf82"),"name":"回劲蛊","kind":"stamina_restore","cost":9,"cd":15,"dmg":0,"element":"earth","amount":30},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("d8bf82")
	},
	"spring_cocoon": {
		"name":"春茧蛊","rank":2,"dao":"治疗","category":"治疗","element":"wood",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"spring_cocoon_care","origin":"原创蛊虫","shop":"shop","hint":"对人体页选中的未毁损部位持续修复 2.5/秒，同时恢复气血 2/秒，持续 12 秒；受击中断，不能再生。",
		"skill":{"color":Color("b9ddb6"),"name":"春茧蛊","kind":"regrowth","cost":90,"cd":24,"dmg":0,"element":"wood","duration":12,"part_rate":2.5,"hp_rate":2},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("b9ddb6")
	},
	"reed_armor": {
		"name":"苇甲蛊","rank":1,"dao":"防御","category":"防御","element":"wood",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"reed_armor_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"苇甲吸收 20 点伤害，最多持续 18 秒；与其他壳甲、皮蛊互斥。",
		"skill":{"color":Color("c6bd86"),"name":"苇甲蛊","kind":"shell","cost":8,"cd":22,"dmg":0,"element":"wood","duration":18,"points":20},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("c6bd86")
	},
	"mirror_scale": {
		"name":"镜鳞蛊","rank":2,"dao":"防御","category":"防御","element":"metal",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"mirror_scale_care","origin":"原创蛊虫","shop":"bai_shop","hint":"镜鳞吸收 60 点伤害，最多持续 8 秒；与其他壳甲、皮蛊互斥。",
		"skill":{"color":Color("c8d8ed"),"name":"镜鳞蛊","kind":"shell","cost":100,"cd":16,"dmg":0,"element":"metal","duration":8,"points":60},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("c8d8ed")
	},
	"cinder_coat": {
		"name":"灰烬衣蛊","rank":1,"dao":"防御","category":"防御","element":"fire",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"cinder_coat_care","origin":"原创蛊虫","shop":"shop","hint":"10 秒内受到的火焰伤害减少 50%；不防其他伤害，不灭火。与抗寒蛊互斥。",
		"skill":{"color":Color("b7a29b"),"name":"灰烬衣蛊","kind":"resist","cost":10,"cd":18,"dmg":0,"element":"fire","duration":10,"resist_element":"fire","reduction":0.5},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("b7a29b")
	},
	"frost_ward": {
		"name":"寒绒蛊","rank":1,"dao":"防御","category":"防御","element":"water",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"frost_ward_care","origin":"原创蛊虫","shop":"bai_shop","hint":"10 秒内受到的水霜伤害减少 50%；不免疫控制。与灰烬衣互斥。",
		"skill":{"color":Color("c0dfeb"),"name":"寒绒蛊","kind":"resist","cost":10,"cd":18,"dmg":0,"element":"water","duration":10,"resist_element":"water","reduction":0.5},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("c0dfeb")
	},
	"quick_cricket": {
		"name":"疾踵蛊","rank":1,"dao":"移动","category":"移动","element":"wind",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"quick_cricket_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"短跑速度提高 75%，持续 3 秒；与其他加速蛊互斥，保留伤势与地形限制。",
		"skill":{"color":Color("c7d38c"),"name":"疾踵蛊","kind":"haste","cost":8,"cd":9,"dmg":0,"element":"wind","duration":3,"multiplier":1.75},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("c7d38c")
	},
	"cloud_locust": {
		"name":"云翅蝗","rank":2,"dao":"移动","category":"移动","element":"wind",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"cloud_locust_care","origin":"原创蛊虫","shop":"shop","hint":"行走速度提高 50%，持续 12 秒；与其他加速蛊互斥，不能穿墙。",
		"skill":{"color":Color("b7e1d2"),"name":"云翅蝗","kind":"haste","cost":90,"cd":20,"dmg":0,"element":"wind","duration":12,"multiplier":1.5},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("b7e1d2")
	},
	"water_skater": {
		"name":"踏波蛊","rank":1,"dao":"移动","category":"移动","element":"water",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"water_skater_care","origin":"原创蛊虫","shop":"bai_shop","hint":"12 秒内移除游泳带来的减速；仍受伤势、坡度和碰撞限制，不提供飞行。",
		"skill":{"color":Color("8fc4d2"),"name":"踏波蛊","kind":"swim","cost":9,"cd":18,"dmg":0,"element":"water","duration":12},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("8fc4d2")
	},
	"mist_butterfly": {
		"name":"烟叶蝶","rank":1,"dao":"移动","category":"移动","element":"wood",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"mist_butterfly_care","origin":"原创蛊虫","shop":"shop","hint":"10 秒内新发现你的距离降至 25%；攻击或受击打断，不消除已有追击。",
		"skill":{"color":Color("a9b2be"),"name":"烟叶蝶","kind":"veil","cost":10,"cd":17,"dmg":0,"element":"wood","duration":10,"detection":0.25},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("a9b2be")
	},
	"far_sight": {
		"name":"远睛蛊","rank":2,"dao":"侦察","category":"侦察","element":"none",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"far_sight_care","origin":"原创蛊虫","shop":"bai_shop","hint":"基础视野增加 300 像素，持续 8 秒；仍受眼伤限制，与萤瞳互斥。",
		"skill":{"color":Color("e0d7a6"),"name":"远睛蛊","kind":"vision","cost":70,"cd":18,"dmg":0,"element":"none","duration":8,"bonus":300},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("e0d7a6")
	},
	"earth_cicada": {
		"name":"地听蝉","rank":2,"dao":"侦察","category":"侦察","element":"earth",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"earth_cicada_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"在地表探明 1250 像素内未知地形；不凭空显示远处人物或领取资源。",
		"skill":{"color":Color("c4b695"),"name":"地听蝉","kind":"survey","cost":100,"cd":24,"dmg":0,"element":"earth","range":1250},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("c4b695")
	},
	"scent_ant": {
		"name":"寻材蚁","rank":1,"dao":"侦察","category":"侦察","element":"wood",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"scent_ant_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"寻找 1600 像素内最近且尚未采空的木石采集点，提示方向并探明该点地形。",
		"skill":{"color":Color("c9b28b"),"name":"寻材蚁","kind":"prospect","cost":6,"cd":14,"dmg":0,"element":"wood","range":1600},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("c9b28b")
	},
	"ore_mandible": {
		"name":"碎矿颚蛊","rank":1,"dao":"生计","category":"生计","element":"earth",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"ore_mandible_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"12 秒内石料采集点产量 3→6；与其他采集蛊互斥，不绕过刷新冷却。",
		"skill":{"color":Color("b5a18a"),"name":"碎矿颚蛊","kind":"harvest","cost":8,"cd":18,"dmg":0,"element":"earth","duration":12,"rubble_bonus":3,"timber_bonus":0},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("b5a18a")
	},
	"timber_mantis": {
		"name":"伐木螳","rank":2,"dao":"生计","category":"生计","element":"wood",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"timber_mantis_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"15 秒内木材采集点产量 3→7；与其他采集蛊互斥，保留采集冷却。",
		"skill":{"color":Color("a7c58a"),"name":"伐木螳","kind":"harvest","cost":70,"cd":24,"dmg":0,"element":"wood","duration":15,"timber_bonus":4,"rubble_bonus":0},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("a7c58a")
	},
	"gather_scarab": {
		"name":"拾荒蜣","rank":1,"dao":"生计","category":"生计","element":"earth",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"gather_scarab_care","origin":"原创蛊虫","shop":"shop","hint":"8 秒内木材、石料采集点均多得 2 份；不凭空生成资源，不重置冷却。",
		"skill":{"color":Color("d4b26e"),"name":"拾荒蜣","kind":"harvest","cost":10,"cd":16,"dmg":0,"element":"earth","duration":8,"timber_bonus":2,"rubble_bonus":2},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("d4b26e")
	},
	"burrow_grub": {
		"name":"凿岩蛊","rank":2,"dao":"生计","category":"生计","element":"earth",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"burrow_grub_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"发射凿岩弹，对生灵仅伤害 6，对碰到的地形造成 90 点基础破坏；遵守楼层与墙壁碰撞。",
		"skill":{"color":Color("c5a790"),"name":"凿岩蛊","kind":"utility_projectile","cost":80,"cd":3,"dmg":6,"element":"earth","speed":300,"terrain_damage":90},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("c5a790")
	},
	"soothing_moth": {
		"name":"舒筋蛊","rank":1,"dao":"治疗","category":"治疗","element":"wood",
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"soothing_moth_care","origin":"原创蛊虫","shop":"shop","hint":"身体负担减少 30、疼痛减少 15；不修复已经拉伤或毁损的部位。",
		"skill":{"color":Color("d6b3d5"),"name":"舒筋蛊","kind":"soothe","cost":8,"cd":16,"dmg":0,"element":"wood","strain":30,"pain":15},
		"flavor":"本作原创蛊虫；名称、外形、食性、用途与数值均为游戏设计。","color":Color("d6b3d5")
	},
	"stream_gu": {
		"name":"溪流蛊","rank":1,"dao":"攻击","category":"攻击","element":"water","color":Color("62c9dd"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":["5374581"],
		"preferred_food":"stream_gu_care","origin":"原著名录·玩法改编","shop":"bai_shop","hint":"溪流弹伤害 18，减速 3 秒。",
		"skill":{"name":"溪流冲击","kind":"utility_projectile","cd":1.2,"cost":8.0,"dmg":18.0,"element":"water","speed":390.0,"slow":3.0,"color":Color("62c9dd")},"flavor":"溪流蛊的名称与白家标志出自已核对正文；本版攻击、外形、食性与售价为改编。",
	},
	"ember_moth": {
		"name":"焰星蛊","rank":1,"dao":"攻击","category":"攻击","element":"fire","color":Color("ec8b52"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"ember_moth_care","origin":"原创蛊虫","shop":"shop","hint":"火弹伤害 20，灼烧 4 秒；仅命中的生灵受灼烧。",
		"skill":{"name":"焰星","kind":"utility_projectile","cd":2.0,"cost":10.0,"dmg":20.0,"element":"fire","speed":370.0,"burn":4.0,"color":Color("ec8b52")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"frost_midge": {
		"name":"霜针蛊","rank":1,"dao":"攻击","category":"攻击","element":"water","color":Color("a8ddeb"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"frost_midge_care","origin":"原创蛊虫","shop":"bai_shop","hint":"霜针伤害 15，可穿过一名目标，减速 4 秒；不能穿墙。",
		"skill":{"name":"霜针","kind":"utility_projectile","cd":2.0,"cost":12.0,"dmg":15.0,"element":"water","speed":570.0,"slow":4.0,"pierce":1,"color":Color("a8ddeb")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"vine_spider": {
		"name":"藤缚蛊","rank":1,"dao":"控制","category":"控制","element":"wood","color":Color("85b96e"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"vine_spider_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"藤种伤害 6，束缚 3 秒，移动降至 20%；目标仍可攻击。",
		"skill":{"name":"藤缚","kind":"utility_projectile","cd":5.0,"cost":12.0,"dmg":6.0,"element":"wood","speed":330.0,"bind":3.0,"color":Color("85b96e")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"mending_silk": {
		"name":"青丝缝伤蛊","rank":1,"dao":"治疗","category":"治疗","element":"wood","color":Color("aae0ba"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"mending_silk_care","origin":"原创蛊虫","shop":"shop","hint":"在人体页选择受伤部位；修复 14 耐久、恢复 6 气血。不能再生毁损部位、补血或解除致命颈伤。",
		"skill":{"name":"青丝缝伤","kind":"mend","cd":12.0,"cost":14.0,"dmg":0.0,"element":"wood","color":Color("aae0ba")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"resin_beetle": {
		"name":"松脂止血蛊","rank":1,"dao":"治疗","category":"治疗","element":"wood","color":Color("d9ab58"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"resin_beetle_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"封住流血最严重的一个伤口，不补血、不修复毁损部位。再次受伤可能重新出血。",
		"skill":{"name":"松脂封伤","kind":"hemostasis","cd":8.0,"cost":7.0,"dmg":0.0,"element":"wood","color":Color("d9ab58")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"dew_moth": {
		"name":"净露蛊","rank":1,"dao":"治疗","category":"治疗","element":"water","color":Color("b0e8df"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"dew_moth_care","origin":"原创蛊虫","shop":"bai_shop","hint":"解除当前中毒；不消除灼烧、出血、伤残或昏迷。",
		"skill":{"name":"净露洗毒","kind":"cleanse","cd":10.0,"cost":10.0,"dmg":0.0,"element":"water","color":Color("b0e8df")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"wind_moth": {
		"name":"逐风蛊","rank":1,"dao":"移动","category":"移动","element":"wind","color":Color("9bdfc0"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"wind_moth_care","origin":"原创蛊虫","shop":"shop","hint":"行走速度提高 35%，持续 8 秒；腿伤限制仍有效，不穿墙。",
		"skill":{"name":"逐风","kind":"haste","cd":14.0,"cost":10.0,"dmg":0.0,"element":"wind","duration":8.0,"color":Color("9bdfc0")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"night_firefly": {
		"name":"萤瞳蛊","rank":1,"dao":"侦察","category":"侦察","element":"none","color":Color("d9ec87"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"night_firefly_care","origin":"原创蛊虫","shop":"bai_shop","hint":"视野基础半径增加 180 像素，持续 12 秒；仍受眼伤限制。",
		"skill":{"name":"萤瞳","kind":"vision","cd":18.0,"cost":7.0,"dmg":0.0,"element":"none","duration":12.0,"color":Color("d9ec87")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"echo_cicada": {
		"name":"回声蛊","rank":1,"dao":"侦察","category":"侦察","element":"none","color":Color("9ab7dc"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"echo_cicada_care","origin":"原创蛊虫","shop":"shop","hint":"在地表探明半径 850 像素的地形迷雾；不显示视野外人物，不领取资源或完成踏查。",
		"skill":{"name":"回声探路","kind":"survey","cd":16.0,"cost":10.0,"dmg":0.0,"element":"none","color":Color("9ab7dc")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"gravel_shell": {
		"name":"砾壳蛊","rank":1,"dao":"防御","category":"防御","element":"earth","color":Color("c8b393"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"gravel_shell_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"形成可吸收 32 点伤害的护壳，最多 10 秒；与皮蛊护体互斥，不能叠加或提前续时。",
		"skill":{"name":"砾壳护身","kind":"shell","cd":18.0,"cost":14.0,"dmg":0.0,"element":"earth","duration":10.0,"color":Color("c8b393")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"bamboo_saw": {
		"name":"竹锯蛊","rank":1,"dao":"生计","category":"生计","element":"wood","color":Color("9fbd73"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"bamboo_saw_care","origin":"原创蛊虫","shop":"xiong_shop","hint":"持续 16 秒，木料采集点每次由 3 份增至 5 份；仍需靠近按 E，保留采集冷却，碎石不变。",
		"skill":{"name":"竹锯采集","kind":"harvest","cd":24.0,"cost":8.0,"dmg":0.0,"element":"wood","duration":16.0,"color":Color("9fbd73")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"veil_leaf": {
		"name":"枯叶隐息蛊","rank":1,"dao":"辅助","category":"辅助","element":"wood","color":Color("b5ad7b"),
		"hp":24.0,"atk":0.0,"spd":90.0,"radius":8.0,"ai":"flee","hunger_rate":1.0,"source":[],
		"preferred_food":"veil_leaf_care","origin":"原创蛊虫","shop":"shop","hint":"持续 10 秒，未警觉生灵与强盗发现距离降至 45%；不会抹去既有追击，攻击或受击打断。",
		"skill":{"name":"枯叶隐息","kind":"veil","cd":20.0,"cost":12.0,"dmg":0.0,"element":"wood","duration":10.0,"color":Color("b5ad7b")},"flavor":"本作原创蛊虫，外形、食性与数值均为游戏设计。",
	},
	"moon_glow": {
		"name":"月芒蛊", "rank":2, "dao":"月道", "element":"none", "color":Color("6aa9ff"),
		"hp":40.0,"atk":0.0,"spd":90.0,"radius":10.0,"ai":"flee",
		"preferred_food":"moon_glow_care","hunger_rate":1.0,"source":["5374657","5374665","5374667"],
		"skill":{"name":"月芒斩","kind":"proj","cd":0.8,"cost":60.0,"dmg":78.0,"speed":500.0,"projectile_radius":12.0,"color":Color("6aa9ff"),"element":"none","pierce":0,"poison":0.0,"burn":0.0},
		"flavor":"月光蛊与两只小光蛊合炼的二转攻击蛊，形如放大的蓝水晶弯月。攻击力为月光蛊的三倍；小光辅助不再额外叠乘。供养食材待考据。",
	},
	"white_jade": {
		"name":"白玉蛊", "rank":2, "dao":"防御", "element":"none", "color":Color("fff5d8"),
		"hp":45.0,"atk":0.0,"spd":80.0,"radius":9.0,"ai":"flee",
		"preferred_food":"jade","hunger_rate":1.0,"source":["5374657","5374658","5374659"],
		"skill":{"name":"白玉护体","kind":"skin_guard","cd":0.3,"cost":0.0,"dmg":0.0,"color":Color("fff5d8"),"upkeep":8.0,"hit_cost":1.8,"reduction":0.8},
		"flavor":"白豕蛊与玉皮蛊合炼，通体润白、状如椭圆玉石。防御强于玉皮；持续与受击均耗真元。二十日食玉八两。合炼不抹去已练成的肉身力量，也不继续代替白豕养力。",
	},
	"moon_raiment": {
		"name":"月霓裳", "rank":2, "dao":"防御", "element":"none", "color":Color("a3d8ff"),
		"hp":40.0,"atk":0.0,"spd":90.0,"radius":9.0,"ai":"flee",
		"preferred_food":"moon_raiment_care","hunger_rate":1.0,"source":["5374657","5374663","5374665"],
		"skill":{"name":"月衣庇护","kind":"skin_guard","cd":0.3,"cost":0.0,"dmg":0.0,"color":Color("a3d8ff"),"upkeep":7.0,"hit_cost":1.6,"reduction":0.7},
		"flavor":"月光蛊与玉皮蛊合炼，催动显现淡蓝雾衣和飘带。自护弱于白玉，还能帮助他人防御。鼠标指向近处非敌对行人可护持对方；无目标则护持自身。虫体图片为效果意象推导，食材待考据。",
	},
	"moon_blade": {
		"name":"月光蛊", "rank":1, "dao":"月道", "element":"none", "color":Color("8cbac5"),
		"hp":24.0, "atk":0.0, "spd":95.0, "radius":8.0, "ai":"flee",
		"preferred_food":"moon_petals", "hunger_rate":1.0, "source":["5374568","5374582"],
		"skill":{"name":"催发月刃","kind":"proj","cd":0.8,"cost":10.0,"dmg":26.0,"speed":460.0,"color":Color("93c7dd"),"element":"none","pierce":0,"poison":0.0,"burn":0.0},
		"flavor":"古月一族秘法培育的镇族蛊。以月兰花瓣为食。月刃是攻击形态，不是另一种蛊。",
	},
	"jiu_chong": {
		"name":"酒虫", "rank":1, "dao":"炼道", "element":"none", "color":Color("8cbac5"),
		"hp":24.0, "atk":0.0, "spd":95.0, "radius":8.0, "ai":"flee",
		"preferred_food":"bamboo_wine", "hunger_rate":1.0, "source":["5374576","5374640"],
		"skill":{"name":"精炼真元","kind":"refine_essence","cd":0.8,"cost":0.0,"dmg":0.0,"speed":460.0,"color":Color("93c7dd"),"element":"none","pierce":0,"poison":0.0,"burn":0.0},
		"flavor":"以酒为食。一次耗一成真元形成酒雾，再将另一成精炼为半成高一小阶真元；一转巅峰及二转真元不适用。",
	},
	"jade_skin": {
		"name":"玉皮蛊", "rank":1, "dao":"防御", "element":"none", "color":Color("8cbac5"),
		"hp":24.0, "atk":0.0, "spd":95.0, "radius":8.0, "ai":"flee",
		"preferred_food":"jade", "hunger_rate":1.0, "source":["5374622","5374659"],
		"skill":{"name":"维持玉皮","kind":"jade_guard","cd":0.8,"cost":0.0,"dmg":0.0,"speed":460.0,"color":Color("93c7dd"),"element":"none","pierce":0,"poison":0.0,"burn":0.0},
		"flavor":"持续灌注真元形成玉皮防御，承受攻击时另耗真元；停止供给即消退。食物为玉石。",
	},
	"little_light": {
		"name":"小光蛊", "rank":1, "dao":"辅助", "element":"none", "color":Color("eee7ca"),
		"hp":18.0, "atk":0.0, "spd":95.0, "radius":6.0, "ai":"flee",
		"preferred_food":"light_care", "hunger_rate":1.0, "source":["5374621","5374629"],
		"skill":{"name":"辅光月刃","kind":"light_support","cd":0.3,"cost":2.5,"dmg":0.0,"color":Color("eee7ca")},
		"flavor":"乳白五角星形，可寄居掌心。先开启辅光，再催月光蛊，月刃伤害与大小翻倍；需要同时为两只蛊支付真元。供养的具体食材尚待考据。",
	},
	"white_boar": {
		"name":"白豕蛊", "rank":1, "dao":"力道", "element":"none", "color":Color("f2eee0"),
		"hp":24.0, "atk":0.0, "spd":80.0, "radius":8.0, "ai":"flee",
		"preferred_food":"pork_ration", "hunger_rate":1.0, "source":["5374622","5374623","5374629","5374630"],
		"skill":{"name":"白豕养力","kind":"boar_training","cd":0.3,"cost":0.0,"dmg":0.0,"color":Color("f2eee0")},
		"flavor":"乳白色瓢虫，以猪肉为食。静处持续催动，逐渐增长永久肉身力量；蛊死后力量仍在。每日适量使用，不能无限叠加，也不提升修行境界。",
	},
	"black_boar": {
		"name":"黑豕蛊", "rank":1, "dao":"力道", "element":"none", "color":Color("8a94a5"),
		"hp":24.0, "atk":0.0, "spd":80.0, "radius":8.0, "ai":"flee",
		"preferred_food":"pork_ration", "hunger_rate":1.0, "source":["5374621","5374623"],
		"skill":{"name":"黑豕养力","kind":"boar_training","cd":0.3,"cost":0.0,"dmg":0.0,"color":Color("8a94a5")},
		"flavor":"黑、白豕蛊都能逐步改造身体、增长永久力量，以整猪肉供养。试玩中共用身体承受量与一猪之力上限；黑色甲虫外形为同系美术推导。",
	},
	"copper_skin": {
		"name":"铜皮蛊", "rank":1, "dao":"防御", "element":"none", "color":Color("c38043"),
		"hp":24.0, "atk":0.0, "spd":90.0, "radius":8.0, "ai":"flee",
		"preferred_food":"copper_skin_care", "hunger_rate":1.0, "source":["5374621","5374622"],
		"skill":{"name":"铜皮护体","kind":"skin_guard","cd":0.3,"cost":0.0,"dmg":0.0,"color":Color("c38043"),"upkeep":1.3,"hit_cost":0.45,"reduction":0.45},
		"flavor":"扁宽椭圆小虫，通体铜色。催动后皮肤泛黄，抵御伤害；同系皮蛊只维持一种，精确减伤与耗元为游戏参数。 具体食材尚待考据，暂用独立专用供养。",
	},
	"iron_skin": {
		"name":"铁皮蛊", "rank":1, "dao":"防御", "element":"none", "color":Color("727d89"),
		"hp":24.0, "atk":0.0, "spd":90.0, "radius":8.0, "ai":"flee",
		"preferred_food":"iron_skin_care", "hunger_rate":1.0, "source":["5374621","5374622"],
		"skill":{"name":"铁皮护体","kind":"skin_guard","cd":0.3,"cost":0.0,"dmg":0.0,"color":Color("727d89"),"upkeep":1.6,"hit_cost":0.5,"reduction":0.5},
		"flavor":"与铜皮同系，虫体泛黑铁冷光，催动形成皮肤防御。防御与真元负担的差异为试玩数值，不能和其他皮蛊叠加。 具体食材尚待考据，暂用独立专用供养。",
	},
	"stone_skin": {
		"name":"石皮蛊", "rank":1, "dao":"防御", "element":"none", "color":Color("9d9d90"),
		"hp":24.0, "atk":0.0, "spd":90.0, "radius":8.0, "ai":"flee",
		"preferred_food":"stone_skin_care", "hunger_rate":1.0, "source":["5374621","5374622"],
		"skill":{"name":"石皮护体","kind":"skin_guard","cd":0.3,"cost":0.0,"dmg":0.0,"color":Color("9d9d90"),"upkeep":0.9,"hit_cost":0.4,"reduction":0.35},
		"flavor":"灰扑扑的扁宽皮蛊，外形如石制小虫。维持真元护体，断供即失效；低价与防御参数为试玩安排。 具体食材尚待考据，暂用独立专用供养。",
	},
	"beast_skin": {
		"name":"兽皮蛊", "rank":1, "dao":"防御", "element":"none", "color":Color("b48550"),
		"hp":24.0, "atk":0.0, "spd":90.0, "radius":8.0, "ai":"flee",
		"preferred_food":"beast_skin_care", "hunger_rate":1.0, "source":["5374621","5374622"],
		"skill":{"name":"兽皮护体","kind":"skin_guard","cd":0.3,"cost":0.0,"dmg":0.0,"color":Color("b48550"),"upkeep":0.6,"hit_cost":0.3,"reduction":0.25},
		"flavor":"常见皮蛊，原著中价格低于石皮蛊。催动护体，供初学者选择；同系外形与皮革质感为美术推导，合炼路线尚未开放。 具体食材尚待考据，暂用独立专用供养。",
	},
	"brute_longhorn": {
		"name":"蛮力天牛蛊", "rank":1, "dao":"力道", "element":"none", "color":Color("b95835"),
		"hp":24.0, "atk":0.0, "spd":90.0, "radius":8.0, "ai":"flee",
		"preferred_food":"brute_longhorn_care", "hunger_rate":1.0, "source":["5374621","5374622"],
		"skill":{"name":"蛮力爆发","kind":"brute_force","cd":0.8,"cost":20.0,"dmg":0.0,"color":Color("b95835")},
		"flavor":"赤铁色天牛，粗触角有竹节。短暂赋予一牛之力，初阶耗两成真元；频繁使用可能拉伤肌肉，已有豕蛊力量能减轻模拟负担。 具体食材尚待考据，暂用独立专用供养。",
	},
	"yellow_camel": {
		"name":"黄骆天牛蛊", "rank":1, "dao":"辅助", "element":"none", "color":Color("c2a152"),
		"hp":24.0, "atk":0.0, "spd":90.0, "radius":8.0, "ai":"flee",
		"preferred_food":"yellow_camel_care", "hunger_rate":1.0, "source":["5374621","5374622"],
		"skill":{"name":"黄骆耐力","kind":"endurance","cd":0.8,"cost":8.0,"dmg":0.0,"color":Color("c2a152")},
		"flavor":"暗黄瘦长天牛，触角由黄渐黑、没有竹节。降低体力消耗约一刻钟；试玩映射为 15 秒疾步与腾跃省力，不回复真元或修复伤势。 具体食材尚待考据，暂用独立专用供养。",
	},
	"dragon_cricket": {
		"name":"龙丸蛐蛐蛊", "rank":1, "dao":"移动", "element":"none", "color":Color("7da48a"),
		"hp":24.0, "atk":0.0, "spd":90.0, "radius":8.0, "ai":"flee",
		"preferred_food":"dragon_cricket_care", "hunger_rate":1.0, "source":["5374621","5374622"],
		"skill":{"name":"蛐蛐腾跃","kind":"cricket_leap","cd":2,"cost":6.0,"dmg":0.0,"color":Color("7da48a")},
		"flavor":"帮助闪避的蛐蛐蛊。朝鼠标方向短距腾跃，遇障碍停止；需要可用双腿与体力，不附带伤害或无敌。具体距离、消耗和虫体细节为游戏表达。 具体食材尚待考据，暂用独立专用供养。",
	},
}
const GU_ORDER := ["moon_blade","jiu_chong","jade_skin","little_light","white_boar","black_boar","copper_skin","iron_skin","stone_skin","beast_skin","brute_longhorn","yellow_camel","dragon_cricket","moon_glow","white_jade","moon_raiment","stream_gu","ember_moth","frost_midge","vine_spider","mending_silk","resin_beetle","dew_moth","wind_moth","night_firefly","echo_cicada","gravel_shell","bamboo_saw","veil_leaf","golden_splinter","stone_pellet","wind_shear","venom_gnat","red_lotus_moth","ice_lance","thunder_pupa","thorn_seed","iron_drill","rime_wing","blood_suture","warm_pupa","rain_pearl","vigor_grub","spring_cocoon","reed_armor","mirror_scale","cinder_coat","frost_ward","quick_cricket","cloud_locust","water_skater","mist_butterfly","far_sight","earth_cicada","scent_ant","ore_mandible","timber_mantis","gather_scarab","burrow_grub","soothing_moth","clear_origin_silkworm","deep_spring_butterfly","marrow_lotus_beetle","nine_aurora_cocoon","bronze_relic","red_iron_relic","silver_relic","gold_relic","purple_relic","quiet_incense_moth","wall_polish_snail","copper_fletch","sand_fang","rain_needle","obsidian_mantis","storm_hornet","sun_ember_scarab","glacier_centipede","bark_bastion","quartz_tortoise","thunder_insulator","basalt_heart","prism_aegis","scar_stitch","red_dew_tick","calm_bell_moth","purifying_lacewing","return_spring_silk","grass_skipper","river_fin","gale_kite_moth","shadow_step_spider","lantern_antenna","ore_echo_cicada","horizon_owl_moth","deep_resonance_beetle","reed_cutter","flint_mason","amber_resin_ant","mountain_borer","iron_bone","jade_bone","vitality_leaf","self_reliance","tempered_sinew","clot_thread","numb_ant","lucid_larva","sinew_spring","feather_marrow","ballast_bone","scar_crust","red_pulse","lung_bell","bitter_liver","warm_muscle","nerve_lantern","clear_cornea","ear_suture","joint_mender"]
const GU_SHOP := {"iron_bone":1800,"jade_bone":1800,"vitality_leaf":180,"self_reliance":1800,"tempered_sinew":1800,"clot_thread":650,"numb_ant":180,"lucid_larva":650,"sinew_spring":650,"feather_marrow":650,"ballast_bone":650,"scar_crust":180,"red_pulse":650,"lung_bell":180,"bitter_liver":650,"warm_muscle":180,"nerve_lantern":650,"clear_cornea":650,"ear_suture":180,"joint_mender":650,"clear_origin_silkworm":9000,"deep_spring_butterfly":9000,"marrow_lotus_beetle":18000,"nine_aurora_cocoon":18000,"bronze_relic":360,"red_iron_relic":1300,"silver_relic":3600,"gold_relic":9000,"purple_relic":18000,"quiet_incense_moth":650,"wall_polish_snail":1800,"copper_fletch":180,"sand_fang":650,"rain_needle":650,"obsidian_mantis":1800,"storm_hornet":1800,"sun_ember_scarab":4500,"glacier_centipede":9000,"bark_bastion":650,"quartz_tortoise":1800,"thunder_insulator":1800,"basalt_heart":4500,"prism_aegis":9000,"scar_stitch":180,"red_dew_tick":650,"calm_bell_moth":1800,"purifying_lacewing":4500,"return_spring_silk":9000,"grass_skipper":180,"river_fin":650,"gale_kite_moth":1800,"shadow_step_spider":4500,"lantern_antenna":180,"ore_echo_cicada":650,"horizon_owl_moth":1800,"deep_resonance_beetle":4500,"reed_cutter":180,"flint_mason":650,"amber_resin_ant":1800,"mountain_borer":4500,"golden_splinter":180,"stone_pellet":180,"wind_shear":180,"venom_gnat":180,"red_lotus_moth":650,"ice_lance":650,"thunder_pupa":180,"thorn_seed":180,"iron_drill":650,"rime_wing":650,"blood_suture":180,"warm_pupa":180,"rain_pearl":180,"vigor_grub":180,"spring_cocoon":650,"reed_armor":180,"mirror_scale":650,"cinder_coat":180,"frost_ward":180,"quick_cricket":180,"cloud_locust":650,"water_skater":180,"mist_butterfly":180,"far_sight":650,"earth_cicada":650,"scent_ant":180,"ore_mandible":180,"timber_mantis":650,"gather_scarab":180,"burrow_grub":650,"soothing_moth":180,"stream_gu":85,"ember_moth":90,"frost_midge":110,"vine_spider":100,"mending_silk":120,"resin_beetle":70,"dew_moth":100,"wind_moth":100,"night_firefly":75,"echo_cicada":90,"gravel_shell":95,"bamboo_saw":65,"veil_leaf":105,"moon_blade":80,"jade_skin":500,"little_light":60,"white_boar":600,"black_boar":600,"copper_skin":120,"iron_skin":180,"stone_skin":80,"beast_skin":50,"brute_longhorn":200,"yellow_camel":250,"dragon_cricket":220}
const EXPANSION_GU := ["copper_skin","iron_skin","stone_skin","beast_skin","brute_longhorn","yellow_camel","dragon_cricket"]

const UTILITY_GU := ["stream_gu", "ember_moth", "frost_midge", "vine_spider", "mending_silk", "resin_beetle", "dew_moth", "wind_moth", "night_firefly", "echo_cicada", "gravel_shell", "bamboo_saw", "veil_leaf"]

const SIXTY_GU := ["golden_splinter", "stone_pellet", "wind_shear", "venom_gnat", "red_lotus_moth", "ice_lance", "thunder_pupa", "thorn_seed", "iron_drill", "rime_wing", "blood_suture", "warm_pupa", "rain_pearl", "vigor_grub", "spring_cocoon", "reed_armor", "mirror_scale", "cinder_coat", "frost_ward", "quick_cricket", "cloud_locust", "water_skater", "mist_butterfly", "far_sight", "earth_cicada", "scent_ant", "ore_mandible", "timber_mantis", "gather_scarab", "burrow_grub", "soothing_moth"]

const HUNDRED_GU := ["clear_origin_silkworm","deep_spring_butterfly","marrow_lotus_beetle","nine_aurora_cocoon","bronze_relic","red_iron_relic","silver_relic","gold_relic","purple_relic","quiet_incense_moth","wall_polish_snail","copper_fletch","sand_fang","rain_needle","obsidian_mantis","storm_hornet","sun_ember_scarab","glacier_centipede","bark_bastion","quartz_tortoise","thunder_insulator","basalt_heart","prism_aegis","scar_stitch","red_dew_tick","calm_bell_moth","purifying_lacewing","return_spring_silk","grass_skipper","river_fin","gale_kite_moth","shadow_step_spider","lantern_antenna","ore_echo_cicada","horizon_owl_moth","deep_resonance_beetle","reed_cutter","flint_mason","amber_resin_ant","mountain_borer"]

const BODY_GU := ["iron_bone","jade_bone","vitality_leaf","self_reliance","tempered_sinew","clot_thread","numb_ant","lucid_larva","sinew_spring","feather_marrow","ballast_bone","scar_crust","red_pulse","lung_bell","bitter_liver","warm_muscle","nerve_lantern","clear_cornea","ear_suture","joint_mender"]

static func is_utility_gu(id: String) -> bool:
	return UTILITY_GU.has(id) or SIXTY_GU.has(id) or HUNDRED_GU.has(id) or BODY_GU.has(id)

static func shop_gu_ids(shop: String) -> Array[String]:
	var result:Array[String]=[]
	for id in GU_SHOP:
		if GU[id].get("shop","shop")==shop: result.append(id)
	return result

static func utility_food_stock() -> Dictionary:
	var stock:Dictionary={}
	for id in UTILITY_GU+SIXTY_GU+HUNDRED_GU+BODY_GU: stock[GU[id].preferred_food]=1
	return stock

static func shop_name(id: String) -> String:
	return {"shop":"古月商铺","bai_shop":"白家商铺","xiong_shop":"熊家商铺"}.get(GU[id].get("shop","shop"),"商铺")

static func gu_category(id: String) -> String:
	if GU[id].has("category"): return GU[id].category
	var kind:String=GU[id].skill.kind
	if kind in ["jade_guard","skin_guard"]: return "防御"
	if kind in ["boar_training","brute_force"]: return "力量"
	if kind=="cricket_leap": return "移动"
	if kind=="proj": return "攻击"
	return "辅助"

static func activation_hint(id: String, stage: int = 0, rank: int = 1) -> String:
	if rank<1: return "凡人尚无空窍和真元；需先借希望蛊开窍，之后才能炼化、催动。"
	var potency:=pow(2.0,stage)*pow(10.0,rank-1)
	var skill:Dictionary=GU.get(id,{}).get("skill",{})
	if skill.get("kind","")=="relic": return GU[id].hint
	if GU.get(id,{}).has("hint"):
		return GU[id].hint+" 耗普通真元 %.2f 点，冷却 %.1f 秒，同类蛊共用冷却。" % [float(skill.cost)/potency,float(skill.cd)]
	if skill.get("kind","")=="skin_guard":
		return "维持每秒耗普通真元 %.2f 点；每点来袭伤害另耗 %.3f 点，减伤 %.0f%%。与其他护体互斥；断供失效。" % [float(skill.upkeep)/potency,float(skill.hit_cost)/potency,float(skill.reduction)*100]+(" 鼠标指向 180 像素内的非敌对行人可庇护对方；再次催动关闭。" if id=="moon_raiment" else "")
	match id:
		"moon_glow": return "月刃伤害 26→78（3 倍），冷却 0.8 秒；当前真元每次 %.2f 点。需二转修为；小光不再额外增幅。" % (60.0/potency)
		"brute_longhorn": return "一次耗普通真元 %.2f 点，肉身攻击 +22，持续 5 秒。不能叠加；身体负担过高会拉伤，C 页可查看。不会增加月刃伤害或永久力量。" % (20.0/potency)
		"yellow_camel": return "一次耗普通真元 %.2f 点，持续 15 秒，疾步与蛐蛐腾跃的体力消耗降至 40%%。不能叠加或提前续时。" % (8.0/potency)
		"dragon_cricket": return "朝鼠标腾跃最多 112 像素，耗普通真元 %.2f 点 和体力 20，冷却 2 秒。墙壁挡路；重伤腿无法使用，无攻击或无敌效果。" % (6.0/potency)
		"moon_blade": return "当前小阶普通真元：每次 %.2f 点。高一小阶真元效力翻倍。" % (10.0/potency)
		"jiu_chong": return "每次共耗两成未精炼真元，得到半成高一小阶真元。只能作用于一转初、中、高阶。"
		"jade_skin": return "维持每秒耗普通真元 %.2f 点；每点来袭伤害另耗 %.3f 点，减伤 60%%。真元不足时防御消退。" % [1.0/potency,0.35/potency]
		"little_light": return "开启后催月刃：伤害 26→52，弹体大小 ×2；总耗普通真元 %.2f 点。多只不叠加；再次催动关闭。" % (12.5/potency)
		"white_boar", "black_boar": return "静处每秒耗普通真元 %.2f 点，力量进度 +2%%；每日合计最多 15 秒。达到一猪之力后停止；不增加月刃伤害。再次催动收功。" % (1.0/potency)
	return ""

static func rank_name(r: int) -> String:
	return "蛊师" if r <= 5 else "蛊仙"

static func xp_next(_r: int) -> float:
	return 100.0 # 兼容旧显示接口；实际含义为窍壁温养百分比。

static func el_color(el: String) -> Color:
	return EL_COLOR.get(el, Color("cfd8cf"))

static func el_name(_el: String) -> String:
	return "蛊虫具体效用"
