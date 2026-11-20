class_name SouthernBorderData
extends RefCounted

## 地理志坐标，与 World 的可行走格子无关。只有方位关系来自正文，曲线和间距是读者推演。
const EXTENT := Vector2(1200,900)
const ERA := "青茅山前期 · 后文只补地名与族名，剧情变局不提前发生"
const SOURCES := {
	"qingmao":{"title":"第一卷 1、22、147：青茅山三寨","url":"https://www.bilixs.com/novel/guzhenren/5374581.html","kind":"正文","scope":"古月、白、熊三族和标志蛊；山脚位置另见 CANON 第一卷 147。"},
	"yellow":{"title":"第二卷《黄龙江上竹筏倾》","url":"https://www.sobqg.com/read/guzhenren/18153170.html","kind":"正文","scope":"黄果山为源，依次提及玄冥、龟背、青茅、白骨、雷磁；黄龙江形如几字。"},
	"rivers":{"title":"《柴家有人烟》","url":"https://www.8xiaoshuo.com/shu_23098/12901842.html","kind":"正文","scope":"三江走向、两处交汇、柴巴夏三家与尸皇芋顶天的相对位置。"},
	"clans":{"title":"《蛊如故雏形》","url":"https://www.shuhaige.net/70475/4393272.html","kind":"正文·后期名录","scope":"武、巴、商、铁、侯、罗、乔、柴、夏、翼、池、羊、姚；只作族名索引。"},
	"bone":{"title":"第二卷《轰！》与白骨山","url":"https://www.shuhaige.net/70475/447935.html","kind":"正文","scope":"白骨山的骨质山体；百家迁居属于方源前世记忆中的未来，不能当作开局事实。"},
	"shang":{"title":"第二卷《商家内城》","url":"https://www.bqgns.com/book/50881/266","kind":"正文","scope":"商量山与商家城，山内五区；不据此推定其在全南疆的精确位置。"},
	"trade":{"title":"第二卷《黄金山》","url":"https://m.hetushu.com/book/7640/5345480.html","kind":"正文","scope":"匪猴山商路、黄金山黄家与金家、张家商队；不提供各族统一疆界。"},
	"tomb":{"title":"第二卷《丁浩，你给我出来！》","url":"https://www.sobqg.com/read/guzhenren/18153225.html","kind":"正文","scope":"墓碑山与商队行程；后续灾变、传承事件不自动发生。"},
	"sancha":{"title":"第二卷《只差最后一步》","url":"https://www.sobqg.com/read/guzhenren/18153359.html","kind":"正文","scope":"三叉山在左家冷颤山、车家飞来山之间；左右朝向与里程未给定。"},
	"wu":{"title":"第六卷《七七玄魂鸟》","url":"https://www.hetushu.com/book/7640/5347305.html","kind":"正文·后文补地理","scope":"武家大本营武仪山位于南疆西南；不回填当时的领袖和战况。"},
	"tie":{"title":"《死鬼快来铁面神》","url":"https://www.sobqg.com/read/guzhenren/18154311.html","kind":"正文·后文补地理","scope":"南疆铁家万程山；具体全域方位仍待考。"},
	"qiao":{"title":"《可借不可靠》","url":"https://cn.ttkan.co/novel/pagea/guzhenren-guzhenren_1338.html","kind":"正文·后文补地理","scope":"乔家大本营为大鹏山；章节中的西北是人物当时视点，不能直接当成全域西北。"},
	"chi":{"title":"《局势骤缓》","url":"https://hetushu.com/book/7640/5346586.html","kind":"正文·后文补地理","scope":"池家万蛇山；池与乔、羊接壤，武池不直接接壤，是该章时代的关系。"},
	"yitian":{"title":"《紫山真君战龙公》","url":"https://www.hetushu.com/book/7640/5346599.html","kind":"正文·后文补地理","scope":"义天山位于南疆中心偏左；开局不预置大战遗址和超级梦境。"},
	"jia":{"title":"第一卷《要的就是你这番话》","url":"https://www.kanxiaoshuo.org/novel/guzhenren/chapter/57","kind":"正文","scope":"贾家为大型家族，贾富商队与古月寨贸易；本轮没有核实其驻山名称。"},
	"reader":{"title":"读者百科 Volumes · 第二卷行程索引","url":"https://reverend-insanity.fandom.com/wiki/Volumes","kind":"读者整理","scope":"辅助核对出山、白骨山、商家城与三王传承的阅读顺序；不是坐标或疆界依据。"},
}

const RIVERS := [
	{"id":"red","name":"赤龙江","color":Color("c78d71"),"points":[Vector2(70,70),Vector2(210,155),Vector2(360,260),Vector2(450,355),Vector2(550,460),Vector2(750,630),Vector2(940,715),Vector2(1140,770)]},
	{"id":"blue","name":"碧龙江","color":Color("7cbba5"),"points":[Vector2(65,330),Vector2(220,285),Vector2(360,260),Vector2(540,235),Vector2(760,195),Vector2(960,150),Vector2(1140,130)]},
	{"id":"yellow","name":"黄龙江","color":Color("d3ba78"),"points":[Vector2(85,770),Vector2(240,740),Vector2(310,670),Vector2(345,545),Vector2(420,450),Vector2(550,460),Vector2(610,580),Vector2(650,730),Vector2(850,790),Vector2(1110,815)]},
]
const TRAILS := [
	[Vector2(670,660),Vector2(745,510),Vector2(850,420),Vector2(935,340),Vector2(1015,255)],
	[Vector2(1015,255),Vector2(990,485),Vector2(895,610)],
]

const SITES := [
	{"id":"qingmao","name":"青茅山","kind":"山寨群","pos":Vector2(395,480),"placement":"inferred","major":true,"clans":["guyue","bai","xiong"],"sources":["qingmao","yellow"],"fact":"古月、白家、熊家三寨同处一山，各有传承和元泉；青茅山属于黄龙江沿岸地名。","reading":"以三寨、梯田、竹林和山脚水路构成聚落群；全域落点为沿江示意。","era":"保留三寨，不预设青茅山覆灭。","local":"guyue"},
	{"id":"huangguo","name":"黄果山","kind":"江源","pos":Vector2(85,745),"placement":"inferred","sources":["yellow"],"fact":"黄龙江发源地。","reading":"作为沿江索引的起点；图上的西南落点不代表正文指定方向。"},
	{"id":"xuanming","name":"玄冥山","kind":"沿江山地","pos":Vector2(235,710),"placement":"inferred","sources":["yellow"],"fact":"正文在黄龙江沿途山岳中提及。","reading":"按沿江叙述次序连接，不擅自指定家族和资源矿产。"},
	{"id":"guibei","name":"龟背山","kind":"沿江山地","pos":Vector2(285,600),"placement":"inferred","sources":["yellow"],"fact":"黄龙江沿途山岳之一。","reading":"与玄冥、青茅山连缀作沿江区域，距离为示意。"},
	{"id":"baigu","name":"白骨山","kind":"荒山","pos":Vector2(575,515),"placement":"inferred","major":true,"clans":["bai_hundred"],"sources":["yellow","bone"],"fact":"山体呈骨质，周边较平缓，有特殊骨兽、植被与传承线索。","reading":"独立骨山与洞群，可作为后续方块材质和地下探索的设计依据。","era":"百家迁居是前世记忆中的未来；此处关联家族不代表百家已经据有全山。"},
	{"id":"leici","name":"雷磁山","kind":"沿江山地","pos":Vector2(700,760),"placement":"inferred","sources":["yellow"],"fact":"黄龙江沿途山岳之一。","reading":"保留名称和沿江关系，未核实的地貌与驻族留白。"},
	{"id":"shangliang","name":"商量山 · 商家城","kind":"家族城池","pos":Vector2(1015,255),"placement":"inferred","major":true,"clans":["shang"],"sources":["shang","wu"],"fact":"商家经营的山城，外城之外还有深入山体的内城五区。","reading":"按商业枢纽组织城门、街市、内城、演武与服务区；后文支持商家在赤黄交汇东侧，城市精确落点仍为推演。"},
	{"id":"wuyi","name":"武仪山","kind":"家族驻山","pos":Vector2(180,825),"placement":"relative","major":true,"clans":["wu"],"sources":["wu"],"fact":"武家大本营，正文给出南疆西南一端的方位。","reading":"西南位置有依据，山形、腹地和边界不作精确测绘。"},
	{"id":"wancheng","name":"万程山","kind":"家族驻山","pos":Vector2(1040,585),"placement":"relative","major":true,"clans":["tie"],"sources":["tie","chi"],"fact":"正文明确关联南疆铁家。","reading":"后文将铁家列在南疆东部；东南落点与山距仍为推演，不画成全域国界。"},
	{"id":"dapeng","name":"大鹏山","kind":"家族驻山","pos":Vector2(235,535),"placement":"relative","clans":["qiao"],"sources":["qiao","chi"],"fact":"乔家大本营。后文章节讨论乔家与周边家族联系。","reading":"后文将乔家置于南疆西部中心、池家以东；山峰坐标仍为示意。"},
	{"id":"wanshe","name":"万蛇山","kind":"家族驻山","pos":Vector2(80,430),"placement":"relative","clans":["chi"],"sources":["chi"],"fact":"池家大本营，后文记载池家在南疆最西部，乔家在其右方、羊家在右下方。","reading":"采用邻接关系整理的落点；不将后期疆界直接冻结为开局领地。"},
	{"id":"renyan","name":"人烟山","kind":"家族驻山","pos":Vector2(360,165),"placement":"relative","major":true,"clans":["chai"],"sources":["rivers"],"fact":"柴家大本营，在赤碧交汇上方；周边人口稠密。","reading":"用密集村落群表现人烟山脉；支脉、村寨数量为美术推演。"},
	{"id":"dazhai","name":"大宅山","kind":"家族驻山","pos":Vector2(380,360),"placement":"relative","major":true,"clans":["ba"],"sources":["rivers"],"fact":"巴家大本营，位于赤碧交汇下方。","reading":"保留相对南侧，具体山距和资源辖区未给定。"},
	{"id":"yanshou","name":"延寿山","kind":"家族驻山","pos":Vector2(540,280),"placement":"relative","major":true,"clans":["xia"],"sources":["rivers"],"fact":"夏家大本营，位于赤碧交汇右侧。","reading":"表现为三家围绕江流资源分布，边界与道路由后续玩法决定。"},
	{"id":"feihou","name":"匪猴山","kind":"商路山地","pos":Vector2(745,510),"placement":"inferred","sources":["trade","reader"],"fact":"商队行程中的山地，沿途猴群构成关卡。","reading":"以绕山路段连接白骨山外缘与后续商路；不作为必须完成的小说任务。"},
	{"id":"huangjin","name":"黄金山","kind":"山寨群","pos":Vector2(850,420),"placement":"inferred","major":true,"clans":["jin","huang"],"sources":["trade"],"fact":"黄家寨、金家寨同处一山，双方关系不睦。","reading":"双寨争夺与商队选路可形成区域特色；东西朝向未核实。"},
	{"id":"mubei","name":"墓碑山","kind":"商路山地","pos":Vector2(935,340),"placement":"inferred","sources":["tomb"],"fact":"商队段落出现的山名，与僵尸及传承事件有关。","reading":"先登记山地名与行程关系，不把后续屠寨和事件状态写入开局。"},
	{"id":"lengzhan","name":"冷颤山","kind":"家族驻山","pos":Vector2(780,650),"placement":"inferred","clans":["zuo"],"sources":["sancha"],"fact":"左家驻山，三叉山位于它和飞来山之间。","reading":"左家在图左侧只是排版推演，不是由族名推导的原著方位。"},
	{"id":"sancha","name":"三叉山","kind":"山地","pos":Vector2(895,610),"placement":"relative","major":true,"sources":["sancha"],"fact":"位于左家冷颤山与车家飞来山之间。","reading":"保留夹在两山之间的拓扑关系；三座山在南疆东南的整体落位为推演。","era":"三王传承未设为开局已开启，也不作游历前置条件。"},
	{"id":"feilai","name":"飞来山","kind":"家族驻山","pos":Vector2(975,675),"placement":"inferred","clans":["che"],"sources":["sancha"],"fact":"车家驻山，与冷颤山夹着三叉山。","reading":"只确认相邻关系，图面方位、山道和里程为推演。"},
	{"id":"yitian","name":"义天山","kind":"山地","pos":Vector2(470,565),"placement":"relative","major":true,"sources":["yitian"],"fact":"正文后文将其定位在南疆中心偏左。","reading":"记录地名与相对位置；不提前生成大战废墟、禁仙绝境或超级梦境。"},
	{"id":"red_river","name":"赤龙江","kind":"大江","pos":Vector2(840,665),"placement":"relative","major":true,"sources":["rivers"],"fact":"从南疆西北向东南斜贯，分别与碧龙江、黄龙江交汇。","reading":"三江关系是地图骨架，水道弯折、宽度与流域边界为示意。"},
	{"id":"blue_river","name":"碧龙江","kind":"大江","pos":Vector2(790,190),"placement":"relative","major":true,"sources":["rivers"],"fact":"三大江之一，俯瞰较靠上，走势较缓；不与黄龙江相交。","reading":"用上方缓斜曲线表现，未补造河源名称。"},
	{"id":"yellow_river","name":"黄龙江","kind":"大江","pos":Vector2(900,800),"placement":"relative","major":true,"sources":["yellow","rivers"],"fact":"源于黄果山，整体形似几字，沿途包括青茅、白骨等山，最终入海。","reading":"保留源头与沿岸次序；示意图没有按小说里程缩尺。"},
	{"id":"red_blue","name":"赤碧交汇","kind":"江心漩涡","pos":Vector2(360,260),"placement":"relative","sources":["rivers"],"fact":"两江交汇处资源丰厚，柴、巴、夏三家驻山围绕分布。","reading":"节点关系有据，图上只画江流与附近驻山，不划整片专属疆域。"},
	{"id":"red_yellow","name":"赤黄交汇","kind":"江心漩涡","pos":Vector2(550,460),"placement":"relative","sources":["rivers"],"fact":"后文所述武家领地内的一处江心漩涡。","reading":"作为资源地理记录；不意味着武仪山就在交汇点，也不保证开局归属完全相同。"},
	{"id":"guishou","name":"鬼手山","kind":"家族资源地","pos":Vector2(145,710),"placement":"relative","major":true,"clans":["yang"],"sources":["chi"],"fact":"羊家资源地，在黄龙江源区；羊家位于南疆西南、池家右下方。","reading":"位置按源区与家族相对关系组织，不能直接标成羊家大本营。"},
	{"id":"jiuyou","name":"九幽山脉","kind":"边缘山地","pos":Vector2(100,595),"placement":"inferred","clans":["chi","yang"],"sources":["chi"],"fact":"后文池、羊两家交战涉及的山脉。","reading":"据两家相邻关系示意落位；开局不预置战场或自动开战。"},
	{"id":"shihuang","name":"尸皇芋顶天","kind":"资源地标","pos":Vector2(620,395),"placement":"relative","sources":["rivers"],"fact":"位于赤黄交汇处东北岸的地标。","reading":"保留相对位置，暂不生成资源产出、守卫或传承奖励。"},
]

const CLANS := [
	{"id":"wu","name":"武家","tier":"超级家族","site":"wuyi","sources":["clans","wu"],"fact":"南疆正道超级家族，驻山为武仪山。","reading":"可作为西南区域的主要势力；具体当代族长、附庸和战况分期核对。"},
	{"id":"ba","name":"巴家","tier":"超级家族","site":"dazhai","sources":["clans","rivers"],"fact":"驻山大宅山，与柴、夏同处赤碧交汇周边。","reading":"以江畔资源与相邻家族关系塑造区域，不固定一条全族专属道途。"},
	{"id":"shang","name":"商家","tier":"超级家族","site":"shangliang","sources":["clans","shang"],"fact":"商量山与商家城的经营家族，拥有分层内城。","reading":"家族内容应包括街市、演武、居住、管理和服务；已接缩尺可行走商区、演武坪与赌石坊；布局与数值为沙盒改编。"},
	{"id":"tie","name":"铁家","tier":"超级家族","site":"wancheng","sources":["clans","tie"],"fact":"南疆正道家族；正文有万程山与铁面传承记载。","reading":"后续可围绕调查、守卫与通缉设计互动，不等同于全南疆统一执法政府。"},
	{"id":"hou","name":"侯家","tier":"超级家族","site":"","sources":["clans"],"fact":"列入正文后期十三个南疆正道超级家族名录。","reading":"本轮只确认族名；驻山、方位和开局人物待考，不放置虚构大本营。"},
	{"id":"luo","name":"罗家","tier":"超级家族","site":"","sources":["clans","chi"],"fact":"南疆东部超级家族；与其他域同姓势力分别登记。","reading":"驻山与领地未核实；不凭同姓借用外域地点、人物和传承。"},
	{"id":"qiao","name":"乔家","tier":"超级家族","site":"dapeng","sources":["clans","qiao","chi"],"fact":"大本营大鹏山。后文有与武、池相联系的地缘记载。","reading":"只用于邻接推演，后期联盟与依附不会自动套到青茅山前期。"},
	{"id":"chai","name":"柴家","tier":"超级家族","site":"renyan","sources":["clans","rivers"],"fact":"驻人烟山，周边拥有密集凡人聚落。","reading":"聚落群和人口经营是设计线索，不把人口基数直接换算为免费蛊师或资源。"},
	{"id":"xia","name":"夏家","tier":"超级家族","site":"yanshou","sources":["clans","rivers"],"fact":"驻延寿山，位于赤碧交汇右方。","reading":"与巴、柴共同形成交汇区域，族内人物和资源细节另行考据。"},
	{"id":"yi","name":"翼家","tier":"超级家族","site":"","sources":["clans","chi"],"fact":"位于南疆东部，正文名录用字为翼。","reading":"不能与其他域的易家混同；驻山与开局人员本轮留待核实。"},
	{"id":"chi","name":"池家","tier":"超级家族","site":"wanshe","sources":["clans","chi"],"fact":"驻万蛇山，后文记载与乔、羊领地相邻。","reading":"按地缘联系组织目录；不把万蛇山名称推导成全族只能养蛇。"},
	{"id":"yang","name":"羊家","tier":"超级家族","site":"guishou","sources":["clans","chi"],"fact":"正文名录用字为羊，位于池家右下方；鬼手山是其在黄龙江源区的资源地。","reading":"不是杨家；资源地不等于已确认的大本营，驻地与具体界线仍待核实。"},
	{"id":"yao","name":"姚家","tier":"超级家族","site":"","sources":["clans"],"fact":"南疆正道超级家族之一。","reading":"名称有据；驻山、实力和人物应分时代补全，当前不虚构族长和专属蛊。"},
	{"id":"guyue","name":"古月一族","tier":"青茅山三族","site":"qingmao","sources":["qingmao"],"fact":"青茅山宗族，月光蛊为标志。","reading":"已接入祠堂、学堂、药堂、商铺与住宅；三寨实际布局为游戏设计。","local":"guyue"},
	{"id":"bai","name":"白家","tier":"青茅山三族","site":"qingmao","sources":["qingmao"],"fact":"青茅山白家寨，溪流蛊为家族标志。","reading":"与白骨山相关的百家分别记录；已有九处建筑和服务。","local":"bai"},
	{"id":"xiong","name":"熊家","tier":"青茅山三族","site":"qingmao","sources":["qingmao"],"fact":"三寨中处于山脚低处，熊力蛊为标志。","reading":"已有九处建筑；低处不等于正文确定为青茅山正南。","local":"xiong"},
	{"id":"bai_hundred","name":"百家","tier":"其他正文家族","site":"","related":"baigu","sources":["bone"],"fact":"与白骨山迁居及传承故事有关，字为百。","reading":"青茅山前期驻地未核实；只关联白骨山线索，不冒充已定居的白家。"},
	{"id":"jia","name":"贾家","tier":"其他正文家族","site":"","sources":["jia"],"fact":"经营商队的大型家族，贾富商队与青茅山有贸易往来。","reading":"商队关系不能推出大本营就在青茅山旁；驻山位置待考。"},
	{"id":"zhang","name":"张家","tier":"其他正文家族","site":"","sources":["trade"],"fact":"商队篇章出现的家族，张柱随行。","reading":"作为商旅势力登记；未核实开局驻山，不将其混为商家的城内分支。"},
	{"id":"jin","name":"金家","tier":"其他正文家族","site":"huangjin","sources":["trade"],"fact":"黄金山金家寨，与黄家寨不睦。","reading":"可形成双寨贸易选择；地图只定位到黄金山，不伪造寨门朝向。"},
	{"id":"huang","name":"黄家","tier":"其他正文家族","site":"huangjin","sources":["trade"],"fact":"黄金山黄家寨，与金家共处一山。","reading":"按共同山域组织不同聚落；具体建筑和人物尚未生成。"},
	{"id":"zuo","name":"左家","tier":"其他正文家族","site":"lengzhan","sources":["sancha"],"fact":"冷颤山家族，与车家在三叉山一带竞争。","reading":"关系有据，图面左右与山路是推演；竞争不强制转为开局战争。"},
	{"id":"che","name":"车家","tier":"其他正文家族","site":"feilai","sources":["sancha"],"fact":"飞来山家族，三叉山位于其与左家驻山之间。","reading":"保留地方家族身份，不自动提升为后期十三超级家族之一。"},
]

static func site(id: String) -> Dictionary:
	for row in SITES:
		if row.id==id: return row
	return {}

static func clan(id: String) -> Dictionary:
	for row in CLANS:
		if row.id==id: return row
	return {}

static func entry(key: String) -> Dictionary:
	return clan(key.trim_prefix("clan:")) if key.begins_with("clan:") else site(key)

static func focus_site(key: String) -> String:
	var row:=entry(key)
	return String(row.get("site","")) if key.begins_with("clan:") else String(row.get("id",""))

static func matches(row: Dictionary, query: String) -> bool:
	var haystack:=str(row.get("name",""))+str(row.get("fact",""))+str(row.get("tier",""))+str(row.get("kind",""))
	for id in row.get("clans",[]): haystack+=clan(id).get("name","")
	return query.strip_edges().is_empty() or haystack.contains(query.strip_edges())

static func detail(key: String) -> String:
	var row:=entry(key)
	if row.is_empty(): return "选择山川或家族，查看正文依据与读者推演。"
	var text:="[font_size=19][color=#d8bc7c]%s[/color][/font_size]\n%s\n"%[row.name,row.get("tier",row.get("kind",""))]
	text+="\n[color=#76c2aa]正文记载[/color]\n"+row.fact
	if key.begins_with("clan:"):
		var home:=site(String(row.get("site","")))
		text+="\n关联地点："+(home.name if not home.is_empty() else "位置待考 · 未设虚构据点")
		if not home.is_empty(): text+="\n[url=site:%s]定位 %s[/url]"%[home.id,home.name]
		if row.has("related"): text+="\n[url=site:%s]相关地点：%s（不代表开局归属）[/url]"%[row.related,site(row.related).name]
	else:
		text+="\n落位："+("相对关系有据，具体坐标仍为示意" if row.placement=="relative" else "读者推演，非原著确定方位")
		for id in row.get("clans",[]): text+="\n[url=clan:%s]关联家族：%s[/url]"%[id,clan(id).name]
	text+="\n\n[color=#d8bc7c]读者理解 · 游戏规划[/color]\n"+row.reading
	if row.has("era"): text+="\n\n[color=#dfb894]时代注意[/color]\n"+row.era
	text+="\n\n[color=#93a99f]依据[/color]"
	for id in row.sources: text+="\n[url=source:%s]%s · %s[/url]"%[id,SOURCES[id].kind,SOURCES[id].title]
	if row.get("tier","")=="超级家族": text+="\n十三家名单取自后文，非开局实力排名。"
	text+="\n\n"+("商家城已有沙盒商区，点击游历按钮前往。" if focus_site(key)=="shangliang" else "青茅山已有游玩场景，可切回本地查看。" if row.has("local") else "地理志已收录，远方场景尚未开放。")
	return text
