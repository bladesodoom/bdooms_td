-- RAPID ROUNDS
-- Ammo category and all three ammo tiers for the Rapid Turret.

local Util       = require("prototypes.utility.util")

local RAPID_TINT = { r = 0.3, g = 0.8, b = 1.0, a = 1.0 }

data:extend({
    {
        type = "ammo-category",
        name = "td-rapid-bullet",
    },
})

-- =======================================================================
-- TIER 1 - Rapid Rounds (base)

local rapid_rounds = table.deepcopy(data.raw.ammo["firearm-magazine"])
rapid_rounds.name = "td-rapid-rounds"
rapid_rounds.order = "a[basic-clips]-z[td-rapid-rounds]"
Util.set_ammo_category(rapid_rounds, "td-rapid-bullet")
Util.scale_damage(rapid_rounds.ammo_type, 0.5)
Util.tint_icon(rapid_rounds, RAPID_TINT)

data:extend({ rapid_rounds })

data:extend({
    {
        type = "recipe",
        name = "td-rapid-rounds",
        category = "crafting",
        enabled = true,
        energy_required = 1,
        ingredients = {
            { type = "item", name = "iron-plate",   amount = 1 },
            { type = "item", name = "copper-plate", amount = 1 },
        },
        results = {
            { type = "item", name = "td-rapid-rounds", amount = 2 },
        },
    },
})

-- =======================================================================
-- TIER 2 - Rapid Rounds Mk2

local rapid_mk2 = table.deepcopy(data.raw.ammo["firearm-magazine"])
rapid_mk2.name = "td-rapid-rounds-mk2"
rapid_mk2.icon = "__base__/graphics/icons/piercing-rounds-magazine.png"
rapid_mk2.icon_size = 64
rapid_mk2.icons = nil
rapid_mk2.order = "a[basic-clips]-z[td-rapid-rounds-mk2]"
Util.set_ammo_category(rapid_mk2, "td-rapid-bullet")
Util.scale_damage(rapid_mk2.ammo_type, 0.75)
Util.tint_icon(rapid_mk2, RAPID_TINT)

data:extend({ rapid_mk2 })

data:extend({
    {
        type = "recipe",
        name = "td-rapid-rounds-mk2",
        category = "crafting",
        enabled = true,
        energy_required = 3,
        ingredients = {
            { type = "item", name = "steel-plate",  amount = 1 },
            { type = "item", name = "copper-plate", amount = 1 },
        },
        results = {
            { type = "item", name = "td-rapid-rounds-mk2", amount = 1 },
        },
    },
})

-- =======================================================================
-- TIER 3 - Rapid Rounds AP
-- Slight range bonus: 1.2x turret base range when AP is loaded.

local rapid_ap = table.deepcopy(data.raw.ammo["firearm-magazine"])
rapid_ap.name = "td-rapid-rounds-ap"
rapid_ap.icon = "__base__/graphics/icons/cannon-shell.png"
rapid_ap.icon_size = 64
rapid_ap.icons = nil
rapid_ap.order = "a[basic-clips]-z[td-rapid-rounds-ap]"
Util.set_ammo_category(rapid_ap, "td-rapid-bullet")
Util.scale_damage(rapid_ap.ammo_type, 1.25)
Util.set_range_modifier(rapid_ap, 1.2)
Util.tint_icon(rapid_ap, RAPID_TINT)

data:extend({ rapid_ap })

data:extend({
    {
        type = "recipe",
        name = "td-rapid-rounds-ap",
        category = "crafting",
        enabled = true,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "steel-plate",     amount = 1 },
            { type = "item", name = "copper-plate",    amount = 1 },
            { type = "item", name = "iron-gear-wheel", amount = 1 },
        },
        results = {
            { type = "item", name = "td-rapid-rounds-ap", amount = 1 },
        },
    },
})
