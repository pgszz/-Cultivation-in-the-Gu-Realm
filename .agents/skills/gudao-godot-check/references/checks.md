# 当前检查与历史入口

更新：2026-11-18。当前以 `godot/CANON.md` 的规则为准。

| 入口 | 用途 | 判读 |
| --- | --- | --- |
| `canontest` | 当前正式规则、GUI 输入、碰撞路线、存档 | checked 非零，failures=[]，无脚本错误 |
| `perftest` | 五次窗口采样 | 记录原始 FPS、draws、设备；不是长时压力结论 |
| `--screenshots aperture bag journal map worldmap` | 空窍、背包、身体、地图 | 打开文件看布局，截图成功不能代替交互断言 |
| `--screenshots village interior occlusion waterfall cave` | 环境、屋内、遮挡、瀑布、密洞 | 图面应与真实碰撞/交互一致 |
| `--screenshots comp gujade guliquor refine` | 三种正式插画、图鉴与炼化 | 检查透明边缘、图文尺寸和食性说明 |
| `--screenshots commissions camp notes` | 委托、营地、游历记录 | 检查滚动、按钮与实际数据；防重复领取另由断言验证 |
| `python -X utf8 tools/check_docs.py` | 活动 Markdown 静态检查 | errors=0；不能代替游戏回归或语义审阅 |

通过根目录 `tools/check_game.py` 运行，每项使用独立工程与用户数据命名空间。参数定义以脚本的 CHECKS / SHOTS 为准。

旧 `featuretest`、`polishtest`、`probe`、`bodytest`、`bagtest`、`refinetest`、`skilltest`、`bosstest`、`hosttest`、`poitest`、`test_hunger.tscn` 及 bench 仍有旧蛊 ID、再生/经验/元素反应/休眠预期。它们保留作历史定位，不作为当前验收。修复这些入口前不得把运行成功或历史通过数当成原著版本通过。

当前截图同样必须检查夹具是否使用正式数据；`shotbag` 已改成花瓣、酒、玉石、木料和普通猎获。`shotreaction` 现在展示蛊术说明，不再伪造元素反应通知。

`shotrefine` 已使用月光蛊、酒虫和玉皮蛊；它与仍含退役预期的 `refinetest` 是不同入口。最新截图索引见 [screenshots/README](../../../../godot/screenshots/README.md)。
