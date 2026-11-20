# 当前检查与历史入口

更新：2026-11-20。[回归工作流](../SKILL.md) · [实际验证记录](../../../../godot/VALIDATION.md) · [截图索引](../../../../godot/screenshots/README.md)。

## 运行与判读

从根目录使用 `python -X utf8 tools/check_game.py --checks <入口> --resolution 1280x720 --timeout 240`，需要时加 `--godot`。运行器复制工程，并为每项检查设置独立用户数据命名空间；同一角色的重启检查保留对应测试命名空间。窗口测试顺序执行，尤其不能并行运行依赖鼠标或窗口切换的检查。

行为专项需同时满足退出正常、对应大写 `XXXTEST checked=非零 failures=[]` 且无 SCRIPT ERROR / Parse Error；数目含截图保存断言时应说明。界面变化检查 1280×720 与 960×540，打开图片核对，不以截图文件存在代替视觉验收。完整参数以 [check_game.py](../../../../tools/check_game.py) 的 CHECKS / SHOTS 为准。

## 行为专项

| 入口 | 范围 |
| --- | --- |
| `canontest` | 当前正式规则、真实 GUI 输入、战斗、用养炼、身体、委托、碰撞路线和保存；含山寨专项 |
| `awakeningtest` | 凡人创建、固定潜力、限制、Q 导航/E 花海、仪式完成/中断/死亡/离场、写盘失败回滚、旧档与希望蛊图鉴 |
| `charactertest` | 新建/选择/删除、多角色隔离、死亡锁、旧档一次迁入、损坏档和写盘失败；运行器追加 `characterrestart` |
| `customizetest` | 内置外观、PNG 导入/验证、模板与真实角色保存；追加 `customizerestart` 检查重启和死亡锁 |
| `guupgradetest` | 二转冲窍、材料多实例、实际合炼按钮、失败扣费、身份/快捷/口粮继承、月芒/白玉/月霓裳能力与保存；三档缩放下鼠标庇护、持续绘制与 NPC 真实减伤 |
| `utilitygutest` | 十三种用途蛊三寨购买、炼化、施法/治疗/控制/冷却/采集/视野及保存；全表专用口粮按实际总价采购，四种肉身口粮真实按钮、余额不足与伪造价格 |
| `sixtygutest` | 31 种原创蛊及此前名录，资源原子结算、转数门槛、互斥、弹道/中毒/环境/凿岩与保存 |
| `hundredgutest` | 40 种新增蛊、同转舍利各小阶消费、失败回滚、资质上限/中断/存档及一至五转修行 |
| `bodygutest` | 20 种肉身蛊、120 种总名录、永久改造/限时状态、实际部位伤害、禁止再生、费用预算/消费事务及保存 |
| `maptest` | 地图路线、地面缓存/离屏破坏、缩放/拖动/标点/取消/导航、旧址迁移；南疆目录/来源/检索和浏览隔离 |
| `villagetest` | 25 处入口、两寨逐屋 E 进出、交易/药堂/工坊、指路、敌对/死亡/毁屋与旧站位兼容 |
| `terraintest` | 四方向攻击/缩放、逐层 HP、唯一产料、遮挡/碎块暂停、两层路线/E 石阶/补给、地层隔离与旧山体迁移 |
| `adventuretest` | 攻击蛊开凿同高地板、首障碍、有限反应、三层游泳/上岸/读档、情境对话/包扎/记忆；固定 20/44/84/99 容量的满/半真元显示与施法瞄准坐标 |
| `shangtest` | 商区入口/E/M、场景隔离、赌石固定结果、交易回滚、建筑坍塌/修缮、订单、演武结算/弃权/死亡与返程 |
| `populationtest` | 34 名人员与路线、商队长期小步模拟、日程/暂停、E 交谈/购买、交战/补货/领队死亡和保存；非实际等待或性能采样 |
| `canonpeopletest` | 四位原著人物身份/专属外观、旧档补人、交谈/资料、兄弟关系、人物志标点、保存与死亡不复活 |
| `inspecttest` | Alt 点击查看与普通左键攻击、属性/关系/状态/物品、双向交易/搜刮、容量/余额/距离/敌对限制及旧库存迁移 |
| `socialtest` | 视距与头像分页、点击不穿透、场景隔离、好感防刷、真实关系/经历/目击死亡、角色切换与旧档 |
| `exchangetest` | 真实赠礼/盗窃、收礼条件/双边库存、失败不结算、防刷、2%/5% 反击及普通分支、实际攻击与保存 |
| `statustest` | 头像与快捷页、属性增减/持续条件、施法/移动/护盾、到期/断供/场景/昏迷/读档后的只读汇总 |
| `appearancetest` | 24 套人员形象、六格动作/透明边缘、同组差异、固定与移动人物保存/回退、查看与遗体一致性 |
| `arttest` | 人物攻击/受击/倒地、身体反馈、建筑/家具坍塌/修复、动画暂停、读档终态与唯一产料 |
| `guvfxtest` | 十三蛊特效与实际命中/减伤、互斥/断供/移出/死亡/暂停/读档、两档画质；包含图片保存断言 |
| `controltest` | 移动朝向/斜移/碰墙/攻击瞄准、设置、窗口切换/尺寸/F11 恢复、旧配置与重启 |
| `wildlifetest` | 动物/妖兽身份、栖息地/安全刷新、成长与修炼中断/上限、掉落、暂停、保存和图鉴按钮 |
| `wildlifeanimtest` | 九物种真实动画、命中时刻/闪避/阻挡/打断、步态/暂停、死亡结算与保存；真实畅通路径上狼与两类妖兽追击、真实碰撞后停止迈步 |
| `rendertest` | 按镜头创建/释放地物、离屏破坏与读档废墟、预加载中途破坏、山体/洞层实际纹理更新、静止复用和缓存预算 |
| `perftest` | 完整画质，开局预热 3 秒后采样 5 秒；`PERF_SUMMARY` 的均帧率 ≥55、P95 ≤22 ms 才满足当前 60 FPS 目标的窗口容差；缺数据失败 |
| `perfscenes` | 同门槛检查开局、行走、180 px/s 跨区镜头移动、0.65 缩放、两层地下、室内与短时生灵攻击；窗口需前台且串行执行，建议 timeout 240 |

六十蛊、百蛊专项保留各自批次行为，不独自声明当前总数仍是 60 或 100。凡人开局后的玩法测试必须使用明确已开窍夹具，不能改变正式创建流程以迎合旧断言。

## 截图与演示

专项可自行输出 `shot_*.png`，例如开窍、商区、人物、百蛊和肉身蛊；通常不需要另加截图参数。通用 `--screenshots` 可选入口：

| 参数组 | 用途 |
| --- | --- |
| `aperture bag journal map worldmap` | 空窍、背包、身体/修行录、地图 |
| `atlasfull mapzoom mapguide maparrival mapexit mapfrontier` | 全图、缩放、边缘箭头、到达、室内出口与桥梁 |
| `baivillage xiongvillage baidistrict xiongdistrict baishop xiongclinic villagedirections clanspring villagemap` | 新寨口、两寨街区、服务、指路、元泉和寨内地图 |
| `blockmountain underground deepcave layermap blockimpact` | 山体、浅/深层洞网、分层地图和飞块 |
| `population caravan bandits caravantrade populationmotion` | 日常人员、商队/强盗、交易及连续 AI 演示 |
| `npcinspect npcrelations npcstatus npcdead npcitems npcsell npcloot` | 人物查看、伤亡、交易与搜刮 |
| `village interior occlusion waterfall cave repair destruction damageinterior` | 环境、室内、遮挡、检查修缮与受损 |
| `comp gujade guliquor gulight guwhite gublack refine` | 基础蛊插画、图鉴与炼化 |
| `commissions camp notes` | 委托、营地与游历记录 |
| `wildlife wildlifebeasts wildlifefield wildlifecultivate wildlifemotion` | 两类图鉴、成长/修炼场景和九物种连续动作 |

图鉴/地图演示可能预置发现、迷雾、资质、伤势与资金，不代表正常开局。`populationmotion` 为 90 帧/15 fps/6 秒的固定小步 AI 演示，其他生态暂停；`wildlifemotion` 也使用固定阶段驱动，并非人工战斗录像。保留最终截图和编码演示，源帧留在 `.test-runs/`。

## 历史入口

旧 `featuretest`、`polishtest`、`probe`、`bodytest`、`bagtest`、`refinetest`、`skilltest`、`bosstest`、`hosttest`、`poitest`、`test_hunger.tscn` 及 bench 含退役 ID 或经验/再生/元素矩阵/休眠预期，仅用于定位历史。不得用其退出成功证明当前规则通过。

`shotrefine` 使用当前 `GU_ORDER`，与旧 `refinetest` 不同；`shotbag` 使用正式物品，`shotreaction` 显示具体蛊效说明。文档静态检查为 `python -X utf8 tools/check_docs.py`，要求 errors=0，但不替代语义、游戏或视觉验收。
