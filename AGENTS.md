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
3. 活动文档已于 2026-11-18 全量校正。后续修改同步相应专题、README 与验证记录；不能仅凭清单或文件名判断功能实现。规则见 [文档维护说明](文档维护说明.md)。
4. `_archive/` 是本地历史资料，`_gen.py` 是一次性补丁，不是构建入口；二者不随 Git 发布，克隆环境不要求存在。

## 代码导航

| 位置 | 当前职责 |
| --- | --- |
| `godot/main.tscn` → `godot/scripts/Main.gd` | 运行入口；动态构建场景、战斗、AI、捕获、炼化、存档、菜单及自测入口 |
| `godot/scripts/GameData.gd` | 蛊虫与世界数据；`GU`、`GU_ORDER` 是当前三种正式蛊；旧 60 蛊表在归档，不参与主循环 |
| `godot/scripts/World.gd` | 160×120 格地图、分块地面、碰撞、九处建筑入口与九个自由探索点；旧 80×60 区域的随机序列保留。并非 TileMapLayer |
| `godot/scripts/ApertureState.gd`、`GuVirtual.gd` | 普通空窍/真元与蛊虫独立实例、居处、本命及快捷绑定 |
| `godot/scripts/GuArt.gd`、`godot/assets/gu/painted/` | 三种正式蛊的统一透明插画与生成来源记录；旧 SVG 仅保留历史署名 |
| `godot/scripts/CommissionLedger.gd`、`VillageUI.gd`、`MiniMapUI.gd` | 可选委托状态/结算、商铺学堂与营地菜单、地图游历记录 |
| `godot/scripts/Player.gd`、`Enemy.gd`、`BodyComponent.gd` | 实体状态、绘制与人体部位伤害 |
| `godot/scripts/Fx.gd`、`TopLayer.gd`、`HUD.gd`、各 `*UI.gd` | 战斗表现、HUD 与界面；检查是否被主场景实际实例化 |
| `godot/scripts/HungerSystem.gd`、`FoodSystem.gd`、`Inventory.gd`、`GuManager.gd`、`GuVirtual.gd` | 饥饿、喂食、物品与蛊虫实例 |
| `godot/scripts/PlantSystem.gd`、`AnimalSystem.gd`、`MonsterSystem.gd` | 生态子系统；存在脚本不等于所有设计已接入主循环 |
| `godot/test_hunger.tscn`、`godot/scripts/TestHungerScene.gd`、`godot/scripts/GameManager.gd` | 生态系统的独立测试场景与其保存/加载逻辑 |

Autoload 名称为 `Hunger`、`Plants`、`Animals`、`Monsters`、`Food`、`Inv`、`Gus`。它们与 `HungerSystem`、`Inventory`、`GuManager` 等 `class_name` 不同；修改前检查 `project.godot` 与 `/root/...` 调用。

## 实现约定

- 沿用现有 GDScript 的缩进、命名和类型写法；不为局部需求整文件格式化、升级引擎或迁移渲染器。
- 当前数据主要位于 GDScript 字典；文档中的 JSON/Resource 示例是设计参考，不能假设项目已有对应文件或加载器。
- 增加或调整玩法时追踪输入、状态变化、数值结算、UI 与保存/加载。新字段读取旧存档时给出合理默认值。
- `player.owned` 是兼容模板列表，`captured` 是外部未炼化蛊，`Gus.owned_gus` 是独立实例。`skill_slots` 存实例 ID，`location` 区分 aperture/body/bag。背包、空窍和三个快捷键不得合并。
- 正式存档是 `user://canon_save.json`（version 6，新增委托状态；兼容 version 5，缺失委托默认空；兼容 version 4 的 80 格行宽探索记录）；旧 `save.json` 保留且不自动迁移。旧生态测试 `test_save.sav` 不证明当前规则正确。
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
