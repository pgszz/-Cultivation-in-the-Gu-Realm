class_name NpcConversation
extends RefCounted

const TOPICS := {"life":"近来在忙什么？","road":"附近怎么走？","terrain":"山里有什么要留心的？","cultivation":"请教修行与真元"}

static func greeting(game: Node, person: Npc) -> String:
	if CanonPeople.has(person.resident_id): return CanonPeople.greeting(person)
	if person.hp<person.max_hp*0.5: return "先容我歇口气……这伤还没好。你是来问路，还是有事找我？"
	person.social.ensure(person)
	if person.social.affinity>=30: return "是你来了，快来歇歇脚。承蒙一路照应，有什么事尽管说。"
	if person.social.affinity<0: return "先把话说清楚。先前的事我还记着，没那么容易放下戒心。"
	if game.player.swimming: return "水里走得慢，先上岸再慢慢说。"
	if game.player.hp<game.player.max_hp*0.5: return "你脸色不太好。伤口包扎过了吗？别硬撑着走山路。"
	var familiar:=not person.conversation.is_empty()
	var night:bool=fmod(game.day_time,180.0)/180.0>0.65
	if person is WorldPerson:
		if person.role=="merchant": return "又见面了，货还在车上。要补给，还是聊聊路上的事？" if familiar else "这一路可不近。货物都带着呢，你想买东西，还是问路？"
		if person.role in ["guard","escort"]: return "我还得看着这条路，有事尽管问，别走散了。"
		if person.activity.contains("休"): return "正好歇歇脚，坐一会儿？山路走久了，腿脚也吃不消。"
	return ("又碰面了。" if familiar else "这位道友，且慢些走。")+("夜里视线差，有事就在这里说。" if night else "今日山风不小，你要往哪里去？")

static func reply(game: Node, person: Npc, topic: String) -> String:
	var blocker:String=game.person_talk_blocker(person)
	if blocker!="": return blocker
	if not TOPICS.has(topic) and topic!="care": return ""
	var repeated:=person.conversation.has(topic)
	var result:=""
	if CanonPeople.has(person.resident_id) and topic!="care":
		result=CanonPeople.reply(game,person,topic)
	else:
		match topic:
			"life":
				if person is WorldPerson:
					var destination:String=person.route_names[person.route_index] if not person.route_names.is_empty() else "前面的歇脚处"
					result={"merchant":"把补给运到下一处寨子。路上得靠护卫照看，买卖也要留足周转的元石。","guard":"沿寨边巡看，遇上劫道的便拦住。你若有伤，先回药堂。","escort":"照看商队。有人落后就得等，可不能只顾自己走。","villager":"在寨中办些日常杂事。赶路累了，也会停下来歇脚。"}.get(person.role,"走一趟山路，讨个生活。")
					result+="\n眼下%s，下一站是%s。" % [person.activity,destination]
				else:
					var profile:=person.inspection_profile()
					result="平日就在%s，负责%s。来往的人多了，自然也能记住几张面孔。" % [profile.place,profile.duty]
				if person.hp<person.max_hp: result+="\n只是这阵子带着伤，做事慢了些。"
			"road":
				var target:Dictionary={}
				var best:=INF
				for entrance in TerrainLayers.ENTRANCES:
					var distance:float=person.position.distance_to(entrance.pos)
					if distance<best:
						best=distance
						target=entrance
				game.set_waypoint(target.pos,target.name,false,0)
				result="离这一带较近的是%s。我给你记在山志上了；沿标记走，到入口按 E 下去。地下石阶还能通往更深处。" % target.name
			"terrain": result="爬山别着急，高处一格格上，走得慢些。岩块可以用月刃或蛊术开凿，瞄准脚下附近的地面也能打。\n河里能游，但深水费脚程。溪流可灭火，霜针能冻住水面；焰星会融冰，也会点着木头。"
			"cultivation": result="蓝条看的是你自己的元海装满了多少。比如 44 / 44 就是满真元；四成四说的是资质决定的空窍容量。\n催蛊看每次耗多少点，元海不足便收手。养窍靠打坐温养，可不是靠杀多少野物。"
			"care":
				if person.hp>=person.max_hp: return "多谢好意，我没受伤。绷带留着路上用吧。"
				var inv:Inventory=game.get_node("/root/Inv")
				if not inv.has_item("bandage",1): return "你身上也没有绷带，别勉强。去药堂或商铺补一些吧。"
				inv.remove_item("bandage",1)
				person.hp=minf(person.max_hp,person.hp+18.0)
				game.fx.text(person.position.x,person.position.y-30,"包扎 +18",UIStyle.JADE)
				result="这绷带来得及时，多谢了。我记着你这份心意。"
	if topic=="care" and CanonPeople.has(person.resident_id): result=CanonPeople.PEOPLE[person.resident_id].care
	person.social.conversation_event(person,topic)
	person.conversation[topic]=true
	person.facing=(game.player.position-person.position).angle()
	person.speech="多谢照应。" if topic=="care" else "路上多留心。"
	if CanonPeople.has(person.resident_id): person.speech=CanonPeople.PEOPLE[person.resident_id].bubble
	person.speech_left=3.0
	game.save_game()
	return ("上回也说起过这事。\n" if repeated and topic!="care" else "")+result
