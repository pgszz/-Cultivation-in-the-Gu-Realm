"""Run isolated Godot checks; keep logs and screenshots outside the game project."""
from __future__ import annotations
import argparse, datetime, json, os, re, shutil, subprocess, uuid
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DEFAULT_GODOT=Path(os.environ.get("LOCALAPPDATA",""))/"Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.3-stable_win64_console.exe"
CHECKS={"wildlifetest":"WILDLIFETEST checked=","canontest":"CANONTEST checked=","featuretest":"FEATURETEST checked=","perftest":"PERF fps=","probe":"PROBE respawn","bodytest":"BODYTEST player_body","bagtest":"BAGTEST reload","refinetest":"REFINETEST close","skilltest":"SKILLTEST","npctest":"NPCTEST close","bosstest":"BOSSTEST kill","animaltest":"ANIMALTEST killed","hosttest":"HOSTTEST","poitest":"POITEST ruin","polishtest":"POLISHTEST checked=","hunger":"AUTOTEST load"}
SHOTS={"guwave2","gudefense","gucricket","guwave2shop","guwave2food","gucombat","wildlife","wildlifebeasts","wildlifefield","wildlifecultivate","menu","village","interior","shop","journal","character","map","occlusion","bag","body","comp","elements","fog","reaction","meditation","destruction","repair","damageinterior","aperture","worldmap","waterfall","cave","exploration","atlasfull","minimal","commissions","camp","notes","gujade","guliquor","gulight","guwhite","gublack","gushop","gutraining","refine","itemcurrency","itemtimber","itembandage"}

SHOTS.update({"itemrabbit_meat","itemdeer_meat","itemwolf_meat","itembear_meat","itemboar_meat","itempheasant_meat","itempork_ration","mapzoom","mapguide","maparrival","mapexit","mapfrontier"})
CHECKS["shangtest"]="SHANGTEST checked="
CHECKS["awakeningtest"]="AWAKENINGTEST checked="
CHECKS["adventuretest"]="ADVENTURETEST checked="
CHECKS["terraintest"]="TERRAINTEST checked="
SHOTS.update({"blockmountain","underground","deepcave","layermap","blockimpact"})
CHECKS["maptest"]="MAPTEST checked="
CHECKS["villagetest"]="VILLAGETEST checked="
CHECKS["inspecttest"]="INSPECTTEST checked="
CHECKS["socialtest"]="SOCIALTEST checked="
CHECKS["exchangetest"]="EXCHANGETEST checked="
SHOTS.update({"npcinspect","npcrelations","npcstatus","npcdead","npcitems","npcsell","npcloot"})
CHECKS["arttest"]="ARTTEST checked="
CHECKS["appearancetest"]="APPEARANCETEST checked="
CHECKS["canonpeopletest"]="CANONPEOPLETEST checked="
CHECKS["controltest"]="CONTROLTEST checked="
CHECKS["charactertest"]="CHARACTERTEST checked="
CHECKS["customizetest"]="CUSTOMIZETEST checked="
CHECKS["statustest"]="STATUSTEST checked="
CHECKS["guvfxtest"]="GUVFXTEST checked="
CHECKS["utilitygutest"]="UTILITYGUTEST checked="
CHECKS["sixtygutest"]="SIXTYGUTEST checked="
CHECKS["hundredgutest"]="HUNDREDGUTEST checked="
CHECKS["bodygutest"]="BODYGUTEST checked="
CHECKS["guupgradetest"]="GUUPGRADETEST checked="
CHECKS["wildlifeanimtest"]="WILDLIFEANIMTEST checked="
CHECKS["populationtest"]="POPULATIONTEST checked="
CHECKS["perfscenes"]="PERF_SUMMARY "
CHECKS["rendertest"]="RENDERTEST checked="
SHOTS.update({"population","caravan","bandits","caravantrade","populationmotion"})
SHOTS.add("wildlifemotion")
SHOTS.update({"baivillage","xiongvillage"})
SHOTS.update({"baidistrict","xiongdistrict","baishop","xiongclinic","villagedirections","clanspring","villagemap"})

def assess_performance(output, label):
    """Require measured budgets; a successful run is not a performance pass."""
    required={"opening"}
    if label=="perfscenes": required.update({"walk","frontier_travel","wide_view","underground","deep_cave","interior","wildlife_combat"})
    samples=[]
    try:
        samples=[json.loads(line.removeprefix("PERF_SUMMARY ")) for line in output.splitlines() if line.startswith("PERF_SUMMARY ")]
        passed=required=={s["scene"] for s in samples} and len(samples)==len(required)
        for s in samples:
            passed=passed and s["passed"] is True and s["full_quality"] is True and s["frames"]>0 and s["sample_seconds"]>=4.5 and s["fps_mean"]>=55 and 0<s["p95_ms"]<=22
    except (ValueError, KeyError, TypeError):
        passed=False
        samples=[]
    return bool(passed),samples

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--godot",type=Path,default=DEFAULT_GODOT)
    parser.add_argument("--source-project",type=Path,default=ROOT/"godot",help="Source project or a pinned snapshot; user data is always isolated")
    parser.add_argument("--checks",nargs="*",choices=CHECKS,default=["canontest"])
    parser.add_argument("--screenshots",nargs="*",choices=sorted(SHOTS),default=[])
    parser.add_argument("--timeout",type=int,default=60)
    parser.add_argument("--resolution",default="1280x720")
    args=parser.parse_args()
    if not args.godot.is_file(): parser.error("Godot executable not found; supply --godot")
    run=ROOT/".test-runs"/(datetime.datetime.now().strftime("%Y%m%d-%H%M%S")+"-"+uuid.uuid4().hex[:6])
    project=run/"project"
    shutil.copytree(args.source_project,project,ignore=shutil.ignore_patterns(".godot","screenshots","shot_*.png","*.import"))
    original=(project/"project.godot").read_text(encoding="utf-8")
    report=[]
    def namespace(label):
        config=re.sub(r'^config/name=.*$',f'config/name="Gudao-QA-{run.name}-{label}"',original,flags=re.M)
        config=config.replace("[application]","[application]\nconfig/use_custom_user_dir=false")
        (project/"project.godot").write_text(config,encoding="utf-8")
    def execute(label,extra,expected=None):
        command=[str(args.godot),"--path",str(project),*extra]
        performance=None
        try:
            result=subprocess.run(command,capture_output=True,text=True,encoding="utf-8",errors="replace",timeout=args.timeout,creationflags=getattr(subprocess,"CREATE_NO_WINDOW",0))
            output=result.stdout+result.stderr
            passed=result.returncode==0 and not re.search(r"SCRIPT ERROR|(^|\n)ERROR:",output)
            if expected: passed=passed and expected in output
            if label=="skilltest": passed=passed and "fails=[]" in output
            if label in ("rendertest","shangtest","awakeningtest","polishtest","featuretest","canontest","wildlifetest","maptest","terraintest","adventuretest","villagetest","wildlifeanimtest","populationtest","arttest","appearancetest","canonpeopletest","guvfxtest","utilitygutest","sixtygutest","hundredgutest","bodygutest","guupgradetest","inspecttest","socialtest","exchangetest","controltest","charactertest","characterrestart","customizetest","customizerestart","statustest"): passed=passed and "failures=[]" in output
            if label in ("hosttest","animaltest"): passed=passed and "TEST none" not in output
            execution_passed=bool(passed)
            if label in ("perftest","perfscenes"):
                budget_passed,samples=assess_performance(output,label)
                performance={"execution_passed":execution_passed,"budget_passed":budget_passed,"samples":samples,"minimum_fps":55,"maximum_p95_ms":22}
                passed=passed and budget_passed
        except subprocess.TimeoutExpired as e:
            def decoded(value):
                return value.decode("utf-8",errors="replace") if isinstance(value,bytes) else (value or "")
            output="TIMEOUT\n"+decoded(e.stdout)+decoded(e.stderr)
            passed=False
        (run/(label+".log")).write_text(output,encoding="utf-8")
        report.append({"check":label,"passed":bool(passed),"command":command,"source_project":str(args.source_project.resolve()),**({"performance":performance} if performance is not None else {})})
        print(("PASS " if passed else "FAIL ")+label,flush=True)
        if performance is not None:
            print("  execution="+("ok" if performance["execution_passed"] else "failed")+" budget="+("met" if performance["budget_passed"] else "not met / missing measurements"),flush=True)
            for s in performance["samples"]:
                print(f"  {s.get('scene')}: fps={s.get('fps_mean')} p95_ms={s.get('p95_ms')} draws={s.get('draws_median')} nodes={s.get('nodes')}",flush=True)
        if not passed: print(output[-6000:],flush=True)
        return passed
    namespace("import")
    print("RUN "+str(run),flush=True)
    if execute("import",["--headless","--import"]):
        for check in args.checks:
            namespace(check)
            extra=["--resolution",args.resolution] if check in ("rendertest","perfscenes","shangtest","awakeningtest","featuretest","perftest","canontest","wildlifetest","maptest","terraintest","adventuretest","villagetest","wildlifeanimtest","populationtest","arttest","appearancetest","canonpeopletest","guvfxtest","utilitygutest","sixtygutest","hundredgutest","bodygutest","guupgradetest","inspecttest","socialtest","exchangetest","controltest","charactertest","customizetest","statustest") else ["--headless"]
            if check=="hunger": extra+=["res://test_hunger.tscn","--","--autotest"]
            else: extra+=["--","--"+check]
            passed=execute(check,extra,CHECKS[check])
            if check=="charactertest" and passed:
                execute("characterrestart",extra,CHECKS[check])
            if check=="customizetest" and passed:
                execute("customizerestart",extra,CHECKS[check])
        for shot in args.screenshots:
            namespace("shot"+shot)
            execute("shot"+shot,["--resolution",args.resolution,"--","--shot"+shot],"SHOT")
            filename={"bag":"shot_bag.png","body":"shot_body.png","comp":"shot_comp.png"}.get(shot,"shot_"+shot+".png")
            src=project/filename
            if src.is_file(): shutil.copy2(src,run/filename)
    (run/"report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    (ROOT/".test-runs/latest.txt").write_text(str(run),encoding="utf-8")
    print("REPORT "+str(run/"report.json"),flush=True)
    return 0 if all(x["passed"] for x in report) else 1

if __name__=="__main__": raise SystemExit(main())
