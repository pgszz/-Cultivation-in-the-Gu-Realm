# 素材来源

记录更新：2026-11-20。[项目首页](../README.md) · [接入指南](../资源获取实操指南.md)。

## 素材总索引

本表归并原资源清单，状态按实际引用区分；完整生成提示词、尺寸和 SHA-256 由各目录的 SOURCE.json 维护。

| 资源 | 实际范围与状态 | 来源或说明 |
| --- | --- | --- |
| 蛊虫 | 120 张正式透明插画及 1 张希望蛊仪式插画，`GuArt` 统一引用 | [蛊图来源](assets/gu/painted/SOURCE.json)、下方各批次记录 |
| 人物与环境 | 主角、通用居民、建筑、植被、家具、基础地面与五域示意图 | [painted_world](assets/painted_world/SOURCE.json)、[美术](ART.md) |
| 通用人员 | 20 套外观（4 套居民加 16 套新职业形象） | [people](assets/people/SOURCE.json) |
| 原著关键人物 | 方源、方正、白凝冰、青书四套独立动作；人员外观合计 24 套 | [canon](assets/people/canon/SOURCE.json)、[人物依据](../青茅山关键人物.md) |
| 商家城与新地面 | 全景、透明商楼、八种地面，共十张原图 | [shang_city](assets/shang_city/SOURCE.json) |
| 普通物品与肉类 | 七种常用物品、七种肉类插图，`ItemArt` 统一引用 | [items](assets/items/painted/SOURCE.json) |
| 动物与妖兽 | 九张插画及运行时网格动作 | [wildlife](assets/wildlife/painted/SOURCE.json) |
| 玩家外观模板 | 代码绘制与导出，用户导入图仅在个人角色目录保存 | [character_templates](assets/character_templates/SOURCE.json)、[导入格式](CHARACTER_ART.md) |
| 程序表现 | 分层山岩/洞网、水帘、梯田、人体、元海、UI、音效；未接外部背景音乐库 | 下方“程序绘制” |
| 历史资源 | Ninja Adventure、旧蛊 SVG、早期整山图保留对照及许可；不作为当前正式蛊图 | 下方独立署名与历史状态 |
| 截图与演示 | 按验证快照保存，非运行资源 | [截图索引](screenshots/README.md) |

新增素材需有正式用途、来源记录、代码引用、干净导入和视觉检查。候选资源、仅生成未引用与仅测试使用分别记录；具体流程见 [接入指南](../资源获取实操指南.md)。

## 希望蛊插画 · 2026-11-19

[hope_gu.png](assets/gu/painted/hope_gu.png)使用内置图像生成工具制作，原样复制为 1254×1254 RGBA 透明插画。依据第一卷第5–6章的微弱白色光点描写，不添加昆虫肢体；柔光形状和笔触为美术表达。原始输出路径、SHA256 与尺寸见 [SOURCE](assets/gu/painted/SOURCE.json)，完整提示词见 [HOPE-PROMPT](assets/gu/painted/HOPE-PROMPT.json)。开窍中的光流、白色光膜和元海由程序绘制，角色外观复用现有角色系统，原著与模拟边界见 [开窍系统](../希望蛊开窍系统.md)。

## Ninja Adventure

作者：Pixel-Boy 与 AAA。作者页面声明素材采用 CC0，可用于游戏；具体来源声明保存在 [LICENSE-SOURCE.txt](assets/ninja_adventure/LICENSE-SOURCE.txt)，完整许可文本在 [LICENSE-CC0.txt](assets/ninja_adventure/LICENSE-CC0.txt)。

- [作者发布页](https://pixel-boy.itch.io/ninja-adventure-asset-pack)
- [GitHub 仓库](https://github.com/pixel-boy/NinjaAdventure)
- 固定提交：`6ac78232d5aedcc85ce5f27d060ea92366f7c24a`
- 路径记录：[SOURCE.json](assets/ninja_adventure/SOURCE.json)

历史版本用于地面、室内、人物、村落建筑和道具。当前主循环的人物、建筑、树石与室内家具已改用下方原创图集；原素材保留于 `assets/ninja_adventure/` 供历史对照，仍保留作者署名与许可。这些并非《蛊真人》官方人物或建筑美术。

## 青茅山山体

`assets/generated/qingmao_mountain.png` 为早期生成山体，现保留作历史对照；主场景可攀爬山体和地下洞网由分层方块几何绘制。创建于 2026-11-18；提示摘要和原始输出路径保存在 [生成记录](assets/generated/SOURCE.json)。该图不适用 Ninja Adventure 的作者署名。

## 程序绘制

水帘和梯田、篝火与旧炉、室内布局、人体示意图、地图交互标记、空窍元海、界面和音效由项目代码绘制或合成。人物姿态变换、疾步残影、局部受击、建筑碎片坠落和扬尘也是项目代码实现。

衣冠工坊的三种衣装、三种发型、体型与四方向动作由 [CharacterAppearance.gd](scripts/CharacterAppearance.gd) 原创程序绘制：先生成几何轮廓与渐变，再由 Godot 光栅化为透明图集。[人物与衣服模板](assets/character_templates) 为同一生成器导出的 PNG，没有使用第三方图片输入；布局、参数与摘要见 [SOURCE.json](assets/character_templates/SOURCE.json)。用户自行导入的 PNG 仅存于本机角色目录，不属于仓库素材。

## 人物、建筑与地图 · 原创生成

六幅正式 1536×1024 PNG 位于 [assets/painted_world](assets/painted_world)：主角动作图集、四类居民动作图集、建筑/废墟图集、山林/家具图集、地面材质图集和五域示意图。由内置 image_gen 制作，PNG 原样复制；居民第二版由同一工具去除背景。文件摘要、原始输出位置、完整提示词和实际 alpha 范围见 [SOURCE.json](assets/painted_world/SOURCE.json)，接入和动画范围见 [ART.md](ART.md)。

图集不使用 Ninja Adventure 的人物或建筑作为输入，不套用第三方素材的 CC0/CC BY 声明。人物服装、房屋形制、地图轮廓为原创游戏美术推导；未宣称原著精确复原或官方插画。五域图只是方位示意，真实可游玩地图仍由程序网格定义。

移动寨民、巡卫、山民、行脚人、商队及强盗使用二十套外观：保留上述四套居民，新增四张人物图集、十六套服装与外貌，位于 [assets/people](assets/people)。新增图集同样由内置 image_gen 原创生成，原样保留 alpha；完整提示词、原始输出与摘要见 [SOURCE.json](assets/people/SOURCE.json)。`NpcAppearance.gd` 统一分配形象，`WorldPerson.gd` 和 `ActorAnimation.gd` 播放六格动作；这些普通人员不宣称为原著具名人物。

## 设定参考

世界设定参考用户提供的《蛊真人》正文入口。逐章转述见 [CANON.md](CANON.md)。游戏未附小说全文，素材许可与原著文本的权利不混同。

## 当前蛊虫插画 · 原创生成

月光蛊、酒虫、玉皮蛊、小光蛊、白豕蛊、黑豕蛊六张透明 PNG 位于 `assets/gu/painted/`，2026-11-18 使用内置 image_gen 工具逐张生成，原始输出直接复制，无像素后期修改。全部为 1254×1254 RGBA。提示设计摘要、原始文件名与 SHA-256 见 [SOURCE.json](assets/gu/painted/SOURCE.json)，本次新增三图的完整提示词见 [EXPANSION-PROMPTS.json](assets/gu/painted/EXPANSION-PROMPTS.json)。由 `GuArt.gd` 统一供界面与场景使用；这些新 PNG 不属于 Game-icons.net 素材，不套用旧 SVG 的 CC BY 署名。

月光为蓝色月牙晶体，酒虫为珍珠白胖蚕。玉皮以皮蛊同系列的扁宽轮廓结合翠绿护体表现设计，属于有参考依据的美术推导，未冒充原文完整外形或官方插画。正文对照与实现边界见 CANON。

小光采用第一卷 62/70 的乳白五角星，白豕采用第一卷 63 的圆润乳白瓢虫与六短足；表面光泽、纹理与视角为原创设计。黑豕采用同系甲虫轮廓与黑色甲壳，为明确标注的美术推导。补核第一卷 79 后，玉皮的扁宽、淡绿、椭圆虫体也有直接正文依据；原图未重新绘制。

### 第二批七种蛊虫

第二批新增铜皮、铁皮、石皮、兽皮、蛮力天牛、黄骆天牛、龙丸蛐蛐七张图片，该批完成时正式蛊图共十三张。全部使用内置 image_gen 独立生成、原样复制；新图尺寸有 1536×1024、1448×1086、1312×1199 和 1254×1254，均带真实 alpha 通道。各图路径/尺寸/摘要见 [SOURCE](assets/gu/painted/SOURCE.json)，完整提示词见 [WAVE2-PROMPTS](assets/gu/painted/WAVE2-PROMPTS.json)。铜/铁/石皮及两种天牛的主要外形参考第一卷 62；兽皮质感、蛐蛐虫体和所有装饰纹理属于美术推导。蛮力天牛首轮生成网络失败，重试后的有效图已纳入记录。

## 常用物品插图 · 原创生成

元石、木料、碎石、绷带、月兰花瓣、青竹酒和玉石七张透明 PNG 位于 `assets/items/painted/`，2026-11-18 使用内置 image_gen 工具逐张生成，原始输出直接复制，无像素后期修改。全部为 1254×1254 RGBA；完整提示词、原始输出位置、文件名与 SHA-256 见 [SOURCE.json](assets/items/painted/SOURCE.json)。

同日续补兔肉、鹿肉、狼肉、熊肉、野猪肉、雉肉和整猪肉七张独立透明 PNG，仍使用内置 image_gen 工具。新增提示词另存 [MEAT-PROMPTS.json](assets/items/painted/MEAT-PROMPTS.json)，原始路径和文件摘要追加到同一 SOURCE.json。肉的切块、颜色和纹理用于游戏美术辨认；整猪肉以多块肉的包裹表示一份口粮，不是实际供养重量的比例图。

`ItemArt.gd` 统一提供背包格子及详情图片、商铺/药堂补给图标和营地包扎图标，整猪肉购买按钮也使用对应图。材质、色泽、绑绳、酒坛和花瓣形态是游戏美术设计，不宣称逐字还原原著外观或官方插画；不属于 Ninja Adventure 或 Game-icons.net 素材。皮毛、角牙等其他猎获物品仍保留文字显示。

## 动物与妖兽插画 · 原创生成

野兔、野鹿、野狼、黑熊、野猪、赤狐、山雉，以及独立的青狼妖、铁背妖熊，共九张透明 PNG 位于 `assets/wildlife/painted/`。2026-11-18 使用内置 image_gen 逐张生成，原始输出直接复制；完整提示词、生成原路径、文件名与 SHA-256 见 [SOURCE.json](assets/wildlife/painted/SOURCE.json)。

`WildlifeArt.gd` 为动物/妖兽图鉴和世界实体提供同一套插画；幼体随成长改变显示体型。普通动物参考自然轮廓，妖兽的异色毛皮、铁背等为用户要求的原创沙盒表达，不是小说官方插画，也不套用 Ninja Adventure 或旧 Game-icons 的署名/许可。

同日新增 `WildlifeAnimation.gd` 和 `wildlife_motion.gdshader`，在运行时使用细分网格、各物种关节权重及代码变形实现呼吸、走跑、攻击、受伤、倒伏与影子。动画复用上述九张原始 PNG，没有另行生成或修改原图，也未引入第三方动画帧或骨骼资源。

## 历史蛊虫配图 · Game-icons.net

Icons made by **Lorc** and **Delapouite**. 来源为 [game-icons/icons](https://github.com/game-icons/icons) 素材库，许可 **[CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)**。下载日期 2026-11-18，原许可声明、原始 SVG、文件与下载包 SHA-256 见 [assets/gu/SOURCE.json](assets/gu/SOURCE.json) 和 [LICENSE-SOURCE.txt](assets/gu/LICENSE-SOURCE.txt)。旧 SVG 保留于 `assets/gu/` 供历史对照，正式 GuArt 已改用上述新 PNG；旧素材仍保留此处署名与许可。

| 使用图 | 参考源 | 改动 |
| --- | --- | --- |
| 月光蛊 | Lorc / concentric-crescents.svg | 简化为单片蓝色月牙，重绘晶体切面、渐变和圆形底章 |
| 酒虫 | Delapouite / caterpillar.svg | 重绘圆润的珍珠白虫节与面部，调整蚕形轮廓和底章 |
| 玉皮蛊 | Lorc / gems.svg | 以翠绿色玉石作为防御意象，保留几何图形，改色及底章 |

这些是适配本游戏的蛊虫图标，不是小说官方插画；玉皮图不宣称已经考证虫体外形。原素材和派生图归属分别保留，不把该库误写为 CC0。

## 二转蛊插画 · 2026-11-18

月芒、白玉、月霓裳由内置 image_gen 各自生成透明 PNG 并原样复制。月芒蓝晶弯月依据第一卷 106，白玉润白鹅卵石依据 99；月霓裳图案依据 104 的护体雾衣和飘带作意象推导，未宣称虫体原文。提示词见 [UPGRADE-PROMPTS](assets/gu/painted/UPGRADE-PROMPTS.json)，原图文件名和 SHA-256 见 [SOURCE](assets/gu/painted/SOURCE.json)。

## 十三种用途蛊插画

本次十三张独立透明 PNG 由内置 image_gen 生成，原图直接复制入工程，保留 alpha。溪流外形为原创美术解释，其余十二种为原创蛊；生成记录与 SHA-256 见 [SOURCE](assets/gu/painted/SOURCE.json)，完整提示词见 [UTILITY-PROMPTS](assets/gu/painted/UTILITY-PROMPTS.json)，用途边界见 [用途扩展](../蛊虫用途扩展.md)。

## 六十蛊新增插画（2026-11-19）

新增 31 张原创蛊虫透明 PNG，全部由内置 image_gen 单独生成，原图原样复制、保留 alpha。完整提示词见 [SIXTY-PROMPTS](assets/gu/painted/SIXTY-PROMPTS.json)，路径/尺寸/SHA-256 见 [SOURCE](assets/gu/painted/SOURCE.json)。这是用户授权的原创美术和玩法，未宣称原著形象；该批完成时正式蛊图累计 60 张。

## 百蛊新增四十张插画 · 2026-11-19

40 张独立透明 PNG 均由内置 image_gen 逐张生成，原始输出直接复制，保留 alpha，未使用网络图或拼图裁切。完整提示词见 [HUNDRED-PROMPTS.json](assets/gu/painted/HUNDRED-PROMPTS.json)，原路径、尺寸与 SHA-256 见 [SOURCE.json](assets/gu/painted/SOURCE.json)。赤铁舍利首轮网络失败后单独重试，成功图原样保存。

青铜舍利的圆球外形有正文依据，系列色泽参照名称；纹理、飘丝和装饰为原创美术。35 种原创蛊全部明确标注，包括四种四/五转资质蛊。该批完成时正式蛊图累计 100 张，加希望蛊仪式插画共 101 张；未宣称全书所有蛊虫已还原。

## 青茅山关键人物 · 2026-11-19

方源、方正、白凝冰、青书的六格动作图集由内置 image_gen 生成，原始 PNG 直接复制至 [people/canon/qing_mao.png](assets/people/canon/qing_mao.png)，没有离线像素编辑。完整提示词、生成文件名与 SHA-256 见 [SOURCE.json](assets/people/canon/SOURCE.json)。小说人物及世界设定来源于《蛊真人》，本图为项目的美术解释，不是官方角色插画。外貌依据来自正文，服饰细节与姿态是补充，具体章节见 [关键人物说明](../青茅山关键人物.md)。

## 商家城插画与地面 · 2026-11-19

全景、透明商楼及八张地面（青石铺路、黄土巷道、浅色石坪、苔痕庭院、草甸、竹林落叶、湿苔、溪岸碎石），共十张原图由内置 image_gen 分别生成并原样复制。商楼保留真实 alpha。完整提示词、默认输出路径及文件记录见 [SOURCE.json](assets/shang_city/SOURCE.json)。建筑分块坍塌由现有 CollapseAnimation 对原图实时绘制；原图没有裁成独立图片或被手工涂改。原创布局与美术不宣称小说官方场景。

## 肉身二十蛊插画 · 2026-11-19

20张独立透明PNG用内置 image_gen 生成并原样复制，共有120张正式蛊图和1张希望蛊图。骨形和自力更生蟑螂形有正文依据；装饰、笔触及生机叶的视觉细节为美术解释，另16种为原创。完整提示词见 [BODY-PROMPTS](assets/gu/painted/BODY-PROMPTS.json)，每图原始位置、尺寸和SHA-256见 [SOURCE](assets/gu/painted/SOURCE.json)，[联系表](screenshots/bodygu_contact.png)仅作查看，不是游戏素材裁切来源。
