class_name BoarCultivation
extends RefCounted

# 身体上的永久改造，不随某只蛊的死亡/取出消失。速度、共享上限为试玩参数。
const DAY := 1440.0
const DAILY_LIMIT := 15.0
const GAIN_PER_SECOND := 0.02
const ATTACK_GAIN := 11.0
var progress := 0.0
var daily_used := 0.0
var day_elapsed := 0.0
var active_id := "" # 临时催动状态，不保存；读档后需要主动开始。

func available() -> bool:
	return progress<1.0 and daily_used<DAILY_LIMIT-0.0001

func tick(delta: float, aperture: ApertureState, can_train: bool) -> void:
	if delta<=0: return
	if not can_train: active_id=""
	var remaining:=delta
	while remaining>0.0001:
		var step:=minf(remaining,DAY-day_elapsed)
		if active_id!="":
			var training:=minf(step,minf(DAILY_LIMIT-daily_used,(1.0-progress)/GAIN_PER_SECOND))
			if training>0 and aperture.spend(training):
				daily_used+=training
				progress=minf(1.0,progress+training*GAIN_PER_SECOND)
			else: active_id=""
			if not available(): active_id=""
		day_elapsed+=step
		remaining-=step
		if day_elapsed>=DAY-0.0001:
			day_elapsed=0.0
			daily_used=0.0
		# 空闲的大跨度只推进时钟，不离线/自动重复养力。
		if active_id=="" and remaining>=DAY:
			remaining=fmod(remaining,DAY)
			daily_used=0.0

func attack_bonus() -> float:
	return progress*ATTACK_GAIN

func save_data() -> Dictionary:
	return {"progress":progress,"daily_used":daily_used,"day_elapsed":day_elapsed}

func load_data(data: Dictionary) -> void:
	progress=clampf(float(data.get("progress",0)),0,1)
	daily_used=clampf(float(data.get("daily_used",0)),0,DAILY_LIMIT)
	day_elapsed=clampf(float(data.get("day_elapsed",0)),0,DAY-0.0001)
	active_id=""
