class_name CharacterAppearance
extends RefCounted

## Cosmetic only. PNGs are copied into a character-owned folder, never loaded as scripts/resources.
const CELL := 256
const DEFAULTS := {"base":"painted","style":0,"hair_style":0,"height":1.0,"width":1.0,"hem":0.75,"sleeve":0.6,
	"cloth":"356b66","trim":"cfb67d","sash":"674a40","pants":"293b41","skin":"dab18e","hair":"242b31",
	"actor_asset":"","outfit_asset":""}
const COLORS := ["cloth","trim","sash","pants","skin","hair"]
const LIMITS := {"height":Vector2(0.85,1.08),"width":Vector2(0.8,1.2),"hem":Vector2(0,1),"sleeve":Vector2(0,1)}
var data: Dictionary = DEFAULTS.duplicate(true)
var texture: Texture2D = PaintedArt.HERO
var warning := ""

static func asset_name(value: Variant) -> bool:
	if not value is String or value.length()!=68 or not value.ends_with(".png"): return false
	for c in value.substr(0,64):
		if not c in "0123456789abcdef": return false
	return true

static func normalize(value: Variant) -> Dictionary:
	var result:=DEFAULTS.duplicate(true)
	if not value is Dictionary: return result
	if value.get("base") in ["painted","tailored","imported"]: result.base=value.base
	for key in ["style","hair_style"]:
		if (value.get(key) is float or value.get(key) is int) and is_finite(float(value[key])): result[key]=clampi(int(value[key]),0,2)
	for key in LIMITS:
		if (value.get(key) is float or value.get(key) is int) and is_finite(float(value[key])):
			result[key]=clampf(float(value[key]),LIMITS[key].x,LIMITS[key].y)
	for key in COLORS:
		if value.get(key) is String and value[key].length()==6 and Color.html_is_valid(value[key]): result[key]=value[key].to_lower()
	for key in ["actor_asset","outfit_asset"]:
		if asset_name(value.get(key)): result[key]=value[key]
	return result

static func read_png(path: String) -> Dictionary:
	if path.get_extension().to_lower()!="png": return {"error":"请选择 PNG 动作图集。"}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"error":"无法读取图片，请检查路径和权限。"}
	if file.get_length()<33 or file.get_length()>12*1024*1024: return {"error":"PNG 文件需小于 12 MB，且不能是空文件。"}
	var bytes:=file.get_buffer(file.get_length())
	file.close()
	# Check dimensions before decoding, including files disguised with a PNG extension.
	if bytes.slice(0,8)!=PackedByteArray([137,80,78,71,13,10,26,10]) or bytes.slice(12,16).get_string_from_ascii()!="IHDR":
		return {"error":"这不是有效的 PNG 图片。"}
	var w:=_be32(bytes,16)
	var h:=_be32(bytes,20)
	if w%6!=0 or h%4!=0 or w/6!=h/4 or w<192 or w>1536:
		return {"error":"图集应为 6 列 × 4 行正方形格，每格 32–256 像素；推荐 768×512。"}
	var image:=Image.new()
	if image.load_png_from_buffer(bytes)!=OK: return {"error":"PNG 解码失败，文件可能已损坏。"}
	if image.detect_alpha()==Image.ALPHA_NONE or image.is_invisible(): return {"error":"图集需要透明背景，并包含可见人物或衣服。"}
	image.convert(Image.FORMAT_RGBA8)
	var cell:=int(w/6)
	for row in 4:
		for column in 6:
			var tile:=image.get_region(Rect2i(column*cell,row*cell,cell,cell))
			if tile.is_invisible(): return {"error":"第 %d 行第 %d 列为空；四方向的六种动作都需要素材。"%[row+1,column+1]}
			if tile.get_pixel(0,0).a>0.05 or tile.get_pixel(cell-1,cell-1).a>0.05:
				return {"error":"每格边角需透明。请先去掉背景与模板标注。"}
	return {"image":image,"error":""}

static func _be32(bytes: PackedByteArray, at: int) -> int:
	return (int(bytes[at])<<24)|(int(bytes[at+1])<<16)|(int(bytes[at+2])<<8)|int(bytes[at+3])

func configure(value: Variant, folder: String = "", staged: Dictionary = {}) -> void:
	data=normalize(value)
	warning=""
	if data.base=="painted":
		texture=PaintedArt.HERO
		return
	var actor:Image=_asset("actor_asset",folder,staged)
	var outfit:Image=_asset("outfit_asset",folder,staged)
	var image:Image
	if data.base=="imported" and actor!=null:
		image=actor.duplicate()
		image.resize(CELL*6,CELL*4,Image.INTERPOLATE_LANCZOS)
	else:
		if data.base=="imported": warning="导入人物图片缺失或损坏，已显示内置外观。"
		image=sheet(data,"body" if outfit!=null else "full")
	if outfit!=null:
		var layer:Image=outfit.duplicate()
		layer.resize(CELL*6,CELL*4,Image.INTERPOLATE_LANCZOS)
		image.blend_rect(layer,Rect2i(0,0,CELL*6,CELL*4),Vector2i.ZERO)
	texture=ImageTexture.create_from_image(image)

func _asset(key: String, folder: String, staged: Dictionary) -> Image:
	if staged.get(key) is Image: return staged[key]
	if data[key]=="" or folder=="": return null
	var result:=read_png(folder.path_join(data[key]))
	if result.get("image") is Image: return result.image
	warning="部分导入图片缺失或损坏，已使用内置外观。"
	return null

func region(row: int, frame: int) -> Rect2:
	var cell:=texture.get_width()/6.0
	return Rect2(frame*cell,row*cell,cell,cell)

static func sheet(value: Dictionary, layer: String = "full") -> Image:
	var d:=normalize(value)
	var xml:='<svg xmlns="http://www.w3.org/2000/svg" width="1536" height="1024" viewBox="0 0 384 256">'
	xml+='<defs><linearGradient id="cloth" x1="0" x2="1" y1="0" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs>'%[d.cloth,Color(d.cloth).darkened(0.32).to_html(false)]
	for row in 4:
		for frame in 6:
			xml+='<g transform="translate(%s %s)">'%[frame*64+32,row*64+52]
			xml+=_pose(d,row,frame,layer)
			xml+='</g>'
	xml+='</svg>'
	var image:=Image.new()
	image.load_svg_from_string(xml)
	image.convert(Image.FORMAT_RGBA8)
	return image

static func _poly(points: Array, fill: String, stroke: String = "#203532", width: float = 0.65) -> String:
	var text:=""
	for p in points: text+="%.2f,%.2f "%[p.x,p.y]
	return '<polygon points="%s" fill="%s" stroke="%s" stroke-width="%.2f" stroke-linejoin="round"/>'%[text,fill,stroke,width]

static func _line(a: Vector2, b: Vector2, color: String, width: float = 0.7) -> String:
	return '<path d="M %.2f %.2f L %.2f %.2f" fill="none" stroke="%s" stroke-width="%.2f" stroke-linecap="round"/>'%[a.x,a.y,b.x,b.y,color,width]

static func _ellipse(p: Vector2, radius: Vector2, color: String) -> String:
	return '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s"/>'%[p.x,p.y,radius.x,radius.y,color]

static func _limb(a: Vector2, b: Vector2, wa: float, wb: float, color: String) -> String:
	var side:=(b-a).normalized().orthogonal()
	return _poly([a+side*wa,b+side*wb,b-side*wb,a-side*wa],color)

static func _pose(d: Dictionary, row: int, frame: int, layer: String) -> String:
	var body:=layer!="outfit"
	var clothing:=layer!="body"
	var side:=row in [1,3]
	var back:=row==2
	var skin:String="#"+d.skin
	var hair:String="#"+d.hair
	var pants:String="#"+d.pants
	var trim:String="#"+d.trim
	var sash:String="#"+d.sash
	var cloth:="url(#cloth)"
	var step:=(-1.0 if frame==1 else 1.0) if frame in [1,2] else 0.0
	var hem:float=lerpf(-18.0,-2.0,d.hem) if d.style!=0 else lerpf(-21.0,-13.0,d.hem)
	var sw:float=lerpf(2.1,5.4,d.sleeve)
	var xscale:float=d.width*(-1.0 if row==1 else 1.0)
	var xml:='<g transform="scale(%.3f %.3f)">'%[xscale,d.height*0.94]
	if frame==5: xml+='<g transform="translate(-15 -2) rotate(82) scale(0.85)">'
	var shoulder_l:=Vector2(-6 if not side else -2,-31)
	var shoulder_r:=Vector2(6 if not side else 2,-31)
	var hand_l:=Vector2(-10 if not side else -3,-17-step*2)
	var hand_r:=Vector2(10 if not side else 5,-17+step*2)
	if frame==3:
		hand_r=Vector2(21,-29) if side else Vector2(11,-26 if back else -19)
		hand_l=Vector2(-8,-24)
	if frame==4:
		hand_r=Vector2(12,-39)
		hand_l=Vector2(-11,-26)
	if body and d.hair_style==2: xml+=_poly([Vector2(-5,-41),Vector2(5,-41),Vector2(7,-23),Vector2(0,-25),Vector2(-6,-22)],hair)
	if body:
		for sign_value in [-1,1]:
			var foot:=Vector2(sign_value*(2.3 if side else 3.8)+step*sign_value*2,3-absf(step)*float(sign_value==1)*2)
			xml+=_limb(Vector2(sign_value*3,-18),foot,2.7,2.2,pants)
			xml+=_poly([foot+Vector2(-2,-3),foot+Vector2(2,-3),foot+Vector2(4,0),foot+Vector2(3,2),foot+Vector2(-2,2)],"#242d2b")
			xml+=_line(foot+Vector2(-1,-1),foot+Vector2(2,-1),trim,0.7)
		if side:
			xml+=_limb(shoulder_l,hand_l,2.3,1.5,skin)
			xml+=_ellipse(hand_l,Vector2(1.8,2),skin)
	if clothing and side: xml+=_limb(shoulder_l,hand_l.lerp(shoulder_l,0.18),3,sw,cloth)
	if body:
		xml+=_poly([Vector2(-6,-34),Vector2(6,-34),Vector2(7,-19),Vector2(-7,-19)],"#e4d3b0")
		xml+=_limb(Vector2(0,-38),Vector2(0,-31),2.1,2.1,skin)
	if clothing:
		var width:=7.5 if not side else 5.5
		var flare:float=width+(3 if d.style==1 else 1.5)
		xml+=_poly([Vector2(-width,-33),Vector2(-2,-35),Vector2(3,-34),Vector2(width,-32),Vector2(width,-23),Vector2(flare+step,hem),Vector2(0,hem-0.5),Vector2(-flare+step,hem-1),Vector2(-width,-23)],cloth)
		xml+=_line(Vector2(-flare+step+1,hem-1.6),Vector2(flare+step-1,hem-0.6),trim,1.1)
		if not back:
			xml+=_poly([Vector2(-2,-34),Vector2(4,-29),Vector2(-1,-23),Vector2(1,-29)],trim,"none")
			xml+=_line(Vector2(-1,-23),Vector2(2,hem-2),"#"+Color(d.cloth).lightened(0.22).to_html(false))
		if d.style==2:
			xml+=_poly([Vector2(-width,-33),Vector2(-2,-34),Vector2(-2,hem-1),Vector2(-width-1,hem-2)],sash)
			xml+=_line(Vector2(-2,-33),Vector2(-2,hem-2),trim,1)
		for i in [-1,1]: xml+=_line(Vector2(i*4,-20),Vector2(i*(flare-2)+step,hem-3),"#"+Color(d.cloth).darkened(0.18).to_html(false),0.6)
		xml+=_poly([Vector2(-width,-24),Vector2(width,-24),Vector2(width,-21.5),Vector2(-width,-21.5)],sash)
		xml+=_ellipse(Vector2(2,-22.5),Vector2(1.3,1.1),trim)
		xml+=_poly([Vector2(3,-22),Vector2(5,-22),Vector2(6+step,-11),Vector2(3+step,-13)],sash)
	for i in (1 if side else 2):
		var shoulder:=shoulder_r if i==0 else shoulder_l
		var hand:=hand_r if i==0 else hand_l
		if body: xml+=_limb(shoulder,hand,2.3,1.5,skin)
		if clothing:
			var cuff:=hand.lerp(shoulder,0.18)
			xml+=_limb(shoulder,cuff,3.2,sw,cloth)
			var edge:=(cuff-shoulder).normalized().orthogonal()*sw
			xml+=_line(cuff-edge,cuff+edge,trim,1.3)
		if body: xml+=_ellipse(hand,Vector2(1.8,2.1),skin)
	if body:
		xml+=_ellipse(Vector2(0,-40),Vector2(5.4 if not side else 4.5,6.7),skin)
		xml+=_ellipse(Vector2(-4,-40),Vector2(1.2,1.8),skin)
		if back:
			xml+=_ellipse(Vector2(0,-41),Vector2(5.5,6.4),hair)
		else:
			xml+=_poly([Vector2(-5,-39),Vector2(-5,-45),Vector2(-2,-47),Vector2(3,-46),Vector2(5,-43),Vector2(1,-44),Vector2(-3,-42),Vector2(-3,-38)],hair,"none")
			xml+=_line(Vector2(1 if side else -2.5,-40),Vector2(2.7 if side else -1,-40),"#302b2c",0.6)
			if not side: xml+=_line(Vector2(1,-40),Vector2(2.5,-40),"#302b2c",0.6)
			xml+=_line(Vector2(1,-36.8),Vector2(2 if side else -1,-36.8),"#9b6e5e",0.5)
		if d.hair_style==0:
			xml+=_ellipse(Vector2(-1,-48),Vector2(3.1,2.4),hair)
			xml+=_line(Vector2(-4,-47),Vector2(2,-47),trim,0.8)
		elif d.hair_style==1:
			xml+=_poly([Vector2(-4,-43),Vector2(-6,-40),Vector2(-7+step,-26),Vector2(-4+step,-28)],hair,"none")
			xml+=_line(Vector2(-7+step,-28),Vector2(-4+step,-29),trim,1)
		if d.hair_style==2 and back: xml+=_poly([Vector2(-4,-42),Vector2(4,-42),Vector2(6,-27),Vector2(0,-24),Vector2(-5,-28)],hair)
	if frame==5: xml+='</g>'
	return xml+'</g>'
