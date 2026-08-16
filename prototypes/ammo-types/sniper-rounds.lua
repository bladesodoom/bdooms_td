-- SNIPER ROUNDS
-- Ammo category and all three round tiers for the Sniper Turret. Cloned
-- from piercing-rounds-magazine scaled up significantly for the high
-- per-shot punch the sniper archetype requires.
--
-- All damage is relative to piercing-rounds-magazine base:
--   Standard   = piercing * 5
--   Long Range = piercing * 5  (same damage, more range)
--   AP         = piercing * 10 (2x standard, slightly less extra range)

local Util        = require("prototypes.utility.util")
local Projectiles = require("prototypes.utility.projectiles")

local SNIPER_TINT           = { r = 0.2, g = 0.9, b = 0.3, a = 1.0 }
local SNIPER_PROJECTILE_SPEED = 1.0 -- tiles/tick, fast enough to feel hitscan-like at 40-56 tile range

data:extend({
    {
        type = "ammo-category",
        name = "td-sniper-round",
    },
})

-- =======================================================================
-- TIER 1 - High-Caliber Rounds (base)

local sniper_round = table.deepcopy(data.raw.ammo["piercing-rounds-magazine"])
sniper_round.name = "td-sniper-round"
sniper_round.order = "a[basic-clips]-z[td-sniper-round]"
Util.set_ammo_category(sniper_round, "td-sniper-round")
Util.scale_damage(sniper_round.ammo_type, 5)
Util.tint_icon(sniper_round, SNIPER_TINT)

-- Custom projectile: piercing-rounds-magazine normally resolves as an
-- instant hitscan with no physical projectile, so it's converted into a
-- flying one here - tinted sniper-green and scaled up for a high-caliber
-- look. Tiers 2/3 build on this one, adding a tracer glow and further scale
-- as the round gets more powerful.
local hit_effects = Util.convert_to_projectile_delivery(
    sniper_round, "td-sniper-round-projectile", SNIPER_PROJECTILE_SPEED)
Projectiles.create({
    name  = "td-sniper-round-projectile",
    tint  = SNIPER_TINT,
    scale = 1.3,
    extra = {
        action = {
            type = "direct",
            action_delivery = { type = "instant", target_effects = hit_effects },
        },
    },
})

data:extend({ sniper_round })

data:extend({
    {
        type = "recipe",
        name = "td-sniper-round",
        category = "crafting",
        enabled = true,
        energy_required = 4,
        ingredients = {
            { type = "item", name = "steel-plate",  amount = 2 },
            { type = "item", name = "copper-plate", amount = 1 },
        },
        results = {
            { type = "item", name = "td-sniper-round", amount = 1 },
        },
    },
})

-- =======================================================================
-- TIER 2 - Long Range
-- Same damage as standard, 1.4x range_modifier (40 -> 56 tiles). Designed
-- for picking off worm turrets and nests from safety.

local sniper_long = table.deepcopy(data.raw.ammo["piercing-rounds-magazine"])
sniper_long.name = "td-sniper-round-long"
sniper_long.icon = "__base__/graphics/icons/radar.png"
sniper_long.icon_size = 64
sniper_long.icons = nil
sniper_long.order = "a[basic-clips]-z[td-sniper-round-long]"
Util.set_ammo_category(sniper_long, "td-sniper-round")
Util.scale_damage(sniper_long.ammo_type, 5)
Util.set_range_modifier(sniper_long, 1.4)
Util.tint_icon(sniper_long, SNIPER_TINT)

-- Same size as tier 1, plus a soft green tracer glow that reads well over
-- the long flight this round is built for.
local hit_effects_long = Util.convert_to_projectile_delivery(
    sniper_long, "td-sniper-round-long-projectile", SNIPER_PROJECTILE_SPEED)
Projectiles.create({
    name  = "td-sniper-round-long-projectile",
    base  = "td-sniper-round-projectile",
    light = { size = 1.0, intensity = 0.5, color = SNIPER_TINT },
    extra = {
        action = {
            type = "direct",
            action_delivery = { type = "instant", target_effects = hit_effects_long },
        },
    },
})

data:extend({ sniper_long })

data:extend({
    {
        type = "recipe",
        name = "td-sniper-round-long",
        category = "crafting",
        enabled = true,
        energy_required = 6,
        ingredients = {
            { type = "item", name = "steel-plate",  amount = 3 },
            { type = "item", name = "copper-plate", amount = 1 },
        },
        results = {
            { type = "item", name = "td-sniper-round-long", amount = 1 },
        },
    },
})

-- =======================================================================
-- TIER 3 - AP Round
-- 2x damage + 1.2x range.

local sniper_ap = table.deepcopy(data.raw.ammo["piercing-rounds-magazine"])
sniper_ap.name = "td-sniper-round-ap"
sniper_ap.icon = "__base__/graphics/icons/cannon-shell.png"
sniper_ap.icon_size = 64
sniper_ap.icons = nil
sniper_ap.order = "a[basic-clips]-z[td-sniper-round-ap]"
Util.set_ammo_category(sniper_ap, "td-sniper-round")
Util.scale_damage(sniper_ap.ammo_type, 10)
Util.set_range_modifier(sniper_ap, 1.2)
Util.tint_icon(sniper_ap, SNIPER_TINT)

-- Biggest, brightest round in the line: further scaled up from the long
-- range round and a hotter/wider glow to sell the 2x damage.
local hit_effects_ap = Util.convert_to_projectile_delivery(
    sniper_ap, "td-sniper-round-ap-projectile", SNIPER_PROJECTILE_SPEED)
Projectiles.create({
    name  = "td-sniper-round-ap-projectile",
    base  = "td-sniper-round-long-projectile",
    scale = 1.15,
    light = { size = 1.4, intensity = 0.9, color = SNIPER_TINT },
    extra = {
        action = {
            type = "direct",
            action_delivery = { type = "instant", target_effects = hit_effects_ap },
        },
    },
})

data:extend({ sniper_ap })

data:extend({
    {
        type = "recipe",
        name = "td-sniper-round-ap",
        category = "crafting",
        enabled = true,
        energy_required = 8,
        ingredients = {
            { type = "item", name = "steel-plate",     amount = 3 },
            { type = "item", name = "copper-plate",    amount = 1 },
            { type = "item", name = "iron-gear-wheel", amount = 2 },
        },
        results = {
            { type = "item", name = "td-sniper-round-ap", amount = 1 },
        },
    },
})
