---
name: gudao-godot-check
description: 验证《蛊道修仙：青茅山》的 Godot 导入、原著规则、人体、背包、空窍和界面回归，选择隔离自测并判断日志与行为。用于代码改动后的验证、错误复现或性能检查；不把正常退出当成自动通过。
---

# 蛊道 Godot 回归验证

工程为根目录的 `godot/`，Godot 4.3 / GL Compatibility。先读 `godot/README.md`、`CANON.md` 和目标实现，区分当前主循环与已退役的旧测试。

## 隔离与执行

从项目根目录使用已有 `tools/check_game.py`。它复制源码资源，排除缓存，将每项检查的工程名随机隔离并设置 `config/use_custom_user_dir=false`；仅复制目录不能自动隔离 user://。

```powershell
python -X utf8 tools/check_game.py --checks canontest
python -X utf8 tools/check_game.py --checks canontest --screenshots aperture bag journal map worldmap --resolution 1280x720
```

上述省略引擎路径的命令仅适用于脚本默认路径可用的环境。其他机器传 `--godot` 指定实际 Godot 4.3 可执行文件；先确认版本。每个进程只有一个测试入口。`canontest` 用窗口和 Viewport 真实输入事件；`perftest` 用窗口采样；导入使用无头模式。

正式玩家存档是 `user://canon_save.json`。旧 `save.json` 不自动迁移或覆盖。不要直接在真实玩家目录执行会保存的测试；需要复现存档时只复制到独立测试命名空间。

## 判读与补充

- 报告在 `.test-runs/时间戳/`，包括 stdout/stderr、实际命令、report.json、截图。
- `CANONTEST checked=... failures=[]`、退出码 0 且无 SCRIPT ERROR / Parse Error 才能判通过。阅读断言覆盖，不能只看总数。
- 饥饿死亡用例会故意产生“蛊虫已经饿死”警告；区分预期断言和其他警告。
- 当前断言覆盖数据边界、实际施法、炼化/喂食、地图路线、人体、交互与存档往返。新缺陷只补有意义的行为边界，不为文案写镜像测试。
- UI 改动应打开实际截图观察遮挡、排版、可滚动区域和文字。必要时检查 1280×720、960×540。截图夹具可能预置蛊和伤势，不代表正常开局自带全部内容。
- 窗口截图与程序投递输入不等于桌面人工试玩；如未手动验证，报告时说明。
- 性能记录引擎、设备、渲染器、分辨率、垂直同步和采样时长；短时静止场景不能证明长时战斗性能。

仅修改文档时运行 `python -X utf8 tools/check_docs.py`，不强制启动游戏或将旧 208 项结果改写成新一轮回归。

入口与旧测试边界见 [references/checks.md](references/checks.md)。当前结果同步到 `godot/VALIDATION.md`，不复用旧版本的通过数。
