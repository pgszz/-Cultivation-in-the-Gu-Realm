# 《蛊道修仙：青茅山》项目协作说明

## 项目与工作方式

- 默认用中文沟通；保留现有英文代码标识符与中文玩法术语。
- 工作区根目录放设计文档，实际游戏工程在 `godot/`。执行引擎命令时指定该工程目录。
- 当前基线是 Godot 4.3、GDScript、2D、GL Compatibility 渲染器，以 `godot/project.godot` 为准。
- 用户要求原著世界/蛊虫规则结合自由探索，不强制按小说剧情推进。当前为青茅山前期的自由探索、供养、炼化、温养与战斗试玩；杀怪不是升级条件。新增探索地点和资源安排可作为明确标注的游戏设计，不以未实现原著剧情为探索门槛。先读 `godot/CANON.md` 的正文依据、模拟参数和未开放项。
- 项目已在 2026-11-18 初始化 Git，主分支 `main`。操作前检查实际状态和远程；源码发布排除本地备份、测试副本、玩家存档与缓存。

## 开始任务时

1. 先读根目录 `README.md`、`godot/README.md`、`godot/project.godot`，再定位相关脚本；只按任务需要读取根目录专题文档。
2. “当前行为”以场景引用、实际调用与验证结果为准；“目标行为”以用户最新需求与核对过的小说正文为准；旧设计稿不能冒充原著。发现两者不同，说明差异后完成当前任务，不能自动把实现当成正确设计。
3. 活动文档已于 2026-11-20 全量整理去重；正文规则、专题数值与历史验证分别维护。后续修改同步相应专题、README 与验证记录；不能仅凭清单或文件名判断功能实现。规则见 [文档维护说明](文档维护说明.md)。
4. `_archive/` 是本地历史资料，`_gen.py` 是一次性补丁，不是构建入口；二者不随 Git 发布，克隆环境不要求存在。

## 代码导航

| 位置 | 当前职责 |
| --- | --- |
| `godot/main.tscn` → `godot/scripts/Main.gd` | 运行入口；动态构建场景、战斗、AI、捕获、炼化、存档、菜单及自测入口 |
| `godot/scripts/GameData.gd` | 蛊虫与世界数据；`GU`、`GU_ORDER` 是当前正式蛊；旧 60 蛊表在归档，不参与主循环 |
| `godot/scripts/World.gd` | 480×360 格地图、按视野加载地面（常规视口缓存 24 块）、碰撞、25 处建筑入口（白家、熊家各九处）与三十二个自由探索点；保留旧 320×240 生成尺寸，白家/熊家寨迁至远山/山脚，边界与道路局部调整。并非 TileMapLayer |
| `godot/scripts/TerrainLayers.gd`、`TerrainTests.gd` | 程序生成分层山体、两层 128×96 洞网、每格每高度独立 HP、逐块破坏/开路；World 层碰撞、FogOfWar 分层迷雾和 AtlasMap 查看，专项 terraintest，地图版本 7 |
| `godot/scripts/EnvironmentInteractions.gd`、`AdventureTests.gd` | 有限水火霜反应、玩家水体通行、蛊术落点开凿与整合专项 `adventuretest`；version 8 可选 `environment` |
| `godot/scripts/ApertureState.gd`、`GuVirtual.gd`、`CultivationGu.gd`、`HundredGuTests.gd` | 一至五转空窍、四/五转原创资质增长、同转舍利消费事务；独立实例/居处/本命/快捷位，专项 hundredgutest |
| `godot/scripts/AwakeningUI.gd`、`AwakeningView.gd`、`AwakeningTests.gd` | 凡人开局、创建时固定随机丁至甲等资质、花海希望蛊开窍、插画/动画与事务保存；专项 awakeningtest |
| `godot/scripts/GuEffects.gd`、`BoarCultivation.gd` | 互斥皮蛊、临时蛮力/耐力、碰撞腾跃、体力与拉伤负担；豕蛊永久养力分开结算 |
| `godot/scripts/GuArt.gd`、`godot/assets/gu/painted/` | 正式蛊的统一透明插画与生成来源记录；旧 SVG 仅保留历史署名 |
| `godot/scripts/CommissionLedger.gd`、`VillageUI.gd`、`MiniMapUI.gd` | 可选委托状态/结算、商铺学堂与营地菜单、地图游历记录 |
| `godot/scripts/SouthernBorderData.gd`、`SouthernBorderMap.gd`、`SouthernBorderUI.gd`、`SouthernBorderTests.gd` | 南疆 29 处山川、23 家族的地理志；事实/读者推演/时代与来源分开，缩放检索；随 maptest 验证；地理志本身不可行走，商家城条目另接独立商区 |
| `godot/scripts/ShangCity.gd`、`ShangCityUI.gd`、`ShangCityTests.gd` | 独立商区、演武/赌石/订单/往返与事务保存；version 8 可选 `shang_city`，专项 shangtest |
| `godot/scripts/CanonPeople.gd`、`CanonPeopleTests.gd` | 四位原著人物、独立形象、资料/台词/路线，专项 canonpeopletest；不是完整人物持蛊战斗 |
| `godot/scripts/SettlementData.gd`、`SettlementTests.gd` | 白家与熊家各九处建筑、街区范围/住民/商品/服务、逐屋交互与独立存档回归；专项入口 villagetest |
| `godot/scripts/PopulationSystem.gd`、`WorldPerson.gd`、`PopulationTests.gd` | 34 名移动人员（30 普通人员与四位原著人物）、日程/道路寻路、商队/强盗/护卫交战与交易，版本 7 可选 population 字段；专项入口 populationtest |
| `godot/scripts/Player.gd`、`Enemy.gd`、`BodyComponent.gd` | 实体状态、绘制与人体部位伤害 |
| `godot/scripts/Fx.gd`、`GuVfx.gd`、`TopLayer.gd`、`HUD.gd`、各 `*UI.gd` | 蛊虫月牙弹道/护体/辅助表现、HUD 与界面；GuVfx 只读实际状态，不结算数值；专项入口 guvfxtest |
| `godot/scripts/HungerSystem.gd`、`FoodSystem.gd`、`Inventory.gd`、`GuManager.gd`、`GuVirtual.gd` | 饥饿、喂食、物品与蛊虫实例 |
| `godot/scripts/WildlifeSystem.gd`、`WildlifeArt.gd` | 主游戏十三处栖息地、七种动物/两种独立妖兽、视野外刷新、成长/修炼、持久化与插画；由 Main 持有，不是 Autoload |
| `godot/scripts/WildlifeAnimation.gd`、`assets/wildlife/wildlife_motion.gdshader` | 九种生灵的网格步态、攻击/受伤/倒伏；由 WildlifeSystem 的游戏时钟推进，命中由 Main 的伤害入口结算 |
| `godot/scripts/PlantSystem.gd`、`AnimalSystem.gd`、`MonsterSystem.gd` | 生态数据与旧独立接口；主游戏读取 AnimalSystem.ANIMALS / MonsterSystem.WILDLIFE，其他旧接口不等于已接入 |
| `godot/test_hunger.tscn`、`godot/scripts/TestHungerScene.gd`、`godot/scripts/GameManager.gd` | 生态系统的独立测试场景与其保存/加载逻辑 |

Autoload 名称为 `Hunger`、`Plants`、`Animals`、`Monsters`、`Food`、`Inv`、`Gus`。它们与 `HungerSystem`、`Inventory`、`GuManager` 等 `class_name` 不同；修改前检查 `project.godot` 与 `/root/...` 调用。

## 实现约定

- 沿用现有 GDScript 的缩进、命名和类型写法；不为局部需求整文件格式化、升级引擎或迁移渲染器。
- 当前数据主要位于 GDScript 字典；文档中的 JSON/Resource 示例是设计参考，不能假设项目已有对应文件或加载器。
- 增加或调整玩法时追踪输入、状态变化、数值结算、UI 与保存/加载。新字段读取旧存档时给出合理默认值。
- 当前一百二十蛊都有图片；肉身批次20种见 `肉身状态蛊.md`、`BodyGuEffects.gd`、专项 `bodygutest`；version 8 可选 `body_gu` 保存骨改造、锻筋进度和冷却，临时效果不读档恢复。新增 40 种（五种原著舍利、35 种原创，四/五转资质蛊可用）见 `百蛊扩充.md`，专项 `hundredgutest`。一至五转修炼已接，跨转参数为沙盒设计；舍利只能作用于相同转数且未达巅峰的角色，消费成功与升阶一起保存。`aperture.aptitude_gain` 为 version 8 可选数字字段，旧档默认 0，四种资质蛊共享终身 +20 点且不改变 potential。此前六十蛊：原有二十九种，加三十一种原创扩充（20 种一转、11 种二转，见 `六十蛊扩充.md`；专项 `sixtygutest`）。用户已允许原创；溪流为原著名录与玩法改编，该批其余十二种及本轮三十一种标明原创。`UtilityGuEffects` 接入治疗、侦察、控制、移动、防御与生计；三寨获取和专属配方见 `蛊虫用途扩展.md`。新增七蛊食材未核实，分别用独立专用供养抽象；不能把供养占位写成原著配方。体力/蛮力负担保存于 version 7 可选 `gu_physical`，旧档默认满体力/零负担，主动蛊效读档关闭。
- `player.owned` 是兼容模板列表，`captured` 是外部未炼化蛊，`Gus.owned_gus` 是独立实例。`skill_slots` 存实例 ID，`location` 区分 aperture/body/bag。背包、空窍和三个快捷键不得合并。
- 新角色 `rank=0` 为凡人，`aperture.potential` 在创建时随机 20–99 并保存；开窍前不显示潜力、不产真元。希望蛊为独立仪式蛊，不加入正式可养用蛊表、不创建实例或成为本命；开窍后才补给未炼化月光蛊。旧蛊师档保留状态，玩法测试使用明确已开窍夹具，不能为旧测试恢复自动开窍。依据见 [希望蛊开窍系统](希望蛊开窍系统.md)。
- 正式角色存档是 `user://characters/<角色ID>.json`（version 8，保留 version 4–7 已支持数据兼容）。`CharacterSaves` 统一管理：死亡 `.dead` 标记优先于快照，死亡角色只能查看或删除；删除 `.deleted` 标记防止角色重现。旧 `canon_save.json` 一次导入为“旧角色”并保留原文件，删除后不重复导入；更旧 `save.json` 不迁移。地图兼容与具体字段见技术方案。旧生态测试 `test_save.sav` 不证明当前规则正确。
- 普通动物和妖兽为独立类别，`is_animal` / `is_monster` 互斥，通用战斗判断用 `is_creature()`；普通动物不修炼、不变妖兽。妖兽自行修炼阶段明确为用户要求的沙盒设计。生态专项使用 `wildlifetest`。
- 不手工修改 `godot/.godot/` 中的引擎缓存。新增资源引用使用 `res://`；运行时存档使用 `user://`。

## 运行与验证

先定位 Godot 4.3 并确认版本。下面路径只是示例，替换为实际安装位置；所有命令在仓库根目录执行：

```powershell
$godotExe = 'C:/Tools/Godot/Godot_v4.3-stable_win64_console.exe'
& $godotExe --version
python -X utf8 tools/check_docs.py
python -X utf8 tools/check_game.py --godot $godotExe --checks canontest
# 下行是实际游玩，会使用玩家真实存档，不用于自动测试
& $godotExe --path .\godot
```

- 修改代码或场景后，执行导入/解析检查与受影响的最小自测集合。UI 改动还需要窗口模式验证；性能结论需要说明渲染模式和机器环境。
- 自测参数及结果判读见 `gudao-godot-check`。现有多数自测只输出日志，退出码 0 不等于行为正确。
- 运行游戏自测使用根目录 `python -X utf8 tools/check_game.py --checks canontest`，自动隔离工程与 `user://`。旧自测包含退役预期，不可拿历史通过结果证明当前版本。
- 只改文档或 skills 时运行 `python -X utf8 tools/check_docs.py`，检查结构、链接、路径与已登记事实；不强制启动游戏。事实检查仍需结合调用链，脚本不代替语义审阅。
- 汇报时区分实际验证通过、仅静态检查、未运行；无法执行时写明原因。

## 项目 skills

项目技能放在 `.agents/skills/`。按任务读取对应 `SKILL.md`，不要每次全量加载。

| Skill | 使用场景 | 入口 |
| --- | --- | --- |
| `gudao-godot-dev` | 游戏功能实现、GDScript 调试、场景和数据接入 | [.agents/skills/gudao-godot-dev/SKILL.md](.agents/skills/gudao-godot-dev/SKILL.md) |
| `gudao-godot-check` | 回归测试、日志判读、界面及性能验证 | [.agents/skills/gudao-godot-check/SKILL.md](.agents/skills/gudao-godot-check/SKILL.md) |
| `gudao-design-sync` | 将玩法设计对应到代码、核实进度、同步设计文档 | [.agents/skills/gudao-design-sync/SKILL.md](.agents/skills/gudao-design-sync/SKILL.md) |

可显式调用，例如：`用 $gudao-godot-dev 完成蛊虫喂食接入`。
