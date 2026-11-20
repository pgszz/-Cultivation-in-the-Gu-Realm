class_name ApertureState
extends RefCounted

## 空窍中的修行状态。单位是整个空窍体积的百分数，44 表示四成四。
## 原文依据与时间压缩见 CANON.md；不使用战斗经验。
const STAGES := ["初阶", "中阶", "高阶", "巅峰"]
const WALLS := ["光膜", "水膜", "石膜", "晶膜"]
const ESSENCE := ["青铜", "赤铁", "白银", "黄金", "紫晶"]
const BRONZE_COLORS := ["翠绿", "苍绿", "深绿", "墨绿"]
const GAME_HOUR := 60.0 # 现实一分钟为游戏一小时，恢复/喂食使用同一时钟。
var rank := 0 # 0 为凡人，空窍尚未开辟。
var stage := 0
var capacity := 0.0
var essence := 0.0
var potential := 44.0 # 新角色创建时固定；开窍前不向界面透露。
var aptitude_gain := 0.0 # 后天资质增长，四种原创蛊共享最多 20 个百分点。
var refined_essence := 0.0
var wall_progress := 0.0
var stone_reserve := 0.0
var crossing := false
var crossing_seconds := 0.0
const CROSSING_DURATION := 30.0

func is_open() -> bool:
	return rank>=1

func improve_aptitude(amount: float, ceiling: float) -> float:
	if rank<4 or amount<=0: return 0.0
	var gain:=maxf(0,minf(amount,minf(20.0-aptitude_gain,minf(99,ceiling)-capacity)))
	capacity+=gain
	aptitude_gain+=gain
	return gain # 只扩大容量，不补充真元、不升阶、不修改创建时的潜力。

func awaken() -> bool:
	if is_open(): return false
	rank=1
	stage=0
	capacity=clampf(potential,20,99)
	essence=capacity
	refined_essence=0
	wall_progress=0
	stone_reserve=0
	return true

func aptitude() -> String:
	if not is_open(): return "未觉醒"
	if capacity >= 80: return "甲等"
	if capacity >= 60: return "乙等"
	if capacity >= 40: return "丙等"
	return "丁等"

func realm() -> String:
	if not is_open(): return "凡人 · 未开窍"
	return "%d 转%s" % [rank, STAGES[stage]]

func essence_name() -> String:
	if not is_open(): return "尚无真元"
	return ESSENCE[rank-1]+"真元" + (" · "+BRONZE_COLORS[stage] if rank==1 else "")

func recovery_rate() -> float:
	if not is_open(): return 0.0
	# 第十章明确丙等每小时四分、甲等八分；中间两档用同一梯度。
	return (8.0 if capacity>=80 else 6.0 if capacity>=60 else 4.0 if capacity>=40 else 2.0)/GAME_HOUR

func total() -> float:
	if not is_open(): return 0.0
	return essence+refined_essence

func fill_ratio() -> float:
	return clampf(total()/maxf(1,capacity),0,1)

func amount_text() -> String:
	return "%.1f / %.1f" % [total(),capacity]

func recover(delta: float) -> void:
	if not is_open(): return
	essence += minf(maxf(0,capacity-total()),recovery_rate()*delta)
	if stone_reserve > 0:
		var used := minf(stone_reserve,minf(maxf(0,capacity-total()),delta))
		essence += used
		stone_reserve -= used

func cost_at_stage(base: float) -> float:
	# 十倍跨转换算为模拟参数；保持一转既有耗元不变。
	return base/(pow(2.0,stage)*pow(10.0,maxi(1,rank)-1))

func begin_crossing() -> bool:
	if rank<1 or rank>=5 or stage!=3 or wall_progress<100 or essence<minf(30,capacity) or crossing: return false
	crossing=true
	crossing_seconds=0
	return true

func cancel_crossing() -> void:
	crossing=false
	crossing_seconds=0

func advance_crossing(delta: float) -> bool:
	if not crossing or delta<=0: return false
	var used:=minf(delta,CROSSING_DURATION-crossing_seconds)
	var expense:=used*minf(30,capacity)/CROSSING_DURATION
	if essence<expense:
		cancel_crossing()
		return false
	# 连续冲击消耗当前青铜真元，不使用战斗经验；时长与费用为模拟。
	essence-=expense
	crossing_seconds+=used
	if crossing_seconds<CROSSING_DURATION-0.0001: return false
	rank+=1
	stage=0
	wall_progress=0
	essence/=10.0
	refined_essence=0
	cancel_crossing()
	return true

func can_spend(base: float) -> bool:
	if not is_open(): return false
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
	if not is_open(): return 0.0
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
	if not is_open(): return "尚未开窍，请先到地下溶洞花海引动希望蛊。"
	if wall_progress < 100: return "窍壁温养不足。"
	# 跨转突破涉及持续冲击、反震和资质瓶颈，未验收前不能直接经验升级。
	if stage == 3: return "已达到五转上限；升仙尚未开放。" if rank>=5 else "需在空窍页开始持续冲窍。"
	stage += 1
	wall_progress = 0
	essence = minf(capacity,essence/2.0+refined_essence)
	refined_essence = 0
	return "窍壁蜕变为%s，达到%s。" % [WALLS[stage],realm()]

func save_data() -> Dictionary:
	return {"rank":rank,"stage":stage,"capacity":capacity,"essence":essence,"refined_essence":refined_essence,"wall_progress":wall_progress,"stone_reserve":stone_reserve,"potential":potential,"aptitude_gain":aptitude_gain}

func load_data(d: Dictionary) -> void:
	cancel_crossing()
	rank=clampi(int(d.get("rank",1)),0,5) # 缺少字段的旧蛊师档仍按一转恢复。
	potential=clampf(float(d.get("potential",d.get("capacity",44))),20,99)
	aptitude_gain=clampf(float(d.get("aptitude_gain",0)),0,20)
	if not is_open():
		aptitude_gain=0
		stage=0
		capacity=0
		essence=0
		refined_essence=0
		wall_progress=0
		stone_reserve=0
		return
	stage=clampi(int(d.get("stage",0)),0,3)
	capacity=clampf(float(d.get("capacity",44)),20,99)
	essence=clampf(float(d.get("essence",capacity)),0,capacity)
	refined_essence=clampf(float(d.get("refined_essence",0)),0,capacity-essence)
	if rank!=1 or stage==3:
		essence+=refined_essence
		refined_essence=0
	wall_progress=clampf(float(d.get("wall_progress",0)),0,100)
	stone_reserve=maxf(0,float(d.get("stone_reserve",0)))
