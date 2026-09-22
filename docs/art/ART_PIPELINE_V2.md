# 《风铃谷》美术资源管线补充（v2：贴图接入与动画）

> 类别：**必需**（B）——让已交付的 3.x/4.x 美术资源真正在游戏里显示。
> 前置：`ART_PIPELINE.md`（v1，命名与目录约定）；资源根 `game/art/`。

---

## 1. 命名约定补充（v2）

保留 v1 全部约定。新增/明确以下三类：

### 1.1 带前缀的图标（避免与物品 id 冲突）

| 资源类别 | 命名模板 | 示例 | 数量 |
|---|---|---|---|
| 食物 / 料理 | `game/art/items/dish_<recipe_id>.png` | `dish_berry_jam.png` | 42 |
| 鱼 | `game/art/items/fish_<fish_id>.png` | `fish_koi.png` | 24 |
| 古物 | `game/art/items/relic_<relic_id>.png` | `relic_stone_tablet.png` | 12 |
| 种子 | `game/art/items/seed_<crop_id>.png` | `seed_turnip.png` | 48 |
| 工具 / 资源 | `game/art/items/icon_<item_id>.png` | `icon_hoe.png` | 29 |

**回退链（`ArtPipeline.item_icon` 查不到映射时的兜底顺序）**

```
显式映射表 ArtIdMap → dish_<id> → fish_<id> → relic_<id> → seed_<id> → icon_<id> → 程序化色块
```

> 说明：`items.json` 中 220 个物品的 `id` 不含前缀（如 `wood`、`berry_jam`），
> 美术侧交付的是带类别前缀的文件名，因此**必须由管线做映射**，不能直接 `icon_<id>`。
>
> ✅ **本项已完成**：`docs/art/art_id_map.json` 给出 **297 条**精确映射（missing 0），
> 并已固化为 `game/scripts/autoload/art_id_map.gd`（`const FILE_OF`，key 格式 `"<kind>:<id>"`）。
> 上面的前缀回退链**只作为映射表查不到时的兜底**，正常路径一律先查表。

### 1.2 敌人动画帧（帧序列）

| 敌人 | 类别 | 帧文件 | 帧数 |
|---|---|---|---|
| 晶蚀史莱姆 `slime` | 待机/移动 | `game/art/enemies/enemy_slime_walk_00..03.png` | 4 |
| 晶蚀史莱姆 `slime` | 受击 | `game/art/enemies/enemy_slime_hit_00..03.png` | 4 |
| 雾蝠 `bat` | 飞行 | `game/art/enemies/enemy_mist_bat_fly_00..03.png` | 4 |
| 岩心守卫 `slime_king` | 倒下 | `game/art/enemies/enemy_stone_guardian_fall_00..05.png` | 6 |

`slime_king` 是唯一的 boss，`fall_*` 用作倒地/击败序列。

### 1.3 矿岩（按矿石 id）

`game/art/enemies/enemy_ore_rock_<ore_id>.png`

| 矿石 id（来自 `mine.json` 的 `ore_weights`） | 已交付贴图 | 备注 |
|---|---|---|
| `stone` | `enemy_ore_rock_stone.png` | ✅ |
| `copper_ore` | `enemy_ore_rock_copper.png` | ✅ |
| `iron_ore` | `enemy_ore_rock_iron.png` | ✅ |
| `wind_shard` | `enemy_ore_rock_crystal.png` | ✅（风铃碎片 → 晶簇外观） |
| `silver_ore` | — | ⚠️ 缺，回退 `enemy_ore_rock_stone` + 银色调制 |
| `gold_ore` | — | ⚠️ 缺，回退 `enemy_ore_rock_stone` + 金色调制 |
| `mythril_shard` | — | ⚠️ 缺，回退 `enemy_ore_rock_crystal` + 青色调制 |

> `mine.json` 实际产出 7 种矿石；美术交付了 4 种。缺的 3 种用**同形状 + 色相调制**回退，
> 比程序化圆形色块更贴合已交付风格。

### 1.4 季节 / 天气（UI 侧）

| 用途 | 文件 | 数量 |
|---|---|---|
| 天气图标 | `game/art/ui/ui_weather_{sunny,breeze,cloudy,fog,rain,snow,storm}.png` | 7 |
| 天气全屏遮罩 | `game/art/fx/fx_overlay_{cloudy,fog,night,storm}.png` | 4 |
| 天气粒子图元 | `game/art/fx/fx_{rain,snow}.png` | 2 |
| 季节图标 | `game/art/ui/ui_season_{spring,summer,autumn,winter}.png` | 4 |

> 纹理过滤已设置为 **Nearest**（`project.godot` → `textures/canvas_textures/default_texture_filter=0`），
> 全屏遮罩需在代码里单独开启线性过滤，否则会出现块状马赛克。

### 1.5 树木（四季 × 三类 × 4 季）

`game/art/tiles/tree_<season>_<kind>.png`，`season ∈ {spring,summer,autumn,winter}`，
`kind ∈ {broadleaf,conifer,fruit}`，共 12 张。

### 1.6 角色行走帧（四向 × 4 帧）

落盘目录 **`game/art/chars/walk/`**，与立绘目录 `game/art/chars/` 分开，避免与 `npc_<id>.png` 立绘重名。

```
game/art/chars/walk/player_<dir>_<NN>.png          # dir ∈ down/left/right/up, NN ∈ 00..03
game/art/chars/walk/npc_<npc_id>_<dir>_<NN>.png
```

| 角色 | 文件数 | 来源 |
|---|---|---|
| 主角 `player` | 16 | `player_walk_sheet.png`（4 行 × 4 列板图） |
| 8 位 NPC | 8 × 16 = 128 | 各自一张 4×4 板图 |
| **合计** | **144** | 192×288 RGBA，透明底 |

**板图规范（出图时必须写进 prompt，否则模型会给出不可切的整幅插画）**

- `exactly 4 columns and 4 rows, 16 equal cells`
- `exactly the same height, same size, same scale in all 16 cells`
- `No props or accessories that change silhouette`
- `No borders, no grid lines, no captions, no text`

行顺序固定 **down → left → right → up**，列顺序即动画帧序（00 为静止帧）。

**切片三要素（`tools/slice_walk.py`，缺一不可）**

1. **全板统一 scale** —— 若每帧各自 fit 画布，播放时会「呼吸抖动」。取各帧主体宽高的 90 分位作为基准，
   且必须按**加 margin 后**的尺寸算 scale（否则最大帧会撑破画布）。
2. **脚底对齐** —— 按角色主体 bbox 底边落地，不是按含 margin 的裁切框底边。
   后者会让各帧脚底上下漂移（实测 7~10px）。
3. **主体连通域合并** —— 只取「最大连通域」会被背景近似色（浅色衣物贴 `#F3EAD3` 纸底）把头身切断；
   整格前景又会把相邻行溢入的残片一起裁进来。折中方案：合并所有面积 ≥ 最大域 **15%** 的域。

审计脚本 `tools/audit_walk.py` 四条判定：空帧（覆盖率 <8%）、同向 4 帧高度极差 >18%（抖动）、
四向平均高度极差 >25%（某行画错）、脚底极差 >6px（锚点漂移）。**当前 144 帧 0 问题**。

### 1.7 无美术映射项（保持程序化绘制）

`mythril_shard`（仅作为采集点，无独立物品）、`field_marker`、`tiny_bell` 等
若在 `items.json` 中存在但无对应美术文件，管线返回 `null` 由调用方走程序化绘制，**属于预期行为**。

---

## 2. 代码接入清单（按文件）

| 文件 | 函数 | 现状 | 目标 | 状态 |
|---|---|---|---|---|
| `game/scripts/autoload/art_id_map.gd` | `FILE_OF` / `path_of()` | — | 297 条显式映射（由 `tools/gen_art_map_gd.py` 生成） | ✅ **已生成** |
| `game/scripts/autoload/art_pipeline.gd` | `mapped()` | — | 先查 `ArtIdMap`，命中直接返回 | ✅ **已实现** |
| `game/scripts/autoload/art_pipeline.gd` | `item_icon` | `tex("icon_" + id)` | 先查表，再按 §1.1 回退链 | ✅ **已实现** |
| `game/scripts/autoload/art_pipeline.gd` | `_try_load` | 固定 10 个根目录 | 追加 `furniture/`、`animals/`、`cutscenes/`、`marketing/` | ✅ **已实现（14 个根目录）** |
| `game/scripts/autoload/art_pipeline.gd` | `crop(id, stage)` | `tex("crop_%s")` | 按阶段取图并逐级回退 | ✅ **已实现** |
| `game/scripts/autoload/art_pipeline.gd` | 新增 `crop_seed` / `furniture` | — | 查表 + 拼名回退 | ✅ **已实现** |
| `game/scripts/autoload/art_pipeline.gd` | 新增 `ore_rock` / `ore_tint` | — | 按 §1.3 映射 + 缺失色相回退 | ✅ **已实现** |
| `game/scripts/autoload/art_pipeline.gd` | 新增 `enemy_frame` | — | `enemy_frame("<enemy>:<anim>:<NN>")` | ✅ **已实现**（批量取帧见下方片段） |
| `game/scripts/autoload/art_pipeline.gd` | 新增 `tree` | — | `tree_<season>_<kind>` | ⬜ 待接（走 `tex()` 即可，无需改管线） |
| `game/scripts/entities/farm_plot.gd` | `_try_load_tex` | 写死 `res://art/sprites/crop_%s.png`（1×1 占位） | `ArtPipeline.crop(crop_id, stage)` | ✅ **已改造** |
| `game/scripts/player.gd` | `_ready` / `_draw` | `load("res://art/sprites/player.png")`（1×1） | 四向帧动画：按 `facing` 选方向 + 移动时按 7fps 推进帧，停下回第 0 帧；缺帧回退程序化小人 | ✅ **已改造** |
| `game/scripts/autoload/art_pipeline.gd` | 新增 `player_walk` / `npc_walk` | — | 查映射表 → 拼名回退；`player_frame()` 保留为旧接口，内部转 `player_walk()` | ✅ **已实现** |
| `game/scripts/entities/npc.gd` | `_draw` | 色块 + 名字 | `ArtPipeline.npc_walk(npc_id,"down",0)`，脚底落在 y=+14；无图回退色块 | ✅ **已改造** |
| `game/scripts/world.gd` | `_draw` | 纯 `draw_rect`/`draw_circle` | 贴 `tile_*` 地表 + `tree_*` + `building_*` + `prop_*` | ⬜ 待接 |
| `game/scripts/overworld_area.gd` | `_draw` | 纯几何 | 按 `area_id` 贴对应 `tile_*` 地表 | ⬜ 待接 |
| `game/scripts/mine_level.gd` | `_draw` | 纯几何 | 贴 `tile_mine_deep.png` + `fx_overlay_*` | ⬜ 待接 |
| `game/scripts/ui/hud.gd` | — | 纯 Label | `ui_hotbar.png` / `ui_coin.png` / `ui_hp_heart.png` / `ui_season_*.png` / `ui_weather_*.png` | ⬜ 待接 |
| `game/scripts/ui/inventory_panel.gd` | 格子绘制 | 色块 | `ArtPipeline.item_icon(item_id)` + `panel_9s.png` 九宫格 | ⬜ 待接 |
| `game/scripts/ui/craft_panel.gd` | 配方图标 | 色块 | `ArtPipeline.item_icon(recipe_id)` | ⬜ 待接 |
| `game/scripts/ui/title_screen.gd` | — | 纯文字 | `title_bg.png` + `logo_emblem.png` | ⬜ 待接 |
| `game/scripts/ui/shop_panel.gd` | 商品图标 | 色块 | `ArtPipeline.item_icon` | ⬜ 待接 |
| `game/scripts/entities/resource_node.gd` | `_draw` | `draw_circle` | 木/石/纤维/风铃碎片 → `tree_*` / `prop_rock_pile` / `prop_grass_tuft` / `icon_windchime_shard` | ⬜ 待接 |
| `game/scripts/entities/mine_enemy.gd` | `_draw` | `draw_circle` | `ArtPipeline.enemy_frame(type_id, anim, i)` | ⬜ 待接 |
| `game/scripts/entities/mine_rock.gd` | `_draw` | `draw_circle` | `ArtPipeline.ore_rock(ore_id)` + `ore_tint(ore_id)` | ⬜ 待接 |
| `game/scripts/entities/animal_pen.gd` | `_draw` | 色块 | `animals/animal_<kind>.png` | ⬜ 待接 |
| `game/scripts/entities/furniture_spot.gd` | `_draw` | 色块 | `ArtPipeline.furniture(id)` | ⬜ 待接 |
| `game/scripts/entities/treasure_chest.gd` | `_draw` | 色块 | `tiles/prop_treasure_chest.png`（**已从 `enemies/` 移到 `tiles/`**） | ⬜ 待接 |
| `game/scripts/entities/bed.gd` / `workbench.gd` / `commission_board.gd` / `shipping_bin.gd` / `museum_building.gd` / `wind_bell_tower.gd` / `seed_shop.gd` | `_draw` | 色块 | `buildings/building_<id>.png` | ⬜ 待接 |

### 关键实现片段

**查表优先（已落地，见 `art_pipeline.gd`）**

```gdscript
const ArtIdMap := preload("res://scripts/autoload/art_id_map.gd")

func mapped(kind: String, id: String) -> Texture2D:
	var rel: String = ArtIdMap.path_of(kind, id)   # "crop:turnip" -> "crops/crop_turnip.png"
	if rel == "":
		return null
	return _load_rel(rel)                          # 前缀 res://art/
```

### 关键实现片段

**物品图标回退链**

```gdscript
const ICON_PREFIXES := ["dish_", "fish_", "relic_", "seed_", "icon_"]

func item_icon(item_id: String) -> Texture2D:
    for p in ICON_PREFIXES:
        var t := tex(p + item_id)
        if t:
            return t
    return null
```

**带色相调制的回退（矿岩）**

```gdscript
const ORE_ALIAS := {
    "stone": "stone", "copper_ore": "copper", "iron_ore": "iron",
    "wind_shard": "crystal", "silver_ore": "stone",
    "gold_ore": "stone", "mythril_shard": "crystal",
}
const ORE_TINT := {
    "silver_ore": Color(0.85, 0.88, 0.95),
    "gold_ore": Color(1.0, 0.88, 0.55),
    "mythril_shard": Color(0.6, 0.85, 0.95),
}

func ore_rock(ore_id: String) -> Texture2D:
    return tex("enemy_ore_rock_" + ORE_ALIAS.get(ore_id, "stone"))
```

**全屏天气遮罩（必须单独开线性过滤）**

```gdscript
func overlay(weather: String) -> Texture2D:
    var t := tex("fx_overlay_" + WEATHER_MAP.get(weather, ""))
    if t:
        t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # 覆盖 Nearest，避免块状
    return t
```

**帧动画（已落地为 `enemy_frame()`，下面是批量取帧的调用示例）**

```gdscript
const ENEMY_ANIM := {"slime": ["walk", 4], "bat": ["fly", 4], "slime_king": ["fall", 6]}

func enemy_anim(type_id: String) -> Array[Texture2D]:
	if not ENEMY_ANIM.has(type_id):
		return []
	var s: Array = ENEMY_ANIM[type_id]
	var out: Array[Texture2D] = []
	for i in int(s[1]):
		var t := ArtPipeline.enemy_frame(type_id, s[0], i)
		if t:
			out.append(t)
	return out
```

> 注意 `slime` 前缀是 `enemy_slime`，`bat` 的前缀是 `enemy_mist_bat`，
> `slime_king` 的前缀是 `enemy_stone_guardian`——三者不一致，拼名取不到。
> 好在 `art_id_map` 的 `enemy_frame` 类已用**游戏内 type_id**（`slime` / `bat` / `slime_king`）
> 记录了全部 14 条精确映射，直接 `enemy_frame(type_id, anim, i)` 即可，无需手写前缀表。

---

## 3. 尺寸与锚点规范

| 类别 | 交付画布 | 建议渲染尺寸 | 锚点 |
|---|---|---|---|
| 作物成熟图 | 128×128 | 32×32 | 脚底居中 |
| 作物生长阶段 `_s0..s3` | 128×128 | 24×24 | 脚底居中 |
| 物品图标 | 256×256 | 32×32（背包）/ 64×64（详情） | 居中 |
| 树木 | 256×256 | 64×96 | 根部居中 |
| 建筑 | 512×512 | 96×80 ~ 192×160 | 底边居中 |
| 敌人帧 | 256×256 | 32×32 ~ 56×56 | 底边居中 |
| **角色行走帧** | **192×288** | 16×24（主角）/ 20×30（NPC） | **脚底居中，全板统一 scale** |
| 全屏遮罩 | 1536×1024 | 拉伸铺满 | 左上 |
| 场景锚点图 `keys/` | 1536×1024 | 仅参考，不运行时加载 | — |
| UI 面板 | 1024×1024 | 九宫格切分 | 四角固定 |

---

## 4. 验收自查清单

**资源侧（已全部通过，见 `docs/art/_verify.txt`）**

- [x] **588** 张运行时资产命名规范（0 违规）
- [x] 无损坏文件（0）
- [x] 应透明的资源均带 alpha 通道（0 异常）
- [x] id → 文件映射 **441/441**，missing 0（297 基础 + 144 行走帧）
- [x] 水印已全部裁除
- [x] 行走帧 144 张审计通过（空帧 / 抖动 / 方向错 / 脚底漂移 均为 0）

**引擎侧（需 Godot 打开工程逐项确认）**

- [ ] `art_id_map.gd` / `art_pipeline.gd` / `farm_plot.gd` / `player.gd` / `npc.gd` 五处改动**编译通过**
- [ ] 农田里作物按生长阶段显示贴图（不再是纯色圆）
- [ ] 玩家不再是纯色方块（四向行走有帧动画，停下回静止帧）
- [ ] NPC 显示行走帧立绘（不再是纯色矩形）
- [ ] 每类资源在游戏内**至少有一处**可见（不是躺在目录里）
- [ ] 背包 / 合成 / 商店三处图标**无空白格**（无美术项回退色块，不是透明）
- [ ] 敌人有帧动画，受击有闪烁
- [ ] 矿岩按矿石种类显示不同外观（含 3 种色相回退）
- [ ] 天气切换时**地表色调 + 全屏遮罩 + UI 图标**三者同步
- [ ] 树木按季节切换贴图
- [ ] 窗口拉伸到 1920×1080 时贴图**无模糊、无块状**
- [ ] `ArtPipeline` 的"重新扫描美术资源"按钮可用

> ⚠️ 交付方本机**没有 Godot 可执行文件**，上述 GDScript 改动**未做编译验证**，
> 请在 Godot 里打开工程跑一次。首次打开会为 588 张 PNG 全量生成 `.import`，耗时较长。

---

## 5. 已知缺口（本次不阻塞，建议后续补齐）

| 缺口 | 影响 | 建议 |
|---|---|---|
| 主角 / NPC 挥工具、受击、坐下等**非行走**动作帧 | 目前只有行走四向 ×4 | 补 1~2 次生成（按 §1.6 板图规范） |
| `silver_ore` / `gold_ore` / `mythril_shard` 矿岩贴图 | 三种矿石与石头同形（靠 `ore_tint()` 色相区分） | 补 3 张（1 次生成） |
| 作物生长阶段仅 12 种作物有 `_s0..s3` | 其余 36 种用色块渐变 | 补 36×4 = 144 张（可选） |
| 岩心守卫「待机 2 + 走 4」、史莱姆「消散 3」、矿岩「裂纹 2 + 爆开 3」、宝箱「开/关 2」 | 部分敌人状态无图 | 约 4 次生成 |
| 心事件插画 6–8 张、Steam 小胶囊、实机截图、宣传 GIF | 营销与剧情素材不全 | 需实机配合 |

---

*本文件为 v1 `ART_PIPELINE.md` 的补充，两者配合使用。*
