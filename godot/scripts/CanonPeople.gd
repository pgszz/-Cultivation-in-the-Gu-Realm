class_name CanonPeople
extends RefCounted

## Early Qing Mao visual snapshots. Routes/dialogue/combat values are sandbox design.
const ORDER := ["canon_fang_yuan","canon_fang_zheng","canon_bai_ning_bing","canon_qing_shu"]
const SOURCES := {
	"twins":{"title":"第一卷第二节 · 逆光阴五百年觉悟","url":"https://czbooks.net/n/u30h/ujch9","note":"方正清瘦、略矮，面貌与方源极像；习惯低头。方源惯常冷漠。"},
	"qingshu":{"title":"第一卷第一百零四节 · 想买酒虫？","url":"https://www.sobqg.com/read/guzhenren/18153074.html","note":"青书青色长发、面色白皙、脸部线条柔和，笑容温和而自信；照顾组员。"},
	"bai":{"title":"第一卷第一百三十一节 · 孤独是最深邃的黑暗","url":"https://www.sobqg.com/read/guzhenren/18153101.html","note":"白凝冰是白发白衣的少年，旁观争斗，偏好山泉而非酒。"},
	"eyes":{"title":"第一卷第一百三十三节 · 谢谢你让我杀你","url":"https://www.sobqg.com/read/guzhenren/18153103.html","note":"方源黑眸、冷静；白凝冰兴奋求战时，双眼由黑转为蓝色。"}
}
const PEOPLE := {
	"canon_fang_yuan":{
		"name":"古月方源","clan":"guyue","faction":"古月山寨","title":"古月族人","period":"青茅山少年形象",
		"look":"黑眸，表情冷静；与方正保持相似的五官，以沉静站姿区分。",
		"inference":"墨色交领衣、束发方式、布褶与动作幅度是本作美术补充，不是原著指定制服。",
		"summary":"少言而冷静，对自己的去路有明确打算。","sources":["twins","eyes"],"scale":1.0,
		"home":Vector2(400,1168),"route":[Vector2(400,1168),Vector2(816,1008),Vector2(752,1328)],"stops":["古月竹楼外","古月东街","寨南竹路"],
		"greeting":"有事就说。我还有自己的事情。","familiar":"又是你。说说来意。","hurt":"这点伤，我会处理。有事直说。","wary":"还有事？先前的账，我记着。",
		"life":"走自己的路。至于旁人的议论，听得再多也不能替我做决定。",
		"terrain":"先看退路，再看眼前能得什么。没有把握，就别把性命赌在一块陌生的山石上。",
		"cultivation":"资质决定起点，筹划决定你怎样走下去。供养、真元、退路，都该先算清楚。",
		"care":"这份人情，我记下了。","bubble":"有事直说。"
	},
	"canon_fang_zheng":{
		"name":"古月方正","clan":"guyue","faction":"古月山寨","title":"古月族人","period":"开篇少年形象",
		"look":"方源的孪生弟弟；面貌极相似，身形清瘦、略矮，微垂目光。",
		"inference":"灰蓝衣服与浅色腰带是辨识配色；拘谨姿态取自开篇，未混入后期仙鹤门形象。",
		"summary":"与哥哥相貌相似，交谈时略显拘谨，也希望能走出自己的路。","sources":["twins"],"scale":0.94,
		"home":Vector2(720,1296),"route":[Vector2(720,1296),Vector2(528,1008),Vector2(400,1264)],"stops":["古月学堂外","寨中街巷","竹楼南路"],
		"greeting":"你……是在找我吗？我叫方正。","familiar":"你来了。这次想问些什么？","hurt":"我还撑得住……让我缓一缓。","wary":"上次的事情还没说清楚。我现在不太敢相信你。",
		"life":"刚才还在想学堂里讲的事情。大家总提起哥哥，我也想把自己的事情做好。",
		"terrain":"我对寨里的路比较熟。真要往远山去，我会先问清楚沿路有没有可以歇脚的地方。",
		"cultivation":"学堂讲过，空窍要一点点温养。我会认真记着，也想靠自己做好。",
		"care":"谢谢你……我会小心些的。","bubble":"你找我吗？"
	},
	"canon_bai_ning_bing":{
		"name":"白凝冰","clan":"bai","faction":"白家寨","title":"白家天才","period":"青茅山前期 · 男性人族",
		"look":"白发白衣的少年；常态黑瞳，出手姿态显蓝眸，神情疏冷。",
		"inference":"衣领、腰带、发束和招式姿态为美术补充；未采用后期女性、龙人或独臂形象。",
		"summary":"厌倦平淡，谈起有趣的争斗时才显出兴致。","sources":["bai","eyes"],"scale":1.02,
		"home":GameData.BAI_VILLAGE+Vector2(160,64),"route":[GameData.BAI_VILLAGE+Vector2(160,64),GameData.BAI_VILLAGE+Vector2(160,384),GameData.BAI_VILLAGE+Vector2(-160,672)],"stops":["白家寨东街","白家演武路","白家南路"],
		"greeting":"找我？希望你带来的不是无聊的闲话。","familiar":"又碰见你了。有什么有趣的事？","hurt":"疼痛倒让人清醒。你有什么事？","wary":"上回还没尽兴，你又来了。",
		"life":"走走，看看。若总是一样的面孔、一样的日子，岂不乏味。",
		"terrain":"险路至少比一成不变的街巷有趣。你若只是问路，沿寨里的道路走就是了。",
		"cultivation":"光问别人怎么走，没有什么意思。你自己的本事，终究要由你自己去试。",
		"care":"呵，你倒肯费这个工夫。","bubble":"有什么有趣的事？"
	},
	"canon_qing_shu":{
		"name":"古月青书","clan":"guyue","faction":"古月山寨","title":"蛊师小组组长","period":"青茅山 · 常态人形",
		"look":"青色长发、白皙面容，脸部线条柔和；温和而自信的微笑。",
		"inference":"青绿衣装、米色腰带和稍高的轮廓为美术补充；未把木魅变化后的树皮当作日常皮肤。",
		"summary":"待人温和，做事有主见，关心同伴和寨子的安危。","sources":["qingshu"],"scale":1.06,
		"home":Vector2(528,784),"route":[Vector2(528,784),Vector2(816,1008),Vector2(816,1264),Vector2(336,944)],"stops":["祠堂南街","古月东街","学堂路口","药堂外"],
		"greeting":"慢慢说。是路上遇到了麻烦，还是想问寨里的事情？","familiar":"又见面了。这一路还顺利吗？","hurt":"别担心，我先处理伤口。你也照看好自己。","wary":"事情既然发生了，就把话说清楚。信任总要慢慢补回来。",
		"life":"看看寨里的路，也看看有没有人需要照应。同伴各有长处，做事还是要彼此商量。",
		"terrain":"进山前备好补给，同行时别只顾自己往前。有人跟不上，就停一停，先看清路况。",
		"cultivation":"修行和休息都要顾到。练习用蛊时先熟悉自己的真元，不要勉强透支，更不要伤到同行的人。",
		"care":"多谢照应。你自己的伤也别耽搁了。","bubble":"路上可还顺利？"
	}
}

static func has(id: String) -> bool:
	return PEOPLE.has(id)

static func definitions() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id in ORDER:
		var data:Dictionary=PEOPLE[id]
		result.append({"id":id,"name":data.name,"clan":data.clan,"faction":data.faction,"role":"cultivator","appearance":id,"route":data.route,"stops":data.stops,"wait":12.0})
	return result

static func lore(id: String) -> String:
	if not has(id): return ""
	var data:Dictionary=PEOPLE[id]
	var text:="[color=#d8bc7c]%s · %s[/color]\n\n原著外貌\n%s\n\n美术补充\n%s\n\n[color=#d8bc7c]正文依据[/color]\n" % [data.name,data.period,data.look,data.inference]
	for source in data.sources:
		text+="\n%s\n%s\n" % [SOURCES[source].title,SOURCES[source].note]
	return text+"\n[color=#93a99f]此处是前期外貌切片；共存、活动路线和交谈是自由探索改编，不表示原著同一天发生的事件。当前接入外观与徒手自卫，未还原人物完整蛊虫配置与剧情。[/color]"

static func greeting(person: Npc) -> String:
	var data:Dictionary=PEOPLE[person.resident_id]
	person.social.ensure(person)
	if person.hp<person.max_hp*0.5: return data.hurt
	if person.social.affinity<0: return data.wary
	return data.familiar if not person.conversation.is_empty() else data.greeting

static func reply(game: Node, person: Npc, topic: String) -> String:
	var data:Dictionary=PEOPLE[person.resident_id]
	if topic=="road":
		game.set_waypoint(data.home,data.stops[0]+" · "+data.name,false,0)
		return "我常在%s一带走动。位置记在山志上了，沿路过来就能找到这一带。" % data.stops[0]
	return data.get(topic,"")

static func bond(id: String, other: String) -> String:
	if id=="canon_fang_yuan" and other=="canon_fang_zheng": return "孪生弟弟 · 原著"
	if id=="canon_fang_zheng" and other=="canon_fang_yuan": return "孪生兄长 · 原著"
	return ""
