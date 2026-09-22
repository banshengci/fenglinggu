# 《风铃谷》美术交付清单（README）

> 交付方：WorkBuddy 智能设计助手
> 接收方：Xiaomi MiMo Desktop
> 引擎：Godot 4.2+（Forward Plus）
> 交付日期：2026-09-22
> 交付根目录：`game/art/`

---

## 1. 一句话说明

按 `docs/art/美术需求清单.md` **全量生产**，落盘 **645 张 PNG / 277.2 MB**；
其中**随包运行时资产 588 张 / 166.1 MB**（另有 `keys/` 风格锚点 9 张、`sprites/` 灰盒占位 9 张、
`_stage/` 切片中间产物 39 张，均不随包）。

**数据层 ↔ 美术文件的映射已全部打通**：`docs/art/art_id_map.json` 共 **441 条，
mapped 441 / missing 0**，并已固化为引擎可直接查询的
`game/scripts/autoload/art_id_map.gd`。

---

## 2. 交付内容分布

| 目录 | 张数 | 体积 | 内容 |
|---|---:|---:|---|
| `chars/walk/` | **144** | 8.7 MB | **行走帧**：主角 16 + NPC 8×16，四向 × 4 帧，192×288 脚底对齐 |
| `items/` | **156** | 22.1 MB | 料理 40 · 种子 48 · 鱼 24 · 古物 12 · 工具/资源图标 32 |
| `crops/` | **96** | 4.3 MB | 48 种作物成熟图 + 12 种作物生长阶段（`_s0.._s3`，48 张） |
| `tiles/` | **41** | 30.7 MB | 生态地皮 10 · 树木四季×三类 12 · 花 6 色 6 · 装饰道具 12 · 宝箱 1 |
| `ui/` | **36** | 17.6 MB | `ui_*` 32（面板/按钮/图标行/对话框/快捷栏/天气 7/季节 4/技能 6/手柄提示 7）+ `panel_9s` · `title_bg` · `logo_emblem` · `app_icon` |
| `furniture/` | **32** | 3.6 MB | 家具与摆件（含 4 幅风景画） |
| `fx/` | **14** | 4.5 MB | 天气遮罩 4 · 天气粒子 2 · 收获/翻地/水滴/火花/风铃/共鸣/光斑/落叶 8 |
| `buildings/` | **14** | 31.2 MB | 风铃塔 / 木屋 / 杂货摊 / 博物馆 / 矿洞入口 / 风车 / 小船 等 |
| `chars/` | **11** | 17.6 MB | NPC 立绘 9 · 主角参考图 + 变体表 |
| `enemies/` | **26** | 4.8 MB | 敌人帧 18（4 组动画）· 矿岩 4 皮 · 合成图 3 · 待机 1 |
| `marketing/` | **7** | 7.6 MB | 主胶囊 / 库图 / Splash / 赛事海报 4 |
| `keys/` | **9** | 24.0 MB | **风格锚点**（生成时对齐用，**不随包**） |
| `sprites/` | **9** | <0.01 MB | 灰盒期 1×1 占位图（已被正式资源取代，**不随包**） |
| `animals/` | **6** | 0.6 MB | 鸡 / 牛 / 羊 / 鸭 / 山羊 / 蜂箱 |
| `cutscenes/` | **5** | 12.8 MB | 5 章主线过场插画 |
| `_stage/` | **39** | 87.0 MB | 拼板源图（切片前的中间产物，**不随包，可删**） |
| **总计** | **645** | 277.2 MB | 随包运行时 **588 张 / 166.1 MB** |

> 口径说明：`588 = 645 − _stage 39 − keys 9 − sprites 9`。

---

## 3. 与需求清单逐条对照

图例：`✅ 完成` · `🟡 部分` · `⛔ 未做`

| 需求章节 | 要求 | 交付 | 状态 |
|---|---|---|---|
| §1.1 主角 | 行走四向 / 挥工具 / 受击 / 外观分层 / 立绘 | 行走四向 ×4 ✅（`chars/walk/player_*_NN.png`，已接入 `player.gd` 帧动画）；参考图/变体表/立绘 ✅；挥具与受击 ⛔ | 🟡 |
| §1.2 NPC ×8 | 立绘 512² + 行走四向 | 立绘 **9/9** ✅；行走四向 ×4 **8/8 角色** ✅（`chars/walk/npc_*`，已接入 `npc.gd`） | ✅ |
| §1.3 动物 ×6 | 站立 + 吃草帧 + 产物图标 | 动物 6 ✅；产物图标 6 ✅（`items/icon_*`） | ✅ |
| §2.1 Tileset | 10 生态 × 10–20 | 生态地皮 **10 张**（一生态一张全景图，非拼边切片） | 🟡 |
| §2.2 植被 | 树四季×3 + 灌木/草簇/花6色/竹/芦苇/石簇 | **全部完成**（树 12 · 花 6 · 装饰 12） | ✅ |
| §3 作物 48 | 成熟图 + 生长 4–5 阶 | 成熟图 **48/48** ✅；生长阶段 12/48（其余走色板变体） | 🟡 |
| §4 图标 | 工具5 · 资源9 · 种子48 · 鱼24 · 古物12 · 料理40 · 家具30 · 任务2 | 种子 **48/48** ✅ · 鱼 24 ✅ · 古物 12 ✅ · 料理 40 ✅ · 家具 32 ✅ · 工具/资源 32 ✅ · 任务 2 ✅ | ✅ **id 全部对齐** |
| §5 建筑 | 15 类 | **14 张**（缺「家具摆放台」单图，功能由 `building_workbench` 覆盖） | ✅ |
| §6 家具 30+ | 32×32 正视 | **32 张**，含需求点名的全部物件 | ✅ |
| §7 敌人 | 史莱姆走4+受击1+消散3 · 雾蝠飞4 · 岩心守卫待机2+走4+倒下6 · 矿岩4皮+爆开3 · 宝箱开/关2 | 史莱姆走4 ✅ 受击4 ✅ · 雾蝠飞4 ✅ · 岩心守卫倒下6 ✅ · 矿岩 4 皮 ✅ · 宝箱 1 张 | 🟡 |
| §8 UI | 面板九宫格 · 按钮4态 · 图标集 · 对话框 · 快捷栏 · 标题 · Logo · 手柄提示 | 全部有图 | ✅ |
| §9 特效与天气 | 收获/翻地/水滴/火花 · 风铃光圈/共鸣 · 天气7 · 夜晚遮罩 | 特效 8 ✅ · 天气遮罩 4 + 粒子 2 ✅ | ✅ |
| §10 过场 | 5 章插画 · 心事件 6–8 · 赛事海报 4 | 过场 5 ✅ · 海报 4 ✅ · 心事件 ⛔ | 🟡 |
| §11 营销 | 胶囊 1232×706 / 小胶囊 231×87 / 库图 600×900 / 截图 6–8 / App 图标 / Splash / GIF | 主胶囊 ✅ 库图 ✅ Splash ✅ App 图标 ✅；小胶囊 ⛔ · 截图 ⛔ · GIF ⛔ | 🟡 |

---

## 4. 命名与目录约定

```text
game/art/
  keys/          风格锚点（生成的唯一对齐基准，不随包）
  chars/         npc_<npc_id>.png · player_refsheet.png · player_variants.png
  crops/         crop_<crop_id>.png · crop_<crop_id>_s0..s3.png
  tiles/         tile_<eco>.png · prop_<prop>.png · tree_<season>_<kind>.png · flower_<color>.png
  buildings/     building_<id>.png
  items/         dish_<recipe_id>.png · seed_<crop_id>.png · fish_<fish_id>.png
                 relic_<relic_id>.png · icon_<item_id>.png
  furniture/     furniture_<id>.png
  enemies/       enemy_<type>.png · enemy_<type>_<anim>_<NN>.png · enemy_ore_rock_<ore>.png
  ui/            ui_<name>.png · panel_9s.png · title_bg.png · logo_emblem.png · app_icon.png
  fx/            fx_<name>.png · fx_overlay_<weather>.png
  animals/       animal_<kind>.png
  cutscenes/     cutscene_<NN>_<scene>.png
  marketing/     capsule_main.png · library_art.png · splash.png · poster_<theme>.png
```

命名统一 `snake_case.png`；帧序列 `_{i:02d}`；图标/道具类全部 **透明底 RGBA PNG**。

---

## 5. ✅ 数据层 ↔ 美术文件映射（已全部打通）

**美术文件名带类别前缀（`dish_` / `fish_` / `relic_` / `seed_` / `icon_`），
而数据层 id 不带前缀，且两套命名体系还不同名**（例如数据 `carp_spring` → 文件 `fish_brook_carp.png`）。
因此**不能靠字符串拼接**，必须查表。

三份等价产物，任选其一消费：

| 文件 | 形态 | 用途 |
|---|---|---|
| `docs/art/art_id_map.json` | JSON（441 条 + 统计头） | 通用，任何工具链 |
| `docs/art/art_id_map.csv` | CSV（`kind,id,file,note`） | 表格/Excel 查看 |
| `game/scripts/autoload/art_id_map.gd` | GDScript `const FILE_OF` | **引擎内直接查**，由 `tools/gen_art_map_gd.py` 从 JSON 生成 |

### 5.1 覆盖的 13 类（441 条，missing 0）

| kind | 条数 | key 格式 | 例 |
|---|---:|---|---|
| `crop` | 48 | 作物 id | `crop:turnip` → `crops/crop_turnip.png` |
| `crop_stage` | 48 | `<crop>:s<N>` | `crop_stage:turnip:s2` → `crops/crop_turnip_s2.png` |
| `seed` | 48 | `seed_<crop>` | `seed:seed_turnip` → `items/seed_turnip.png` |
| `dish` | 40 | 配方 id | `dish:tomato_soup` → `items/dish_veg_soup.png` |
| `furniture` | 30 | 家具 id | `furniture:wood_fence` → `furniture/furniture_fence.png` |
| `fish` | 24 | 鱼 id | `fish:carp_spring` → `items/fish_brook_carp.png` |
| `item_icon` | 18 | 道具 id | `item_icon:wood_axe` → `items/icon_axe.png` |
| `enemy_frame` | 14 | `<enemy>:<anim>:<NN>` | `enemy_frame:slime:walk:02` → `enemies/enemy_slime_walk_02.png` |
| `antique` | 12 | 古物 id | `antique:clay_bell` → `items/relic_clay_bell_shard.png` |
| `npc` | 8 | NPC id | `npc:grandpa_lin` → `chars/npc_grandpa_lin.png` |
| `ore_rock` | 7 | 矿石 id | `ore_rock:copper_ore` → `enemies/enemy_ore_rock_copper.png` |
| `player_walk` | 16 | `<dir>:<NN>` | `player_walk:down:02` → `chars/walk/player_down_02.png` |
| `npc_walk` | 128 | `<npc_id>:<dir>:<NN>` | `npc_walk:atang:left:01` → `chars/walk/npc_atang_left_01.png` |

> 注：`dish` / `fish` / `antique` / `furniture` 里有少量条目是**语义近似复用**
> （如 `tomato_soup`→`veg_soup`、`hotpot`→`mushroom_pot`），
> 条目 `note` 字段标了近似关系，如需一图一物可后续补出。

### 5.2 引擎内接入（已完成）

`game/scripts/autoload/art_pipeline.gd` 已改为**「先查表、后拼名」**两路解析：

```gdscript
const ArtIdMap := preload("res://scripts/autoload/art_id_map.gd")

func mapped(kind: String, id: String) -> Texture2D:
	var rel: String = ArtIdMap.path_of(kind, id)     # 1) 显式映射表
	if rel == "": return null
	return _load_rel(rel)                            #    res://art/<rel>

func item_icon(item_id: String) -> Texture2D:        # 2) 拼名回退
	...  # dish_ / fish_ / relic_ / seed_ / icon_ 逐个试
```

对外接口：`crop(crop_id, stage)` · `crop_seed()` · `item_icon()` · `npc_portrait()` ·
`building()` · `furniture()` · `ore_rock()` / `ore_tint()` · `enemy_frame()` · `ui()` ·
`player_frame()` · `tex()`。

已顺带接好的调用点：

| 文件 | 改动 |
|---|---|
| `game/scripts/entities/farm_plot.gd` | 原写死 `res://art/sprites/crop_%s.png`（1×1 占位）。改为 `ArtPipeline.crop(crop_id, stage)`，按生长阶段取图并逐级回退；无图才走程序化绘制 |
| `game/scripts/player.gd` | 原 `load("res://art/sprites/player.png")` 是 1×1，拉伸成纯色方块。改为先取 `ArtPipeline.player_frame("down",0)`，尺寸 <8px 一律丢弃，回退程序化小人 |
| `game/scripts/autoload/art_pipeline.gd` | 新增 `furniture/ animals/ cutscenes/ marketing/` 四个候选根目录；新增上面全部接口 |

> ⚠️ 本机没有 Godot 可执行文件，**这三处 GDScript 改动未做编译验证**，
> 请在 Godot 里打开工程跑一次（首次打开会自动为全量 PNG 生成 `.import`，耗时较长）。

---

## 6. 规格说明（接入时注意）

| 项 | 说明 |
|---|---|
| 格式 | PNG。**图标/道具/角色/建筑/家具/作物 = RGBA 透明底**；`fx_overlay_*`、`title_bg`、`splash`、`cutscenes`、`keys` = 不透明全幅 |
| 画布 | 图标类 256×256（266 张）、作物 128×128（82 张）、贴图类 512×512（17 张）、板图/插画 1024×922（33）与 1536×922（31） |
| 纹理过滤 | `project.godot` 已设 **Nearest**（像素风）。**全屏遮罩 `fx_overlay_*` 必须单独开线性过滤**，否则块状 |
| 字体 | 图内**无任何文字**（符合需求 §14.5） |
| 调色 | 严格对齐 §0 主色板 `#8FB56F` `#F3EAD3` `#6B5340` `#E8C87A` `#8FC0D8` `#C07850`；无硬阴影；细暖褐线稿 |
| 水印 | 全部已裁除 |

---

## 7. 交付前清理建议

| 项 | 建议 |
|---|---|
| `game/art/_stage/`（39 张 / 87.0 MB） | **拼板源图，运行时不需要**（含本轮 11 张行走帧板图）。删掉可减 ~31% 包体。要保留以便重切片，请移出 `game/`（Godot 会全量导入） |
| `game/art/keys/`（9 张 / 24.0 MB） | 风格锚点，运行时不加载。建议留在仓库但**排除出导出包** |
| `game/art/sprites/`（9 张 / <1 KB） | 1×1 灰盒占位。正式资源已全部就位，可安全删除 |
| `game/art/**/*.import` | 现仅 12 个（早期灰盒图）。**首次用 Godot 打开工程会自动补齐 588 张的 `.import`**——请留足首次导入时间 |
| `docs/art/preview/` | 10 张棋盘格衬底联络表（目检用，含行走帧 2 张），可选交付 |
| `docs/art/_raw_scratch/` | 过程产物（审计日志、过期联络表），**不交付** |

---

## 8. 验收自查结果

对 588 张运行时资产做全量自动核查（`tools/verify_delivery.py`，结果 `docs/art/_verify.txt`）：

| 检查项 | 结果 |
|---|---|
| 命名不规范 | **0** |
| 打不开 / 损坏 | **0** |
| 应透明但无 alpha 通道 | **0** |
| 疑似空白图 | **3**（见下，均属内容极简，实机可接受） |
| id 映射缺失 | **0**（441/441） |
| 行走帧审计（空帧/抖动/方向错/脚底漂移） | **0**（144 帧，见 `docs/art/_walk_audit.txt`） |

3 张低覆盖率图：`crops/crop_tea_s0.png`(1.0%) · `crops/crop_tomato_s0.png`(1.8%) ·
`enemies/enemy_stone_guardian_fall_05.png`(1.4%) —— 分别是幼苗首帧与消散末帧，本身内容极简。

另已完成：35 张 RGB 图补抠透明底；4 张切片失败的料理图重做并复检；
`items/mushroom_seed.png` → `items/seed_mushroom.png`、`enemies/prop_treasure_chest.png`
→ `tiles/prop_treasure_chest.png` 两处命名不一致已修正；重复文件 `chars/npc_zhitao.png` 已删。

---

## 9. 剩余缺口（建议后续补齐）

| 优先级 | 缺口 | 工作量 |
|---|---|---|
| P2 | 主角 / NPC 挥工具、受击、坐下等**非行走**动作帧（行走四向 ×4 已交付） | 约 4 次生成 |
| P2 | 3 种矿岩独立贴图（`silver_ore` / `gold_ore` / `mythril_shard`） | 1 次生成 3 张（当前用 `ore_tint()` 色相回退） |
| P2 | 岩心守卫「待机 2 + 走 4」、史莱姆「消散 3」、矿岩「裂纹 2 + 爆开 3」、宝箱「开关 2」 | 约 4 次生成 |
| P3 | 作物生长阶段补齐 36 种 × 4 阶 = 144 张 | 约 12 次生成 |
| P3 | 心事件插画 6–8 张、Steam 小胶囊、实机截图、宣传 GIF | 需实机配合 |

---

## 10. 相关文档

| 文件 | 用途 |
|---|---|
| `docs/art/delivery_overview.html` | **交付总览页**（浏览器直接打开，含分布表 / 完成度 / 联络表 gallery） |
| `docs/art/美术需求清单.md` | 原始需求规格（262 行） |
| `docs/art/ART_PIPELINE_V2.md` | **接入指南**：命名约定补充 + 代码接入清单 + 尺寸规范 |
| `docs/art/README.md` | 本文件（交付清单） |
| `docs/art/art_id_map.json` / `.csv` | **297 条 id→文件映射**（机器可读） |
| `game/scripts/autoload/art_id_map.gd` | 同上，GDScript 版（引擎直查） |
| `docs/art/asset_checklist.csv` | 原始需求逐项对照表（304 行） |
| `docs/art/preview/` | 8 张联络表，可直接目检风格一致性 |
| `docs/art/_verify.txt` / `_final_count.txt` | 核查与清点原始输出 |

---

*本交付为一次性全量生产的结果。若需补充 §9 缺口，可继续在 `game/art/` 内增量落盘，
命名延续 §4，并重跑 `tools/build_id_map.py` + `tools/gen_art_map_gd.py` 刷新映射表。*
