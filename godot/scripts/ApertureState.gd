class_name ApertureState
extends RefCounted

## 空窍中的修行状态。单位是整个空窍体积的百分数，44 表示四成四。
## 原文依据与时间压缩见 CANON.md；不使用战斗经验。
const STAGES := ["初阶", "中阶", "高阶", "巅峰"]
const WALLS := ["光膜", "水膜", "石膜", "晶膜"]
const ESSENCE := ["青铜", "赤铁", "白银", "黄金", "紫晶"]
const BRONZE_COLORS := ["翠绿", "苍绿", "深绿", "墨绿"]
const GAME_HOUR := 60.0 # 现实一分钟为游戏一小时，恢复/喂食使用同一时钟。
var rank := 1
var stage := 0
var capacity := 44.0
var essence := 44.0
var refined_essence := 0.0
var wall_progress := 0.0
var stone_reserve := 0.0

func aptitude() -> String:
	if capacity >= 80: return "甲等"
	if capacity >= 60: return "乙等"
	if capacity >= 40: return "丙等"
	return "丁等"

func realm() -> String:
	return "%d 转%s" % [rank, STAGES[stage]]

func essence_name() -> String:
	return ESSENCE[rank-1]+"真元" + (" · "+BRONZE_COLORS[stage] if rank==1 else "")

func recovery_rate() -> float:
	# 第十章明确丙等每小时四分、甲等八分；中间两档用同一梯度。
	return (8.0 if capacity>=80 else 6.0 if capacity>=60 else 4.0 if capacity>=40 else 2.0)/GAME_HOUR

func total() -> float:
	return essence+refined_essence

func recover(delta: float) -> void:
	essence += minf(maxf(0,capacity-total()),recovery_rate()*delta)
	if stone_reserve > 0:
		var used := minf(stone_reserve,minf(maxf(0,capacity-total()),delta))
		essence += used
		stone_reserve -= used

func cost_at_stage(base: float) -> float:
	return base/pow(2.0,stage)

func can_spend(base: float) -> bool:
	return essence+refined_essence*2.0 >= cost_at_stage(base)-0.0001

func spend(base: float) -> bool:
	var need := cost_at_stage(base)
	if not can_spend(base): return false
	var refined_used := minf(refined_essence,need/2.0)
	refined_essence -= refined_used
	need -= refined_used*2.0
	essence = maxf(0,essence-need)
	return true

func refine_essence() -> bool:
	# 一转酒虫只能精炼一转真元，提升一小阶；巅峰不能精炼成二转。
	# 第 29 章：一成发动酒雾，再将另一成精炼为半成，总耗两成。
	if rank != 1 or stage >= 3 or essence < 20.0: return false
	essence -= 20.0
	refined_essence += 5.0
	return true

func cultivate(delta: float) -> float:
	# 此进度是窍壁温养度，消耗与时长为实时游戏压缩参数。
	if wall_progress >= 100: return 0.0
	var amount := 0.6*delta
	var remaining := 100.0-wall_progress
	var advanced := minf(refined_essence,minf(amount,remaining/2.0))
	refined_essence -= advanced
	var ordinary := minf(essence,minf(amount-advanced,remaining-advanced*2.0))
	essence -= ordinary
	var gain := advanced*2.0+ordinary
	wall_progress = minf(100,wall_progress+gain)
	return gain

func breakthrough() -> String:
	if wall_progress < 100: return "窍壁温养不足。"
	# 跨转突破涉及持续冲击、反震和资质瓶颈，未验收前不能直接经验升级。
	if stage == 3: return "跨转冲窍尚未开放；不会自动升转。"
	stage += 1
	wall_progress = 0
	essence = minf(capacity,essence/2.0+refined_essence)
	refined_essence = 0
	return "窍壁蜕变为%s，达到%s。" % [WALLS[stage],realm()]

func save_data() -> Dictionary:
	return {"rank":rank,"stage":stage,"capacity":capacity,"essence":essence,"refined_essence":refined_essence,"wall_progress":wall_progress,"stone_reserve":stone_reserve}

func load_data(d: Dictionary) -> void:
	rank=clampi(int(d.get("rank",1)),1,5)
	stage=clampi(int(d.get("stage",0)),0,3)
	capacity=clampf(float(d.get("capacity",44)),20,99)
	essence=clampf(float(d.get("essence",capacity)),0,capacity)
	refined_essence=clampf(float(d.get("refined_essence",0)),0,capacity-essence)
	if rank!=1 or stage==3:
		essence+=refined_essence
		refined_essence=0
	wall_progress=clampf(float(d.get("wall_progress",0)),0,100)
	stone_reserve=maxf(0,float(d.get("stone_reserve",0)))
