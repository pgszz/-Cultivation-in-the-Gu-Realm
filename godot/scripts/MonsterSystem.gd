class_name MonsterSystem
extends Node2D

## 妖兽系统 - 对话、招募与战斗
## 对应文档：妖兽系统设计.md

signal monster_dialogue_started(monster_id: String)
signal monster_relationship_changed(monster_id: String, relationship: int)
signal monster_recruited(monster_id: String)

# 用户要求的沙盒妖兽；独立于下方退役妖将/妖王表，不宣称原著分级。
const WILDLIFE := {
	"green_wolf":{"name":"青狼妖","hp":130,"atk":22,"drops":["wolf_meat","green_wolf_fur"]},
	"iron_bear":{"name":"铁背妖熊","hp":210,"atk":30,"drops":["bear_meat","iron_back"]},
}

const MONSTERS := {
	# 初级妖兽
	"green_wolf": {
		"name": "青狼妖", "level": "beast", "years": 20, "hp": 500, "atk": 150,
		"meat_restore": 60, "dao_bonus": {"力": 30},
		"personality": "凶猛", "can_talk": false,
		"drops": ["wolf_demon_meat", "green_wolf_pearl"]
	},

	# 妖将
	"silver_wolf": {
		"name": "银月狼将", "level": "general", "years": 80, "hp": 1500, "atk": 300,
		"meat_restore": 100, "dao_bonus": {"力": 50},
		"personality": "孤傲", "can_talk": true,
		"drops": ["wolf_demon_meat", "silver_moon_pearl"],
		"dialogue": {
			"first_meet": "人类？好久没见过活着的人类了。",
			"trade": "你有什么能换我的东西？",
			"battle": "既然如此，那就战吧！"
		}
	},

	# 妖王
	"nine_tail_fox": {
		"name": "九尾狐王", "level": "king", "years": 500, "hp": 5000, "atk": 1000,
		"meat_restore": 180, "dao_bonus": {"变": 80},
		"personality": "狡诈", "can_talk": true,
		"drops": ["fox_demon_meat", "nine_tail"],
		"recruitable": true,
		"dialogue": {
			"first_meet": "有趣，居然有人类敢走进青丘山。",
			"trade": "这个我要了，你想要什么？",
			"recruit": "血契？你确定要和我签订血契？"
		}
	},
}

const MEAT_DEMON := {
	"wolf_demon_meat": {"name": "妖狼肉", "restore": 60, "dao_bonus": 30, "exp_bonus": 100},
	"fox_demon_meat": {"name": "妖狐肉", "restore": 180, "dao_bonus": 80, "exp_bonus": 500},
}

class MonsterInstance:
	var monster_id: String
	var position: Vector2
	var hp: float
	var max_hp: float
	var relationship: int = 0  # -100到100
	var is_alive: bool = true
	var is_recruited: bool = false

func spawn_monster(monster_id: String, pos: Vector2) -> MonsterInstance:
	var data = MONSTERS[monster_id]
	var instance = MonsterInstance.new()
	instance.monster_id = monster_id
	instance.position = pos
	instance.max_hp = data.hp
	instance.hp = data.hp
	return instance

func start_dialogue(instance: MonsterInstance, dialogue_type: String = "first_meet") -> String:
	var data = MONSTERS[instance.monster_id]

	if not data.can_talk:
		return "[无法沟通]"

	if data.has("dialogue") and data.dialogue.has(dialogue_type):
		monster_dialogue_started.emit(instance.monster_id)
		return data.dialogue[dialogue_type]

	return "..."

func change_relationship(instance: MonsterInstance, amount: int):
	instance.relationship = clamp(instance.relationship + amount, -100, 100)
	monster_relationship_changed.emit(instance.monster_id, instance.relationship)

func can_recruit(instance: MonsterInstance) -> bool:
	var data = MONSTERS[instance.monster_id]

	if not data.get("recruitable", false):
		return false

	if instance.relationship < 60:
		return false

	return true

func recruit_monster(instance: MonsterInstance) -> bool:
	if not can_recruit(instance):
		return false

	instance.is_recruited = true
	monster_recruited.emit(instance.monster_id)
	return true

func get_relationship_status(relationship: int) -> String:
	if relationship >= 81:
		return "挚友"
	elif relationship >= 61:
		return "亲密"
	elif relationship >= 31:
		return "友好"
	elif relationship >= 1:
		return "中立"
	elif relationship >= -49:
		return "敌对"
	else:
		return "仇恨"

func get_demon_meat_restore(meat_id: String, gu_dao: String = "") -> Dictionary:
	var meat = MEAT_DEMON.get(meat_id)
	if not meat:
		return {"restore": 0.0, "dao_bonus": 0, "exp_bonus": 0}

	var result = {
		"restore": float(meat.restore),
		"dao_bonus": meat.dao_bonus,
		"exp_bonus": meat.exp_bonus
	}

	return result
