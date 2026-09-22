#!/usr/bin/env python
"""按计划书目标量生成内容表。"""
from __future__ import annotations

import json
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "game" / "data"
DATA.mkdir(parents=True, exist_ok=True)

SEASONS = ["萌芽春", "长夏", "蜜酿秋", "静雪冬"]


def w(name: str, obj) -> None:
    path = DATA / name
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")
    print("wrote", name, "keys/rows", len(obj) if isinstance(obj, (list, dict)) else "?")


def items_table() -> dict:
    items = json.loads((DATA / "items.json").read_text(encoding="utf-8"))
    # 基础已有保留，补齐大量物品
    extra_tools = []
    seeds_crops = [
        # (crop_id, seed_name, crop_name, days, seasons, sell, regrow, sprout, mature, desc)
        ("turnip", "白萝卜种子", "白萝卜", 3, ["萌芽春"], 35, 0, "#A8C87A", "#F5F0E1", "春日最早能收的根菜。"),
        ("potato", "土豆种子", "土豆", 4, ["萌芽春", "蜜酿秋"], 55, 0, "#8FBC6B", "#C4A060", "产量扎实的主食。"),
        ("tomato", "番茄种子", "番茄", 5, ["长夏"], 75, 3, "#6B9B4A", "#E05555", "可反复采收的夏季明星。"),
        ("berry", "浆果种子", "山莓", 4, ["长夏", "蜜酿秋"], 95, 2, "#5A8A4A", "#E06090", "灌木浆果。"),
        ("cabbage", "卷心菜种子", "卷心菜", 5, ["萌芽春", "静雪冬"], 65, 0, "#7FA36A", "#B8D48A", "扎实的叶菜。"),
        ("carrot", "胡萝卜种子", "胡萝卜", 3, ["萌芽春", "蜜酿秋"], 40, 0, "#A8C87A", "#E09040", "脆甜根菜。"),
        ("onion", "洋葱种子", "洋葱", 4, ["萌芽春"], 48, 0, "#8FBC6B", "#D0A0C0", "会让人笑着流泪。"),
        ("garlic", "蒜头种子", "蒜头", 4, ["萌芽春", "静雪冬"], 52, 0, "#8FBC6B", "#E8E0C8", "厨房常备。"),
        ("radish", "樱桃萝卜种子", "樱桃萝卜", 2, ["萌芽春"], 30, 0, "#A8C87A", "#E06080", "两天就能见着的惊喜。"),
        ("lettuce", "生菜种子", "生菜", 3, ["萌芽春", "长夏"], 38, 1, "#8FBC6B", "#B8D48A", "沙拉主角。"),
        ("spinach", "菠菜种子", "菠菜", 3, ["萌芽春"], 42, 0, "#5A8A4A", "#4A7A3A", "补铁小能手。"),
        ("pea", "豌豆种子", "豌豆", 4, ["萌芽春"], 50, 2, "#8FBC6B", "#A8D070", "豆荚会笑。"),
        ("strawberry", "草莓种子", "草莓", 6, ["长夏"], 120, 2, "#6B9B4A", "#E05070", "香甜多汁。"),
        ("corn", "玉米种子", "玉米", 7, ["长夏", "蜜酿秋"], 110, 0, "#8FBC6B", "#E8C87A", "高高的金棒子。"),
        ("watermelon", "西瓜种子", "西瓜", 8, ["长夏"], 150, 0, "#5A8A4A", "#4A8A5A", "夏天的快乐。"),
        ("melon", "蜜瓜种子", "蜜瓜", 7, ["长夏"], 140, 0, "#8FBC6B", "#D0E080", "清甜。"),
        ("pepper", "辣椒种子", "辣椒", 5, ["长夏", "蜜酿秋"], 85, 3, "#6B9B4A", "#E04040", "热情如火。"),
        ("eggplant", "茄子种子", "茄子", 6, ["长夏"], 95, 2, "#6B9B4A", "#7A5A9A", "紫衣贵族。"),
        ("cucumber", "黄瓜种子", "黄瓜", 4, ["长夏"], 60, 3, "#8FBC6B", "#8FC070", "清爽。"),
        ("pumpkin", "南瓜种子", "南瓜", 8, ["蜜酿秋"], 180, 0, "#8FBC6B", "#E09040", "秋天的灯笼。"),
        ("sweet_potato", "红薯种子", "红薯", 6, ["蜜酿秋"], 100, 0, "#8FBC6B", "#C08060", "烤着吃最香。"),
        ("grape", "葡萄种子", "葡萄", 7, ["蜜酿秋"], 130, 3, "#6B9B4A", "#8A5A9A", "可酿酒（料理）。"),
        ("rice", "稻种", "稻米", 6, ["蜜酿秋"], 90, 0, "#A8C87A", "#E8E0B0", "一粒一粒都是日子。"),
        ("wheat", "麦种", "麦穗", 5, ["蜜酿秋", "静雪冬"], 70, 0, "#A8C87A", "#E8D080", "磨坊的好朋友。"),
        ("mushroom_seed", "菌棒", "蘑菇", 4, ["蜜酿秋", "静雪冬"], 88, 2, "#A09080", "#C0A080", "林间味道。"),
        ("hazelnut", "榛果苗", "榛果", 7, ["蜜酿秋"], 115, 0, "#8FBC6B", "#C0A060", "小松鼠认证。"),
        ("sunflower", "向日葵种子", "向日葵", 6, ["长夏", "蜜酿秋"], 100, 0, "#8FBC6B", "#E8C87A", "永远朝向好天气。"),
        ("lavender", "薰衣草种子", "薰衣草", 5, ["长夏"], 90, 2, "#8FBC6B", "#A080C0", "助眠香气。"),
        ("chrysanthemum", "菊苗", "秋菊", 5, ["蜜酿秋"], 85, 0, "#8FBC6B", "#E0C060", "秋日门牌。"),
        ("plum", "李树苗", "李子", 8, ["蜜酿秋"], 140, 3, "#6B9B4A", "#A05080", "酸甜果子。"),
        ("apple", "苹果苗", "苹果", 10, ["蜜酿秋", "静雪冬"], 160, 4, "#6B9B4A", "#E05050", "果树代表。"),
        ("pear", "梨树苗", "梨", 9, ["蜜酿秋"], 150, 4, "#6B9B4A", "#D0E080", "多汁。"),
        ("tea", "茶苗", "茶叶", 6, ["萌芽春", "长夏"], 105, 3, "#5A8A4A", "#4A7A3A", "山雾里长出来的叶子。"),
        ("herb", "香草种子", "香草", 3, ["萌芽春", "长夏"], 55, 2, "#8FBC6B", "#7FA36A", "料理灵魂。"),
        ("cotton", "棉种", "棉花", 6, ["长夏", "蜜酿秋"], 80, 0, "#8FBC6B", "#F0F0E8", "以后做衣服。"),
        ("flax", "亚麻种", "亚麻", 5, ["萌芽春"], 75, 0, "#A8C87A", "#C0C0A0", "织布用。"),
        ("cocoa_seed", "可可苗", "可可豆", 9, ["长夏"], 170, 0, "#5A8A4A", "#A06040", "远方的味道。"),
        ("vanilla", "香草兰苗", "香草荚", 10, ["长夏"], 190, 2, "#5A8A4A", "#C0A060", "甜点之魂。"),
        ("ginger", "姜种", "姜块", 5, ["蜜酿秋", "静雪冬"], 78, 0, "#8FBC6B", "#D0A060", "暖胃。"),
        ("lotus", "莲藕种", "莲藕", 7, ["长夏"], 125, 0, "#5A8A4A", "#E8D0C0", "湖边亲戚。"),
        ("bamboo_shoot", "竹笋种", "竹笋", 4, ["萌芽春"], 88, 2, "#5A8A4A", "#C0D080", "雨后特别甜。"),
        ("cocoa_bean", "咖啡苗", "咖啡豆", 11, ["长夏"], 200, 3, "#5A8A4A", "#6B5340", "提神。"),
        ("wintermelon", "冬瓜种子", "冬瓜", 8, ["静雪冬"], 130, 0, "#8FBC6B", "#B0C8A0", "耐放。"),
        ("snow_pea", "雪豆种子", "雪豆", 5, ["静雪冬"], 72, 2, "#8FBC6B", "#D0E8D0", "冬天的脆响。"),
        ("holly", "冬青苗", "冬青果", 7, ["静雪冬"], 110, 0, "#4A7A3A", "#E04040", "节日点缀。"),
        ("mandarin", "橘树苗", "金橘", 9, ["静雪冬"], 155, 3, "#6B9B4A", "#E0A040", "冬天的甜。"),
        ("asparagus", "芦笋种子", "芦笋", 5, ["萌芽春"], 92, 3, "#8FBC6B", "#7FA36A", "春天贵客。"),
        ("artichoke", "洋蓟种子", "洋蓟", 7, ["萌芽春", "长夏"], 118, 0, "#8FBC6B", "#A0A890", "造型派。"),
    ]
    for cid, sname, pname, days, seasons, sell, regrow, sprout, mature, desc in seeds_crops:
        sid = f"seed_{cid}" if not cid.startswith("mushroom") else "mushroom_seed"
        if cid == "mushroom_seed":
            sid = "mushroom_seed"
        elif cid == "cocoa_bean":
            sid = "seed_cocoa_bean"
        else:
            sid = f"seed_{cid}"
        items.setdefault(sid, {
            "id": sid,
            "name": sname,
            "type": "seed",
            "crop_id": cid if cid != "mushroom_seed" else "mushroom",
            "buy_price": max(15, sell // 2),
            "color": sprout,
            "desc": desc,
        })
        product = cid if cid != "mushroom_seed" else "mushroom"
        if cid == "mushroom_seed":
            product = "mushroom"
        items.setdefault(product, {
            "id": product,
            "name": pname,
            "type": "crop",
            "sell_price": sell,
            "color": mature,
            "desc": desc,
        })

    # 鱼
    fish_names = [
        ("carp_spring", "溪鲤", 40, "#C8B090", ["萌芽春"]),
        ("crucian", "银鲫", 48, "#D0D0C0", ["萌芽春"]),
        ("loach", "泥鳅", 35, "#A08060", ["萌芽春", "长夏"]),
        ("dace", "雅罗", 52, "#B0C0A0", ["萌芽春"]),
        ("bluegill", "蓝鳃太阳鱼", 55, "#7EB8D0", ["长夏"]),
        ("bass", "河鲈", 70, "#90A8B0", ["长夏"]),
        ("catfish", "鲶鱼", 80, "#6B5340", ["长夏"]),
        ("puffer", "河豚", 95, "#E8D080", ["长夏"]),
        ("mackerel", "鲭鱼", 88, "#80A0C0", ["长夏", "蜜酿秋"]),
        ("salmon", "溯河鲑", 120, "#E09080", ["蜜酿秋"]),
        ("carp_mirror", "镜鲤", 100, "#D0B080", ["蜜酿秋"]),
        ("night_eel", "夜鳗", 90, "#6A5A8A", ["蜜酿秋"]),
        ("eel", "黄鳝", 75, "#A09050", ["蜜酿秋", "长夏"]),
        ("gudgeon", "吻鮈", 42, "#C0B090", ["蜜酿秋"]),
        ("ice_trout", "冰晶鳟", 110, "#B0D8E8", ["静雪冬"]),
        ("whitefish", "白鲑", 98, "#E0E8E8", ["静雪冬"]),
        ("smelt", "胡瓜鱼", 60, "#C0D0B0", ["静雪冬"]),
        ("pike", "狗鱼", 130, "#8A9A70", ["静雪冬"]),
        ("moon_koi", "月光锦鲤", 200, "#E8C87A", []),
        ("ghost_fish", "幽灵鱼", 180, "#C0C8D8", []),
        ("crystal_shrimp", "雾晶虾", 70, "#A8D8E8", []),
        ("stone_loach", "石鳅", 50, "#A0A0A0", []),
        ("pond_turtle", "池龟", 150, "#6B8F5A", []),
        ("legend_fish", "传说之鱼", 500, "#E8A0E8", []),
    ]
    for fid, name, sell, color, seasons in fish_names:
        items.setdefault(fid, {
            "id": fid, "name": name, "type": "fish", "sell_price": sell,
            "color": color, "desc": "钓鱼获得。"
        })

    # 古物
    antiques = [
        ("clay_bell", "陶铃残片", 30, "#D0A070"),
        ("glass_marble", "雾晶弹珠", 45, "#A8D8E8"),
        ("old_letter", "风干的信", 25, "#E8DCC0"),
        ("gear_toy", "齿轮玩具", 55, "#A0A8B0"),
        ("porcelain_shard", "青瓷片", 40, "#A0C0C0"),
        ("bronze_coin", "青铜钱", 35, "#C0A060"),
        ("wooden_comb", "木梳", 28, "#B8956C"),
        ("stone_bead", "石珠", 32, "#9A9A9A"),
        ("glass_bottle", "雾玻璃瓶", 38, "#C0E0E0"),
        ("iron_key", "旧铁钥", 50, "#A0A8B0"),
        ("bone_flake", "骨哨残片", 33, "#E8E0D0"),
        ("pocket_watch", "怀表（停了）", 80, "#E8C87A"),
    ]
    for aid, name, sell, color in antiques:
        items.setdefault(aid, {
            "id": aid, "name": name, "type": "antique", "sell_price": sell,
            "color": color, "desc": "博物馆藏品。"
        })

    # 料理
    foods = [
        ("turnip_cake", "萝卜糕", 90, "#F0E6C8"),
        ("berry_jam", "山莓酱", 220, "#C04060"),
        ("tomato_soup", "番茄汤", 140, "#E07050"),
        ("potato_stew", "土豆炖锅", 160, "#C0A070"),
        ("salad", "田园沙拉", 110, "#B8D48A"),
        ("veggie_skewer", "烤蔬菜串", 130, "#E0A050"),
        ("fish_grill", "烤溪鲤", 100, "#D0B080"),
        ("fish_stew", "渔夫炖鱼", 180, "#C09070"),
        ("berry_pie", "山莓派", 240, "#E090A0"),
        ("apple_pie", "苹果派", 280, "#E0B070"),
        ("corn_bread", "玉米面包", 150, "#E8D080"),
        ("pumpkin_soup", "南瓜浓汤", 210, "#E09040"),
        ("mushroom_risotto", "蘑菇烩饭", 230, "#D0B090"),
        ("honey_toast", "蜜糖吐司", 170, "#E8C87A"),
        ("tea_set", "山雾茶", 190, "#8FBC6B"),
        ("coffee", "咖啡", 250, "#6B5340"),
        ("hot_cocoa", "热可可", 260, "#A06040"),
        ("wine_grape", "葡萄酿", 300, "#8A5A9A"),
        ("sushi", "湖鲜寿司", 270, "#E8E0D0"),
        ("rice_bowl", "盖浇饭", 160, "#F0E8D0"),
        ("noodle", "清汤面", 145, "#E8E0B0"),
        ("dumpling", "时蔬饺", 175, "#F0F0E0"),
        ("hotpot", "丰收火锅", 320, "#E06040"),
        ("cheese", "农舍奶酪", 200, "#F0E0A0"),
        ("butter_toast", "黄油面包", 130, "#E8D0A0"),
        ("jam_toast", "果酱吐司", 155, "#E0A0A0"),
        ("pickles", "腌菜坛", 120, "#A0B060"),
        ("kimchi", "泡菜", 125, "#E06050"),
        ("smoked_eel", "熏鳗", 220, "#A08070"),
        ("honey", "野花蜜", 180, "#E8C060"),
        ("candy", "风铃糖", 140, "#E8A0E8"),
        ("chocolate", "可可甜点", 290, "#6B5340"),
        ("cake", "奶油蛋糕", 310, "#F5F0E1"),
        ("pudding", "焦糖布丁", 230, "#E0C080"),
        ("ice", "雾晶冰沙", 160, "#A8D8E8"),
        ("sun_cake", "向日葵饼", 190, "#E8C87A"),
        ("herb_salt", "香草盐", 150, "#A0C0A0"),
        ("ginger_tea", "姜茶", 155, "#D0A060"),
        ("mixed_juice", "鲜榨果汁", 200, "#E0A0B0"),
        ("legend_feast", "风铃盛宴", 500, "#E8A0E8"),
    ]
    for fid, name, sell, color in foods:
        items.setdefault(fid, {
            "id": fid, "name": name, "type": "cooked", "sell_price": sell,
            "color": color, "desc": "厨房出品。"
        })

    # 家具/装饰
    furniture = [
        ("field_marker", "田界牌", 15, "#C4A574"),
        ("tiny_bell", "微型风铃", 80, "#E8C87A"),
        ("wood_fence", "木栅栏", 12, "#B8956C"),
        ("stone_path", "石板路", 10, "#9A9A9A"),
        ("flower_pot", "花盆", 25, "#C07850"),
        ("lantern", "纸灯笼", 45, "#E8C87A"),
        ("bench", "长椅", 60, "#B8956C"),
        ("sign_post", "木牌", 20, "#C4A574"),
        ("well", "小水井", 120, "#A0A8B0"),
        ("birdhouse", "鸟屋", 70, "#B8956C"),
        ("windmill_toy", "风车玩具", 90, "#E0A050"),
        ("crystal_lamp", "晶石灯", 110, "#A8D8E8"),
        ("rug", "织毯", 85, "#C07080"),
        ("curtain", "布帘", 55, "#E0D0B0"),
        ("bookshelf", "书架", 130, "#B8956C"),
        ("tea_table", "茶几", 95, "#C4A574"),
        ("painting_hills", "画·翠谷", 200, "#8FB56F"),
        ("painting_lake", "画·湖心", 200, "#8FC0D8"),
        ("painting_mine", "画·晶洞", 200, "#6A8AAA"),
        ("bell_mobile", "铃串挂饰", 140, "#E8C87A"),
        ("festival_banner", "祭典幡", 160, "#E05555"),
        ("photo_frame", "相框", 75, "#C4A574"),
        ("trophy_cup", "纪念杯", 100, "#E8C87A"),
        ("music_box", "音乐盒", 180, "#D0A070"),
        ("potted_tree", "盆栽树", 120, "#6B8F5A"),
        ("stone_lantern", "石灯", 100, "#9A9A9A"),
        ("hanging_bells", "檐铃", 95, "#E8C87A"),
        ("picnic_set", "野餐篮", 88, "#C4A574"),
        ("cat_bed", "猫窝", 110, "#E0C0B0"),
        ("telescope", "望远镜", 220, "#A0A8B0"),
    ]
    for fid, name, sell, color in furniture:
        items.setdefault(fid, {
            "id": fid, "name": name, "type": "furniture", "sell_price": sell,
            "color": color, "placeable": True, "desc": "家园装饰。"
        })

    # 矿物扩展
    minerals = [
        ("copper_ore", "铜矿", 18, "#C07840"),
        ("iron_ore", "铁矿", 32, "#A0A8B0"),
        ("silver_ore", "银矿", 55, "#D0D8E0"),
        ("gold_ore", "金矿", 90, "#E8C87A"),
        ("mythril_shard", "星纹晶", 150, "#A0E0E8"),
        ("copper_wire", "铜件", 28, "#D09060"),
    ]
    for mid, name, sell, color in minerals:
        items.setdefault(mid, {
            "id": mid, "name": name, "type": "resource", "sell_price": sell,
            "color": color, "desc": "矿物。"
        })

    items["wind_shard"] = items.get("wind_shard", {
        "id": "wind_shard", "name": "风铃碎片", "type": "quest",
        "sell_price": 0, "color": "#A8D8E8", "desc": "风铃残片。"
    })
    # 工具升级线：木(0)→铜(1)→铁(2)→银晶(3)→星纹(4)
    tool_bases = [
        ("hoe", "锄头", "till", "#8B7355"),
        ("watering_can", "水壶", "water", "#5B8FA8"),
        ("wood_axe", "斧头", "chop", "#A67C52"),
        ("stone_pick", "镐子", "mine", "#7A8B99"),
    ]
    tier_meta = [
        (0, "木", "", 0),
        (1, "铜", "_copper", 40),
        (2, "铁", "_iron", 90),
        (3, "银晶", "_silver", 160),
        (4, "星纹", "_star", 280),
    ]
    for base_id, base_name, action, color in tool_bases:
        for tier, tname, suffix, sell in tier_meta:
            tid = base_id + suffix if suffix else base_id
            items.setdefault(tid, {
                "id": tid,
                "name": f"{tname}{base_name}" if suffix else base_name,
                "type": "tool",
                "tool_action": action,
                "tool_tier": tier,
                "tool_base": base_id,
                "sell_price": sell,
                "color": color,
                "desc": f"{tname}阶{base_name}，效率 {tier + 1}。",
            })
        # 确保基础工具带 tier 字段
        items[base_id]["tool_tier"] = 0
        items[base_id]["tool_base"] = base_id
    w("items.json", items)
    return items


def crops_table(items: dict) -> dict:
    # 从 seed 映射生成作物表
    crops = {}
    # seed_id -> crop
    seed_to_crop = {}
    for iid, it in items.items():
        if it.get("type") == "seed":
            seed_to_crop[iid] = it.get("crop_id", iid.replace("seed_", ""))

    meta = {
        "turnip": (3, 4, ["萌芽春"], 35, 0, "#A8C87A", "#F5F0E1", "白萝卜", "seed_turnip", "turnip"),
        "potato": (4, 4, ["萌芽春", "蜜酿秋"], 55, 0, "#8FBC6B", "#C4A060", "土豆", "seed_potato", "potato"),
        "tomato": (5, 5, ["长夏"], 75, 3, "#6B9B4A", "#E05555", "番茄", "seed_tomato", "tomato"),
        "berry": (4, 4, ["长夏", "蜜酿秋"], 95, 2, "#5A8A4A", "#E06090", "山莓", "seed_berry", "berry"),
    }
    # 简化：凡 items 里 seed 有 crop_id 且 product 存在则建表
    for sid, cid in seed_to_crop.items():
        if cid in crops:
            continue
        if cid not in items:
            continue
        product = items[cid]
        seed = items[sid]
        # days heuristic from name hash for variety if not in meta
        if cid in meta:
            days, stages, seasons, sell, regrow, sprout, mature, name, seed_item, product_item = meta[cid]
        else:
            days = 3 + (hash(cid) % 8)
            stages = 4
            seasons = seed.get("desc", "")
            # infer from buy/sell
            sell = int(product.get("sell_price", 40))
            regrow = 2 if sell >= 90 else 0
            sprout = str(seed.get("color", "#8FBC6B"))
            mature = str(product.get("color", "#E8C87A"))
            name = product.get("name", cid)
            seed_item = sid
            product_item = cid
            # season guess from seed name
            sn = seed.get("name", "")
            if any(k in sn for k in ["春", "生菜", "芦笋", "茶苗"]):
                seasons = ["萌芽春"]
            elif any(k in sn for k in ["夏", "瓜", "茄", "莓", "辣", "向日葵", "薰衣草"]):
                seasons = ["长夏"]
            elif any(k in sn for k in ["秋", "稻", "麦", "菌", "菊", "榛"]):
                seasons = ["蜜酿秋"]
            elif any(k in sn for k in ["冬", "雪", "橘", "冬青"]):
                seasons = ["静雪冬"]
            else:
                seasons = ["萌芽春", "长夏", "蜜酿秋", "静雪冬"]
        # better seasons from a static map of crop ids
        season_map = {
            "cabbage": ["萌芽春", "静雪冬"], "carrot": ["萌芽春", "蜜酿秋"], "onion": ["萌芽春"],
            "garlic": ["萌芽春", "静雪冬"], "radish": ["萌芽春"], "lettuce": ["萌芽春", "长夏"],
            "spinach": ["萌芽春"], "pea": ["萌芽春"], "strawberry": ["长夏"], "corn": ["长夏", "蜜酿秋"],
            "watermelon": ["长夏"], "melon": ["长夏"], "pepper": ["长夏", "蜜酿秋"], "eggplant": ["长夏"],
            "cucumber": ["长夏"], "pumpkin": ["蜜酿秋"], "sweet_potato": ["蜜酿秋"], "grape": ["蜜酿秋"],
            "rice": ["蜜酿秋"], "wheat": ["蜜酿秋", "静雪冬"], "mushroom": ["蜜酿秋", "静雪冬"],
            "hazelnut": ["蜜酿秋"], "sunflower": ["长夏", "蜜酿秋"], "lavender": ["长夏"],
            "chrysanthemum": ["蜜酿秋"], "plum": ["蜜酿秋"], "apple": ["蜜酿秋", "静雪冬"],
            "pear": ["蜜酿秋"], "tea": ["萌芽春", "长夏"], "herb": ["萌芽春", "长夏"],
            "cotton": ["长夏", "蜜酿秋"], "flax": ["萌芽春"], "cocoa_seed": ["长夏"],
            "vanilla": ["长夏"], "ginger": ["蜜酿秋", "静雪冬"], "lotus": ["长夏"],
            "bamboo_shoot": ["萌芽春"], "cocoa_bean": ["长夏"], "wintermelon": ["静雪冬"],
            "snow_pea": ["静雪冬"], "holly": ["静雪冬"], "mandarin": ["静雪冬"],
            "asparagus": ["萌芽春"], "artichoke": ["萌芽春", "长夏"],
        }
        if cid in season_map:
            seasons = season_map[cid]
        days_map = {
            "radish": 2, "lettuce": 3, "carrot": 3, "turnip": 3, "spinach": 3, "herb": 3,
            "cucumber": 4, "pea": 4, "bamboo_shoot": 4, "mushroom": 4,
        }
        days = days_map.get(cid, days)
        crops[cid] = {
            "id": cid,
            "name": name,
            "seed_item": seed_item,
            "product_item": product_item,
            "days_to_grow": days,
            "stages": 4 if days < 7 else 5,
            "seasons": seasons,
            "sell_price": sell,
            "regrow_days": regrow,
            "color": mature,
            "sprout_color": sprout,
            "mature_color": mature,
            "desc": product.get("desc", ""),
        }
    w("crops.json", crops)
    return crops


def recipes_table() -> dict:
    recipes = {}
    # 从 foods 推导一批配方
    food_inputs = {
        "turnip_cake": {"turnip": 2, "wood": 1},
        "berry_jam": {"berry": 3, "wood": 1},
        "tomato_soup": {"tomato": 2, "herb": 1},
        "potato_stew": {"potato": 2, "carrot": 1},
        "salad": {"lettuce": 2, "tomato": 1, "herb": 1},
        "veggie_skewer": {"pepper": 1, "eggplant": 1, "wood": 1},
        "fish_grill": {"carp_spring": 1, "wood": 1},
        "fish_stew": {"bluegill": 1, "potato": 1, "herb": 1},
        "berry_pie": {"berry": 3, "wheat": 1},
        "apple_pie": {"apple": 2, "wheat": 1},
        "corn_bread": {"corn": 2, "wheat": 1},
        "pumpkin_soup": {"pumpkin": 1, "herb": 1},
        "mushroom_risotto": {"mushroom": 2, "rice": 1},
        "honey_toast": {"wheat": 1, "sunflower": 1},
        "tea_set": {"tea": 2},
        "coffee": {"cocoa_bean": 2},
        "hot_cocoa": {"cocoa_bean": 1, "wheat": 1},
        "wine_grape": {"grape": 3, "wood": 1},
        "sushi": {"carp_spring": 1, "rice": 1},
        "rice_bowl": {"rice": 2, "eggplant": 1},
        "noodle": {"wheat": 2, "herb": 1},
        "dumpling": {"cabbage": 1, "carrot": 1, "wheat": 1},
        "hotpot": {"cabbage": 1, "mushroom": 1, "pepper": 1, "fish_grill": 1},
        "cheese": {"corn": 2},
        "butter_toast": {"wheat": 2},
        "jam_toast": {"wheat": 1, "berry_jam": 1},
        "pickles": {"cucumber": 3, "garlic": 1},
        "kimchi": {"cabbage": 2, "pepper": 1},
        "smoked_eel": {"night_eel": 1, "wood": 2},
        "honey": {"sunflower": 2, "lavender": 1},
        "candy": {"berry": 2},
        "chocolate": {"cocoa_bean": 2},
        "cake": {"wheat": 2, "strawberry": 1},
        "pudding": {"corn": 1, "sunflower": 1},
        "ice": {"berry": 2},
        "sun_cake": {"sunflower": 2, "wheat": 1},
        "herb_salt": {"herb": 2},
        "ginger_tea": {"ginger": 2, "tea": 1},
        "mixed_juice": {"strawberry": 1, "melon": 1, "grape": 1},
        "legend_feast": {"legend_fish": 1, "apple": 1, "mushroom": 1, "gold_ore": 1},
    }
    # 清理不存在材料
    for food, inputs in food_inputs.items():
        clean = {k: v for k, v in inputs.items() if v > 0}
        if not clean:
            continue
        recipes[food] = {
            "id": food,
            "name": f"料理·{food}",
            "station": "kitchen",
            "output": food,
            "output_count": 1,
            "inputs": clean,
            "desc": "厨房出品。",
        }

    work = {
        "field_marker": {"wood": 3, "fiber": 1},
        "tiny_bell": {"stone": 2, "wind_shard": 1, "wood": 2},
        "wood_from_fiber": {"fiber": 4},
        "wood_fence": {"wood": 2},
        "stone_path": {"stone": 2},
        "flower_pot": {"stone": 2, "fiber": 1},
        "lantern": {"wood": 2, "wind_shard": 1},
        "bench": {"wood": 4, "stone": 1},
        "sign_post": {"wood": 2, "fiber": 1},
        "well": {"stone": 5, "wood": 2},
        "birdhouse": {"wood": 4},
        "windmill_toy": {"wood": 3, "iron_ore": 1},
        "crystal_lamp": {"stone": 2, "wind_shard": 2, "copper_ore": 1},
        "rug": {"fiber": 5},
        "curtain": {"fiber": 4},
        "bookshelf": {"wood": 6, "fiber": 2},
        "tea_table": {"wood": 4},
        "painting_hills": {"wood": 2, "fiber": 2},
        "painting_lake": {"wood": 2, "fiber": 2},
        "painting_mine": {"wood": 2, "iron_ore": 1},
        "bell_mobile": {"tiny_bell": 1, "wood": 1},
        "festival_banner": {"fiber": 4, "pepper": 1},
        "photo_frame": {"wood": 2},
        "trophy_cup": {"gold_ore": 1, "stone": 2},
        "music_box": {"wood": 3, "iron_ore": 1, "wind_shard": 1},
        "potted_tree": {"wood": 3, "fiber": 2},
        "stone_lantern": {"stone": 4, "wind_shard": 1},
        "hanging_bells": {"tiny_bell": 1},
        "picnic_set": {"wood": 2, "fiber": 2},
        "cat_bed": {"fiber": 4, "wood": 1},
        "telescope": {"iron_ore": 3, "copper_ore": 2, "mythril_shard": 1},
    }
    work_output = {
        "wood_from_fiber": ("wood", 1),
    }
    for fid, inputs in work.items():
        clean = {k: v for k, v in inputs.items() if v > 0}
        out_id, out_n = work_output.get(fid, (fid, 1))
        station = "workbench"
        if fid in ["field_marker", "wood_fence", "bench", "sign_post", "birdhouse",
                   "bookshelf", "tea_table", "potted_tree", "picnic_set", "cat_bed",
                   "photo_frame", "rug", "curtain", "painting_hills", "painting_lake", "painting_mine"]:
            station = "carpentry"
        elif fid in ["windmill_toy", "trophy_cup", "music_box", "telescope",
                     "crystal_lamp", "stone_lantern", "lantern", "bell_mobile",
                     "hanging_bells", "tiny_bell", "well", "festival_banner"]:
            station = "crystal_atelier" if "lamp" in fid or "bell" in fid or "lantern" in fid or fid == "crystal_lamp" else "forge"
            if fid in ["crystal_lamp", "stone_lantern", "lantern", "bell_mobile", "hanging_bells", "tiny_bell"]:
                station = "crystal_atelier"
            elif fid in ["windmill_toy", "trophy_cup", "music_box", "telescope", "well", "festival_banner"]:
                station = "forge"
        recipes[fid] = {
            "id": fid,
            "name": fid,
            "station": station,
            "output": out_id,
            "output_count": out_n,
            "inputs": clean,
            "desc": "工作台合成。",
        }
    # 金属加工
    recipes["copper_wire"] = {
        "id": "copper_wire", "name": "铜件", "station": "workbench",
        "output": "copper_wire", "output_count": 1,
        "inputs": {"copper_ore": 1, "wood": 1}, "desc": "加固。"
    }
    # 工具升级配方：旧工具 + 金属 → 新阶工具
    tool_bases = ["hoe", "watering_can", "wood_axe", "stone_pick"]
    upgrade_ladder = [
        ("_copper", {"copper_ore": 5, "wood": 3}, 1),
        ("_iron", {"iron_ore": 5, "copper_wire": 1}, 2),
        ("_silver", {"silver_ore": 4, "wind_shard": 1}, 3),
        ("_star", {"mythril_shard": 3, "gold_ore": 2}, 4),
    ]
    prev_suffix = ["", "_copper", "_iron", "_silver"]
    for base in tool_bases:
        for i, (suffix, cost, tier) in enumerate(upgrade_ladder):
            out_id = base + suffix
            in_id = base + prev_suffix[i] if prev_suffix[i] else base
            recipes[f"upgrade_{out_id}"] = {
                "id": f"upgrade_{out_id}",
                "name": f"升级→{out_id}",
                "station": "forge",
                "output": out_id,
                "output_count": 1,
                "inputs": {in_id: 1, **cost},
                "desc": f"工具升级至 {tier + 1} 阶。",
            }
    w("recipes.json", recipes)
    return recipes


def fish_table() -> dict:
    fish = [
        {"id": "carp_spring", "name": "溪鲤", "seasons": ["萌芽春"], "sell_price": 40, "color": "#C8B090", "difficulty": 1},
        {"id": "crucian", "name": "银鲫", "seasons": ["萌芽春"], "sell_price": 48, "color": "#D0D0C0", "difficulty": 1},
        {"id": "loach", "name": "泥鳅", "seasons": ["萌芽春", "长夏"], "sell_price": 35, "color": "#A08060", "difficulty": 1},
        {"id": "dace", "name": "雅罗", "seasons": ["萌芽春"], "sell_price": 52, "color": "#B0C0A0", "difficulty": 2},
        {"id": "bluegill", "name": "蓝鳃太阳鱼", "seasons": ["长夏"], "sell_price": 55, "color": "#7EB8D0", "difficulty": 1},
        {"id": "bass", "name": "河鲈", "seasons": ["长夏"], "sell_price": 70, "color": "#90A8B0", "difficulty": 2},
        {"id": "catfish", "name": "鲶鱼", "seasons": ["长夏"], "sell_price": 80, "color": "#6B5340", "difficulty": 2},
        {"id": "puffer", "name": "河豚", "seasons": ["长夏"], "sell_price": 95, "color": "#E8D080", "difficulty": 3},
        {"id": "mackerel", "name": "鲭鱼", "seasons": ["长夏", "蜜酿秋"], "sell_price": 88, "color": "#80A0C0", "difficulty": 2},
        {"id": "salmon", "name": "溯河鲑", "seasons": ["蜜酿秋"], "sell_price": 120, "color": "#E09080", "difficulty": 3},
        {"id": "carp_mirror", "name": "镜鲤", "seasons": ["蜜酿秋"], "sell_price": 100, "color": "#D0B080", "difficulty": 2},
        {"id": "night_eel", "name": "夜鳗", "seasons": ["蜜酿秋"], "sell_price": 90, "color": "#6A5A8A", "difficulty": 3},
        {"id": "eel", "name": "黄鳝", "seasons": ["蜜酿秋", "长夏"], "sell_price": 75, "color": "#A09050", "difficulty": 2},
        {"id": "gudgeon", "name": "吻鮈", "seasons": ["蜜酿秋"], "sell_price": 42, "color": "#C0B090", "difficulty": 1},
        {"id": "ice_trout", "name": "冰晶鳟", "seasons": ["静雪冬"], "sell_price": 110, "color": "#B0D8E8", "difficulty": 2},
        {"id": "whitefish", "name": "白鲑", "seasons": ["静雪冬"], "sell_price": 98, "color": "#E0E8E8", "difficulty": 2},
        {"id": "smelt", "name": "胡瓜鱼", "seasons": ["静雪冬"], "sell_price": 60, "color": "#C0D0B0", "difficulty": 1},
        {"id": "pike", "name": "狗鱼", "seasons": ["静雪冬"], "sell_price": 130, "color": "#8A9A70", "difficulty": 3},
        {"id": "moon_koi", "name": "月光锦鲤", "seasons": [], "sell_price": 200, "color": "#E8C87A", "difficulty": 3, "rare": True},
        {"id": "ghost_fish", "name": "幽灵鱼", "seasons": [], "sell_price": 180, "color": "#C0C8D8", "difficulty": 3, "rare": True},
        {"id": "crystal_shrimp", "name": "雾晶虾", "seasons": [], "sell_price": 70, "color": "#A8D8E8", "difficulty": 1},
        {"id": "stone_loach", "name": "石鳅", "seasons": [], "sell_price": 50, "color": "#A0A0A0", "difficulty": 1},
        {"id": "pond_turtle", "name": "池龟", "seasons": [], "sell_price": 150, "color": "#6B8F5A", "difficulty": 3, "rare": True},
        {"id": "legend_fish", "name": "传说之鱼", "seasons": [], "sell_price": 500, "color": "#E8A0E8", "difficulty": 3, "rare": True},
    ]
    antiques = [
        {"id": "clay_bell", "name": "陶铃残片", "sell_price": 30, "color": "#D0A070"},
        {"id": "glass_marble", "name": "雾晶弹珠", "sell_price": 45, "color": "#A8D8E8"},
        {"id": "old_letter", "name": "风干的信", "sell_price": 25, "color": "#E8DCC0"},
        {"id": "gear_toy", "name": "齿轮玩具", "sell_price": 55, "color": "#A0A8B0"},
        {"id": "porcelain_shard", "name": "青瓷片", "sell_price": 40, "color": "#A0C0C0"},
        {"id": "bronze_coin", "name": "青铜钱", "sell_price": 35, "color": "#C0A060"},
        {"id": "wooden_comb", "name": "木梳", "sell_price": 28, "color": "#B8956C"},
        {"id": "stone_bead", "name": "石珠", "sell_price": 32, "color": "#9A9A9A"},
        {"id": "glass_bottle", "name": "雾玻璃瓶", "sell_price": 38, "color": "#C0E0E0"},
        {"id": "iron_key", "name": "旧铁钥", "sell_price": 50, "color": "#A0A8B0"},
        {"id": "bone_flake", "name": "骨哨残片", "sell_price": 33, "color": "#E8E0D0"},
        {"id": "pocket_watch", "name": "怀表（停了）", "sell_price": 80, "color": "#E8C87A"},
    ]
    w("fish_antiques.json", {"fish": fish, "antiques": antiques})
    return {"fish": fish, "antiques": antiques}


def mine_table() -> dict:
    floors = []
    themes = [
        ("雾晶矿洞", "#2A3340", "#4A5A6A", "slime"),
        ("回声廊", "#243040", "#5A7A8A", "bat"),
        ("脉心", "#1A2430", "#6A8AAA", "bat"),
        ("矿脉深部", "#121A24", "#7A9AB0", "bat"),
        ("节拍室", "#0E141C", "#8AACB8", "bat"),
    ]
    for i in range(26):
        tier = i // 5
        name_prefix, bg, accent, etype = themes[min(tier, 4)]
        ore_w = {"stone": max(1, 5 - tier), "copper_ore": 3, "iron_ore": 2 + min(tier, 2), "wind_shard": 1 + min(tier, 3)}
        if tier >= 2:
            ore_w["silver_ore"] = 2
        if tier >= 3:
            ore_w["gold_ore"] = 2
        if tier >= 4:
            ore_w["mythril_shard"] = 2
            ore_w["wind_shard"] = 4
        floors.append({
            "id": i + 1,
            "name": f"{name_prefix} · {i + 1:02d}层",
            "depth_label": f"B{i + 1}",
            "rock_count": 10 + (i % 8),
            "enemy_count": 2 + (i % 6),
            "chest_count": 1 + (i % 3),
            "ore_weights": ore_w,
            "enemy_type": etype,
            "bg": bg,
            "accent": accent,
            "desc": "雾晶与岩石的层叠。" if i < 5 else "越深，风声越像歌。",
            **({"boss": "slime_king"} if (i + 1) % 7 == 0 else {}),
        })
    enemies = {
        "slime": {"name": "晶蚀史莱姆", "hp": 3, "touch_damage": 1, "speed": 40, "color": "#7BC96F", "size": 14, "loot": {"stone": 1}},
        "bat": {"name": "雾蝠", "hp": 2, "touch_damage": 1, "speed": 70, "color": "#8A7AAA", "size": 12, "loot": {"fiber": 1}},
        "slime_king": {"name": "岩心守卫", "hp": 12, "touch_damage": 1, "speed": 35, "color": "#C9A227", "size": 28, "loot": {"wind_shard": 2, "iron_ore": 2}},
    }
    chest = [
        {"weight": 3, "drops": {"copper_ore": 2, "stone": 3}},
        {"weight": 3, "drops": {"iron_ore": 1, "copper_ore": 1}},
        {"weight": 2, "drops": {"wind_shard": 1, "stone": 2}},
        {"weight": 1, "drops": {"seed_tomato": 2, "turnip": 1}},
        {"weight": 1, "drops": {"wind_shard": 2}},
        {"weight": 1, "drops": {"silver_ore": 1}},
        {"weight": 1, "drops": {"gold_ore": 1}},
        {"weight": 1, "drops": {"clay_bell": 1}},
        {"weight": 1, "drops": {"glass_marble": 1}},
    ]
    w("mine.json", {"floors": floors, "enemy_types": enemies, "chest_table": chest})
    return {"floors": floors}


def commissions_table() -> dict:
    pool = []
    items_cycle = ["turnip", "potato", "tomato", "berry", "wood", "stone", "fiber", "copper_ore", "iron_ore", "carrot", "cabbage", "corn", "pumpkin", "mushroom", "tea", "carp_spring", "bluegill", "wind_shard", "turnip_cake", "berry_jam", "salad", "honey", "cotton", "grape"]
    names = ["林爷爷", "小满", "桃枝", "阿棠", "江澄", "云舟", "石匠", "茶婆", "集市", "守林人", "厨娘", "旅人"]
    for i in range(60):
        item = items_cycle[i % len(items_cycle)]
        count = 1 + (i % 4)
        money = 40 + (i % 10) * 15
        reward_item = items_cycle[(i + 7) % len(items_cycle)]
        pool.append({
            "id": f"q_auto_{i:02d}",
            "text": f"{names[i % len(names)]}的委托：{item} ×{count}",
            "item": item,
            "count": count,
            "reward_money": money,
            "reward_item": reward_item,
            "reward_count": 1 + (i % 2),
            "day_mod": 2 + (i % 5),
        })
    w("commissions.json", {"board": pool})
    return {"board": pool}


def heart_table() -> dict:
    npcs = ["grandpa_lin", "xiaoman", "zhi_tao", "atang", "jiangcheng", "yunzhou", "shijiang", "chapo"]
    events = []
    for ni, nid in enumerate(npcs):
        for heart, title, lines in [
            (2, "小事一桩", [f"{nid} 和你分享了一段往事。", "好感升温。"]),
            (4, "心意", [f"{nid} 把一件小礼物塞进你手里。", "你们更亲近了。"]),
            (6, "约定", [f"{nid}：往后的风铃节，都要一起听铃啊。", "羁绊已达深处。"]),
        ]:
            events.append({
                "id": f"{nid}_{heart}",
                "npc_id": nid,
                "heart": heart,
                "title": title,
                "lines": lines,
                "reward": {"friendship": 5 + heart, "item": "wind_shard" if heart == 6 else "herb", "count": 1},
            })
    w("heart_events.json", {
        "events": events,
        "heart_thresholds": {"2": 20, "4": 50, "6": 90},
    })
    return events


def npcs_table() -> dict:
    base = json.loads((DATA / "npcs.json").read_text(encoding="utf-8"))
    more = {
        "atang": {
            "id": "atang", "name": "阿棠", "role": "杂货店主", "color": "#E8C8A0", "accent": "#C05040",
            "position": {"x": 500, "y": 300},
            "likes": ["turnip_cake", "coffee"], "dislikes": ["stone"],
            "dialogues": {
                "first_meet": ["我是阿棠，杂货摊的老板。", "谷币和人情，我两样都记账。"],
                "default": ["今天的市价我可盯着呢。", "缺种子就来。"],
                "liked_gift": ["识货！"],
                "disliked_gift": ["这玩意儿压秤不值钱。"],
            },
        },
        "jiangcheng": {
            "id": "jiangcheng", "name": "江澄", "role": "渔夫", "color": "#A0C0D0", "accent": "#3A6A8A",
            "position": {"x": 900, "y": 450},
            "likes": ["fish_grill", "carp_spring"], "dislikes": ["turnip"],
            "dialogues": {
                "first_meet": ["江澄。水里的事，问我。", "昨天那条大的……算了。"],
                "default": ["风向对了，鱼才开口。", "湖边安静才好。"],
                "liked_gift": ["好味道！下回教你起竿。"],
                "disliked_gift": ["田里的东西啊……也行吧。"],
            },
        },
        "yunzhou": {
            "id": "yunzhou", "name": "云舟", "role": "画师", "color": "#D0C0E0", "accent": "#7A5A9A",
            "position": {"x": 720, "y": 220},
            "likes": ["painting_hills", "tea_set"], "dislikes": ["copper_ore"],
            "dialogues": {
                "first_meet": ["云舟，来借住写生。", "你这谷子，光影会讲故事。"],
                "default": ["别动，再给我一笔。", "颜料不够了……"],
                "liked_gift": ["妙极。这颜色我要了。"],
                "disliked_gift": ["金属？我的画笔会哭。"],
            },
        },
        "shijiang": {
            "id": "shijiang", "name": "石老", "role": "石匠", "color": "#C0B8A8", "accent": "#8A8A8A",
            "position": {"x": 320, "y": 500},
            "likes": ["stone", "iron_ore"], "dislikes": ["berry"],
            "dialogues": {
                "first_meet": ["石老。石头比人诚实。", "要修什么，拿材料来。"],
                "default": ["叮当叮当，日子就过去了。", "好石头会自己唱歌。"],
                "liked_gift": ["嗯，有分量。"],
                "disliked_gift": ["酸果子留着吧。"],
            },
        },
        "chapo": {
            "id": "chapo", "name": "茶婆", "role": "茶师", "color": "#E0C8B0", "accent": "#6B8F5A",
            "position": {"x": 580, "y": 420},
            "likes": ["tea_set", "ginger_tea"], "dislikes": ["stone"],
            "dialogues": {
                "first_meet": ["来，坐下喝一口。", "山上的雾，都在这杯里。"],
                "default": ["水开了。", "慢慢来，茶不怕等。"],
                "liked_gift": ["真是细心的孩子。"],
                "disliked_gift": ["这个……泡不开。"],
            },
        },
    }
    base.update(more)
    w("npcs.json", base)
    return base


def shop_table() -> dict:
    stock = [
        {"item": "seed_turnip", "price": 20, "seasons": ["萌芽春"]},
        {"item": "seed_potato", "price": 30, "seasons": ["萌芽春", "蜜酿秋"]},
        {"item": "seed_tomato", "price": 40, "seasons": ["长夏"]},
        {"item": "seed_berry", "price": 55, "seasons": ["长夏", "蜜酿秋"]},
        {"item": "seed_cabbage", "price": 35, "seasons": ["萌芽春", "静雪冬"]},
        {"item": "seed_carrot", "price": 25, "seasons": ["萌芽春", "蜜酿秋"]},
        {"item": "seed_strawberry", "price": 70, "seasons": ["长夏"]},
        {"item": "seed_corn", "price": 60, "seasons": ["长夏", "蜜酿秋"]},
        {"item": "seed_pumpkin", "price": 90, "seasons": ["蜜酿秋"]},
        {"item": "seed_rice", "price": 55, "seasons": ["蜜酿秋"]},
        {"item": "seed_tea", "price": 65, "seasons": ["萌芽春", "长夏"]},
        {"item": "seed_mandarin", "price": 85, "seasons": ["静雪冬"]},
        {"item": "wood", "price": 8, "seasons": []},
        {"item": "stone", "price": 7, "seasons": []},
        {"item": "fiber", "price": 4, "seasons": []},
        {"item": "turnip_cake", "price": 70, "seasons": []},
    ]
    w("shop.json", {"shop_id": "general_store", "name": "阿棠杂货", "npc_id": "atang", "stock": stock})
    return stock


def season_events() -> dict:
    w("season_events.json", {
        "events": [
            {"id": "kite_day", "season": "萌芽春", "day": 7, "title": "风筝日", "lines": ["广场上飘满了风筝。", "风铃和风筝比赛谁先碰到云。"], "reward": {"item": "fiber", "count": 3}},
            {"id": "try_plant", "season": "萌芽春", "day": 14, "title": "迎风试种", "lines": ["大家把第一粒种子交给风。", "你的田也多了一丝勇气。"], "reward": {"item": "seed_radish", "count": 3}},
            {"id": "lake_lights", "season": "长夏", "day": 8, "title": "湖灯夜", "lines": ["湖面被灯火点亮。", "像另一条银河。"], "reward": {"item": "lantern", "count": 1}},
            {"id": "tea_party", "season": "长夏", "day": 16, "title": "凉茶会", "lines": ["茶婆支起了茶摊。", "一口下去，暑气都低了头。"], "reward": {"item": "tea_set", "count": 1}},
            {"id": "harvest_fair", "season": "蜜酿秋", "day": 10, "title": "丰收市集", "lines": ["喇叭和叫卖声混在一起。", "溢价商品今天特别好卖！"], "reward": {"money": 200}},
            {"id": "honey_fest", "season": "蜜酿秋", "day": 18, "title": "蜜酿节", "lines": ["甜香飘了三条街。"], "reward": {"item": "honey", "count": 1}},
            {"id": "hearth_night", "season": "静雪冬", "day": 9, "title": "围炉夜", "lines": ["壁炉噼啪，故事轮流传。"], "reward": {"item": "hot_cocoa", "count": 1}},
            {"id": "snow_bell", "season": "静雪冬", "day": 20, "title": "雪中寻铃", "lines": ["雪地上有一串铃印。", "风在很远的地方练习。"], "reward": {"item": "wind_shard", "count": 1}},
        ]
    })


def achievements() -> dict:
    w("achievements.json", {
        "list": [
            {"id": "first_harvest", "name": "第一筐", "desc": "完成第一次收获", "check": "harvest_count>=1"},
            {"id": "green_thumb", "name": "绿手指", "desc": "收获 50 次", "check": "harvest_count>=50"},
            {"id": "flash_fruit", "name": "闪光时刻", "desc": "获得闪光果", "check": "flash_count>=1"},
            {"id": "miner", "name": "下矿去", "desc": "开采 30 次矿岩", "check": "mine_count>=30"},
            {"id": "deep_dive", "name": "地心来客", "desc": "抵达 B10", "check": "max_floor>=10"},
            {"id": "social", "name": "谷里有人缘", "desc": "与 5 人成为朋友", "check": "friends>=5"},
            {"id": "bell1", "name": "风起了", "desc": "修好第 1 枚风铃", "check": "bells>=1"},
            {"id": "bell5", "name": "风之祭", "desc": "五铃齐鸣", "check": "bells>=5"},
            {"id": "rich", "name": "小富即安", "desc": "持有 5000 谷币", "check": "money>=5000"},
            {"id": "museum", "name": "博物之友", "desc": "捐赠 10 件藏品", "check": "donate>=10"},
            {"id": "cook", "name": "厨房主理人", "desc": "合成 20 次料理", "check": "cook_count>=20"},
            {"id": "legend_fish", "name": "传说之钓", "desc": "钓到传说之鱼", "check": "legend_fish>=1"},
        ]
    })


def main() -> None:
    items = items_table()
    crops_table(items)
    recipes_table()
    fish_table()
    mine_table()
    commissions_table()
    heart_table()
    npcs_table()
    shop_table()
    season_events()
    achievements()
    print("content generation done")


if __name__ == "__main__":
    main()
