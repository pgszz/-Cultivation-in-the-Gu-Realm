---
name: gudao-godot-dev
description: 为《蛊道修仙：青茅山》实现或修复 Godot 4.3 游戏功能，处理 GDScript、场景、蛊虫数据、战斗、生态与界面接入。用于本项目的实际开发；仅做文档整理或执行回归验证时不使用。
---

# 蛊道 Godot 开发

目标是把用户要求接到可玩的主循环。以下代码路径均相对于包含 `AGENTS.md` 与 `godot/` 的项目根目录。

## 定位实际运行链路

- 先读根目录 `AGENTS.md`、`godot/project.godot` 和相关代码。入口是 `main.tscn` → `Main.gd`，大量节点由 `_build_*` 动态实例化，不只靠 `.tscn` 判断场景结构。
- 对目标类搜索构造、方法调用、信号连接和 Autoload 注册，确认它是否已接入。`ElementSystem.gd`、`DestructibleTerrain.gd` 等文件的存在不能证明主地图在用它们；旧通用元素自动反应已退役；以 `GameData.GU` 和实际调用链为准。
- 实时战斗、捕获和炼化主要在 `Main.gd`；修改时沿输入 → 判定 → 状态变化 → 表现 → 存档追踪，避免只新增一个无人调用的类。
- 先查看 `godot/CANON.md`，再查看任务涉及的设计文档；区分原著事实、游戏模拟参数、尚未实现与旧设定。当前主打自由探索，遵守原著规则但不强制照小说剧情走；新增沙盒地点和采集安排注明为游戏设计。数值或规则存在实质冲突且无法从用户要求判断时，再询问需要的选择。

## 关键接入点

| 任务 | 需要一起检查的代码 |
| --- | --- |
| 新蛊虫、技能、数值 | `GameData.GU`、`GU_ORDER`、`Main.cast_skill`、宿主分配/刷新、图鉴与保存的模板 ID |
| 捕获、炼化、装备、喂食 | `player.captured` / `owned`、`Main._finish_refine`、`Gus.owned_gus`、`GuVirtual`、`Hunger`、`Food`、`Inv` |
| 人体伤害、死亡、治疗 | `BodyComponent`、`Main.damage_player` / `player_death` / `respawn` / `_use_bandage`、`BodyUI` |
| 地图、生态、地标 | `World`、`GameData`、`Main._spawn_initial_enemies` / `random_spawn` / `_try_poi_interact`、小地图与目标提示 |
| 界面、快捷键 | `Main._build_ui_overlays` / `_unhandled_input`、目标 UI 类、暂停状态与输入拦截 |
| 委托、营地、游历记录 | `CommissionLedger`、`VillageUI`、`MiniMapUI`、`Main._try_poi_interact/claim_camp_supplies/field_bandage` |
| 蛊虫图片 | `GuArt.PORTRAITS`、`assets/gu/painted/SOURCE.json`、图鉴/背包/空窍/炼化和场景 |
| 保存与读取 | `Main.save_game` / `_load_save` 使用 canon_save.json；旧 save.json 保留，不自动覆盖或迁移 |

## 项目中特别容易遗漏的约束

- `GU` 和 `GU_ORDER` 当前只开放月光蛊、酒虫、玉皮蛊。新增蛊先核对名字、转数、用养炼与获取方式；旧 60 蛊表和通用元素公式不能直接恢复。
- 蛊虫模板 ID、运行时实例 ID、中文显示名不能混用。饥饿注册与喂食要使用对应实例身份；加载后还要恢复注册及引用。
- 背包放外部物品与外部携带蛊；空窍管理元海和寄居；三个快捷键绑定实例 ID，不限制蛊虫拥有数。保存位置、身份、饥饿和本命关系时同时检查 UI 联动。
- 野生寄生蛊需要物种与来源依据；当前不随机把家族培育月光蛊或稀有蛊塞给野兔。普通猎获不奖励修行经验或凭空掉元石。
- 当前按具体食性喂养；断粮可导致永久饿死，普通喂食不能复活。离线不推进，普通菜单暂停，炼化工作时推进已炼化蛊饥饿。宽限时长与恢复速度是游戏参数，写入 CANON，不能当正文公式。
- 对新能力优先复用现有信号和数据入口。是否拆分 `Main.gd` 由当前需求决定，不把局部修复扩大为整体重构。

## 完成与验证

使用项目的 [回归验证 skill](../gudao-godot-check/SKILL.md) 选择与改动相关的检查，按其说明隔离存档并判读日志。只为重要行为、边界条件或实际缺陷补验证，不为低影响的文档/格式变动增加测试。

说明玩家能观察到的变化、修改入口、实际执行的验证以及尚未接入的部分。若行为或操作方式变化，更新 `godot/README.md` 和根 README 的相关段落；只有任务涉及设计口径时才同步专题设计文档。文档更新后运行 `python -X utf8 tools/check_docs.py`。
