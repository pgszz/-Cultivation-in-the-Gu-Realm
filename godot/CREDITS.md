# 素材来源

记录日期：2026-11-18。[项目首页](../README.md) · [资源清单](../免费资源清单.md) · [接入指南](../资源获取实操指南.md)。

## Ninja Adventure

作者：Pixel-Boy 与 AAA。作者页面声明素材采用 CC0，可用于游戏；具体来源声明保存在 [LICENSE-SOURCE.txt](assets/ninja_adventure/LICENSE-SOURCE.txt)，完整许可文本在 [LICENSE-CC0.txt](assets/ninja_adventure/LICENSE-CC0.txt)。

- [作者发布页](https://pixel-boy.itch.io/ninja-adventure-asset-pack)
- [GitHub 仓库](https://github.com/pixel-boy/NinjaAdventure)
- 固定提交：`6ac78232d5aedcc85ce5f27d060ea92366f7c24a`
- 路径记录：[SOURCE.json](assets/ninja_adventure/SOURCE.json)

实际使用：地面/室内地面、村落建筑与树木、墙面图集、绿/蓝人物、罐子和木箱。原素材位于 `assets/ninja_adventure/`；使用图集裁切、缩放和部分色调调整。这些并非《蛊真人》官方人物或建筑美术。

## 青茅山山体

`assets/generated/qingmao_mountain.png` 为本次用图像生成工具制作并接入的透明背景山体。创建于 2026-11-18；提示摘要和原始输出路径保存在 [生成记录](assets/generated/SOURCE.json)。该图不适用 Ninja Adventure 的作者署名，也未冒称其素材。

## 程序绘制

竹节与竹枝、水帘和梯田、室内布局、人体示意图、五域方位卡片、空窍元海、界面和音效由项目代码绘制或合成。图像只表达本轮玩法，不是完整地理/建筑考据。

## 设定参考

世界设定参考用户提供的《蛊真人》正文入口。逐章转述见 [CANON.md](CANON.md)。游戏未附小说全文，素材许可与原著文本的权利不混同。

## 当前蛊虫插画 · 原创生成

月光蛊、酒虫、玉皮蛊三张透明 PNG 位于 `assets/gu/painted/`，2026-11-18 使用 image_gen 工具生成，原始输出直接复制，无像素后期修改。提示设计摘要、原路径与 SHA-256 见 [SOURCE.json](assets/gu/painted/SOURCE.json)。由 `GuArt.gd` 统一供界面与场景使用；这些新 PNG 不属于 Game-icons.net 素材，不套用旧 SVG 的 CC BY 署名。

月光为蓝色月牙晶体，酒虫为珍珠白胖蚕。玉皮以皮蛊同系列的扁宽轮廓结合翠绿护体表现设计，属于有参考依据的美术推导，未冒充原文完整外形或官方插画。正文对照与实现边界见 CANON。

## 历史蛊虫配图 · Game-icons.net

Icons made by **Lorc** and **Delapouite**. 来源为 [game-icons/icons](https://github.com/game-icons/icons) 素材库，许可 **[CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)**。下载日期 2026-11-18，原许可声明、原始 SVG、文件与下载包 SHA-256 见 [assets/gu/SOURCE.json](assets/gu/SOURCE.json) 和 [LICENSE-SOURCE.txt](assets/gu/LICENSE-SOURCE.txt)。旧 SVG 保留于 `assets/gu/` 供历史对照，正式 GuArt 已改用上述新 PNG；旧素材仍保留此处署名与许可。

| 使用图 | 参考源 | 改动 |
| --- | --- | --- |
| 月光蛊 | Lorc / concentric-crescents.svg | 简化为单片蓝色月牙，重绘晶体切面、渐变和圆形底章 |
| 酒虫 | Delapouite / caterpillar.svg | 重绘圆润的珍珠白虫节与面部，调整蚕形轮廓和底章 |
| 玉皮蛊 | Lorc / gems.svg | 以翠绿色玉石作为防御意象，保留几何图形，改色及底章 |

这些是适配本游戏的蛊虫图标，不是小说官方插画；玉皮图不宣称已经考证虫体外形。原素材和派生图归属分别保留，不把该库误写为 CC0。
