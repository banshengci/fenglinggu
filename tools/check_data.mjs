#!/usr/bin/env node
/**
 * 风铃谷数据表校验
 * 用法: node tools/check_data.mjs
 */
import { readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const dataDir = join(root, "game", "data");

function load(name) {
  const p = join(dataDir, name);
  if (!existsSync(p)) throw new Error(`缺少文件 ${name}`);
  return JSON.parse(readFileSync(p, "utf8"));
}

const items = load("items.json");
const crops = load("crops.json");
const recipes = load("recipes.json");
const npcs = load("npcs.json");
const mine = load("mine.json");
const shop = load("shop.json");
const heart = load("heart_events.json");
const market = load("market.json");
const story = load("story.json");
const commissions = load("commissions.json");
const fishAntiques = load("fish_antiques.json");
const seasonEvents = load("season_events.json");
const achievements = load("achievements.json");

const errors = [];
const warnings = [];

for (const [id, item] of Object.entries(items)) {
  if (item.id !== id) errors.push(`items.${id}: id 字段应为 "${id}"`);
  if (!item.name) errors.push(`items.${id}: 缺少 name`);
  if (!item.color) warnings.push(`items.${id}: 缺少 color`);
}

for (const [id, crop] of Object.entries(crops)) {
  if (crop.id !== id) errors.push(`crops.${id}: id 不匹配`);
  if (!items[crop.product_item]) errors.push(`crops.${id}: product_item "${crop.product_item}" 不在 items`);
  if (!items[crop.seed_item]) errors.push(`crops.${id}: seed_item "${crop.seed_item}" 不在 items`);
  if (!(crop.days_to_grow > 0)) errors.push(`crops.${id}: days_to_grow 无效`);
  if (items[crop.seed_item] && items[crop.seed_item].crop_id !== id) {
    errors.push(`crops.${id}: seed_item.crop_id 应指向 "${id}"`);
  }
}

for (const [id, r] of Object.entries(recipes)) {
  if (!items[r.output]) errors.push(`recipes.${id}: output "${r.output}" 不在 items`);
  for (const mat of Object.keys(r.inputs || {})) {
    if (!items[mat]) errors.push(`recipes.${id}: 材料 "${mat}" 不在 items`);
  }
  if (!["workbench", "kitchen", "carpentry", "forge", "crystal_atelier"].includes(r.station)) {
    warnings.push(`recipes.${id}: station "${r.station}" 非 workbench/kitchen/carpentry/forge/crystal_atelier`);
  }
}

for (const [id, n] of Object.entries(npcs)) {
  if (n.id !== id) errors.push(`npcs.${id}: id 不匹配`);
  for (const g of [...(n.likes || []), ...(n.dislikes || [])]) {
    if (!items[g]) warnings.push(`npcs.${id}: 礼物 "${g}" 不在 items`);
  }
}

for (const floor of mine.floors || []) {
  for (const ore of Object.keys(floor.ore_weights || {})) {
    if (!items[ore]) errors.push(`mine floor ${floor.id}: 矿石 "${ore}" 不在 items`);
  }
  const et = floor.enemy_type;
  if (et && !mine.enemy_types?.[et]) errors.push(`mine floor ${floor.id}: 敌人 "${et}" 未定义`);
  if (floor.boss && !mine.enemy_types?.[floor.boss]) errors.push(`mine floor ${floor.id}: boss "${floor.boss}" 未定义`);
}
for (const row of mine.chest_table || []) {
  for (const drop of Object.keys(row.drops || {})) {
    if (!items[drop]) errors.push(`mine chest: 物品 "${drop}" 不在 items`);
  }
}

for (const row of shop.stock || []) {
  if (!items[row.item]) errors.push(`shop: 商品 "${row.item}" 不在 items`);
}

for (const e of heart.events || []) {
  if (!npcs[e.npc_id]) errors.push(`heart ${e.id}: npc "${e.npc_id}" 不存在`);
  const reward = e.reward || {};
  if (reward.item && !items[reward.item]) errors.push(`heart ${e.id}: 奖励 "${reward.item}" 不在 items`);
}

for (const [day, list] of Object.entries(market.premium_weekdays || {})) {
  for (const id of list) {
    if (!items[id]) errors.push(`market day ${day}: "${id}" 不在 items`);
  }
}

for (const ch of story.chapters || []) {
  if (!ch.title) errors.push(`story ch${ch.id}: 缺 title`);
  if (ch.unlock_area && !["town", "mine", "deep_mine", "lakeside", "forest", "festival"].includes(ch.unlock_area)) {
    errors.push(`story ch${ch.id}: 未知区域 ${ch.unlock_area}`);
  }
}
if ((story.chapters || []).length !== 5) errors.push("story: 应有 5 章");

for (const row of commissions.board || []) {
  if (!items[row.item]) errors.push(`commission ${row.id}: 交付物 "${row.item}" 不在 items`);
  if (row.reward_item && !items[row.reward_item]) errors.push(`commission ${row.id}: 奖励 "${row.reward_item}" 不在 items`);
}

for (const f of fishAntiques.fish || []) {
  if (!f.id || !f.name) errors.push("fish_antiques: fish 缺 id/name");
}
for (const a of fishAntiques.antiques || []) {
  if (!a.id || !a.name) errors.push("fish_antiques: antique 缺 id/name");
}

for (const e of seasonEvents.events || []) {
  if (!e.id || !e.season) errors.push("season_events: 缺 id/season");
  if (e.reward?.item && !items[e.reward.item]) errors.push(`season ${e.id}: 奖励 "${e.reward.item}" 不在 items`);
}

for (const a of achievements.list || []) {
  if (!a.id || !a.check) errors.push("achievements: 缺 id/check");
}

// 启动物资存在性
for (const tool of ["hoe", "watering_can", "wood_axe", "stone_pick", "seed_turnip", "seed_potato"]) {
  if (!items[tool]) errors.push(`开局物资缺失: ${tool}`);
}

console.log(`items=${Object.keys(items).length} crops=${Object.keys(crops).length} recipes=${Object.keys(recipes).length} npcs=${Object.keys(npcs).length} mine_floors=${(mine.floors||[]).length} shop=${(shop.stock||[]).length} hearts=${(heart.events||[]).length} story=${(story.chapters||[]).length} commissions=${(commissions.board||[]).length} fish=${(fishAntiques.fish||[]).length} antiques=${(fishAntiques.antiques||[]).length} season_events=${(seasonEvents.events||[]).length} achievements=${(achievements.list||[]).length}`);

if (warnings.length) {
  console.log("\n警告:");
  for (const w of warnings) console.log("  -", w);
}
if (errors.length) {
  console.log("\n错误:");
  for (const e of errors) console.log("  -", e);
  process.exit(1);
}
console.log("\n数据表校验通过 ✓");
