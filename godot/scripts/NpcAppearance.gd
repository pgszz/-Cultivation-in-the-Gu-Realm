class_name NpcAppearance
extends RefCounted

## Stable visual identity only; clothing never changes combat or personal inventory.
const STYLES := {
	"blue_disciple":{"sheet":"legacy","row":0,"name":"靛衣束发"},
	"herbalist":{"sheet":"legacy","row":1,"name":"素衣银髻"},
	"ochre_keeper":{"sheet":"legacy","row":2,"name":"褐帽长衫"},
	"grey_elder":{"sheet":"legacy","row":3,"name":"灰袍白须"},
	"red_tunic":{"sheet":"villagers","row":0,"name":"赭红短褂"},
	"teal_apron":{"sheet":"villagers","row":1,"name":"青衫围裙"},
	"straw_elder":{"sheet":"villagers","row":2,"name":"斗笠老翁"},
	"coral_braid":{"sheet":"villagers","row":3,"name":"珊衣长辫"},
	"bamboo_basket":{"sheet":"workers","row":0,"name":"绿衣背篓"},
	"stone_apron":{"sheet":"workers","row":1,"name":"壮实石工"},
	"blue_porter":{"sheet":"workers","row":2,"name":"蓝巾负囊"},
	"plum_traveler":{"sheet":"workers","row":3,"name":"紫披银辫"},
	"jade_guard":{"sheet":"guards","row":0,"name":"青甲束发"},
	"ice_patrol":{"sheet":"guards","row":1,"name":"浅蓝窄袖"},
	"brown_guard":{"sheet":"guards","row":2,"name":"棕袄壮卫"},
	"navy_escort":{"sheet":"guards","row":3,"name":"深蓝短甲"},
	"plum_merchant":{"sheet":"wayfarers","row":0,"name":"紫衣女商"},
	"wine_merchant":{"sheet":"wayfarers","row":1,"name":"方帽绛袍"},
	"hood_bandit":{"sheet":"wayfarers","row":2,"name":"灰兜瘦客"},
	"red_bandit":{"sheet":"wayfarers","row":3,"name":"红巾短衣"},
	"canon_fang_yuan":{"sheet":"canon","row":0,"name":"方源 · 墨衣静立"},
	"canon_fang_zheng":{"sheet":"canon","row":1,"name":"方正 · 蓝衣垂目"},
	"canon_bai_ning_bing":{"sheet":"canon","row":2,"name":"白凝冰 · 白发白衣"},
	"canon_qing_shu":{"sheet":"canon","row":3,"name":"青书 · 青发温颜"}
}
const SHEETS := {
	"villagers":"res://assets/people/villagers.png",
	"workers":"res://assets/people/workers.png",
	"guards":"res://assets/people/guards.png",
	"wayfarers":"res://assets/people/wayfarers.png",
	"canon":"res://assets/people/canon/qing_mao.png"
}
static var _textures: Dictionary = {}
const NAMED := {
	"aqing":"blue_disciple","clinic":"herbalist","shop":"ochre_keeper","archive":"grey_elder",
	"bamboo_gatherer":"bamboo_basket","stone_gatherer":"stone_apron",
	"east_traveler":"plum_traveler","south_traveler":"straw_elder",
	"caravan_merchant":"plum_merchant","caravan_porter":"blue_porter",
	"caravan_guard_a":"navy_escort","caravan_guard_b":"jade_guard",
	"bai_gatekeeper":"ice_patrol","bai_walker":"coral_braid",
	"xiong_gatekeeper":"brown_guard","xiong_walker":"red_tunic"
}

static func choose(id: String, role: String = "", clan: String = "") -> String:
	if CanonPeople.has(id): return id
	if NAMED.has(id): return NAMED[id]
	var index:=int(id.get_slice("_",id.get_slice_count("_")-1))
	match role:
		"villager":
			var offset:=1 if clan=="bai" else (2 if clan=="xiong" else 0)
			return ["red_tunic","teal_apron","straw_elder","coral_braid"][(index+offset)%4]
		"guard":
			var pair:Array={"bai":["ice_patrol","navy_escort"],"xiong":["brown_guard","jade_guard"]}.get(clan,["jade_guard","ice_patrol"])
			return pair[index%2]
		"bandit": return ["hood_bandit","red_bandit"][index%2]
		"escort": return "navy_escort"
		"merchant": return "wine_merchant"
		"porter": return "blue_porter"
		"gatherer": return "bamboo_basket"
		"traveler": return "plum_traveler"
	var other_clan:=id.begins_with("xiong_")
	match SettlementData.service(id):
		"clinic": return "plum_traveler" if other_clan else "herbalist"
		"shop": return "wine_merchant" if other_clan else "plum_merchant"
		"archive": return "straw_elder" if other_clan else "grey_elder"
		"workshop": return "stone_apron" if other_clan else "bamboo_basket"
		"inn": return "teal_apron" if other_clan else "coral_braid"
		"guard": return "brown_guard" if other_clan else "ice_patrol"
		"ancestral": return "grey_elder"
		"home": return ("red_tunic" if other_clan else "teal_apron") if id.ends_with("_a") else ("straw_elder" if other_clan else "coral_braid")
		"hall": return "brown_guard" if other_clan else "ice_patrol"
	return "blue_disciple"

static func restore(saved: Variant, id: String, role: String = "", clan: String = "") -> String:
	# A named identity cannot accidentally inherit a generic/other character's saved face.
	if CanonPeople.has(id): return id
	return saved if saved is String and STYLES.has(saved) else choose(id,role,clan)

static func actor_rect(id: String) -> Rect2:
	var factor:float=CanonPeople.PEOPLE[id].scale if CanonPeople.has(id) else 1.0
	return Rect2(Vector2(-32,-52)*factor,Vector2(64,64)*factor)

static func texture(id: String) -> Texture2D:
	var style:Dictionary=STYLES.get(id,STYLES.blue_disciple)
	if style.sheet=="legacy": return PaintedArt.RESIDENTS
	if _textures.has(style.sheet): return _textures[style.sheet]
	if not ResourceLoader.exists(SHEETS[style.sheet]): return PaintedArt.RESIDENTS
	_textures[style.sheet]=load(SHEETS[style.sheet])
	return _textures[style.sheet]

static func region(id: String, frame: int) -> Rect2:
	var style:Dictionary=STYLES.get(id,STYLES.blue_disciple)
	var cell:=texture(id).get_size()/Vector2(6,4)
	return Rect2(Vector2(clampi(frame,0,5),int(style.row))*cell,cell)

static func portrait(id: String, dead: bool = false) -> AtlasTexture:
	var result:=AtlasTexture.new()
	result.atlas=texture(id)
	result.region=region(id,5 if dead else 0)
	result.filter_clip=true
	return result

static func headshot(id: String) -> AtlasTexture:
	var result:=portrait(id)
	var cell:=region(id,0)
	result.region=Rect2(cell.position+cell.size*Vector2(0.20,0.0),cell.size*Vector2(0.60,0.48))
	return result
