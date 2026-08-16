-- SNIPER TURRET
-- Very long range, very high single-target damage, slow fire rate.

local Util         = require("prototypes.utility.util")

local SNIPER_TINT  = { r = 0.2, g = 0.9, b = 0.3, a = 1.0 }

local sniper = table.deepcopy(data.raw["ammo-turret"]["gun-turret"])
sniper.name = "td-sniper-turret"
sniper.minable.result = "td-sniper-turret"
sniper.attack_parameters.cooldown = sniper.attack_parameters.cooldown * 6
sniper.attack_parameters.range = 40
sniper.attack_parameters.ammo_category = "td-sniper-round"
Util.tint_graphics(sniper, SNIPER_TINT)

data:extend({ sniper })

local sniper_item = table.deepcopy(data.raw.item["gun-turret"])
sniper_item.name = "td-sniper-turret"
sniper_item.place_result = "td-sniper-turret"
sniper_item.order = "a[turret]-c[td-sniper-turret]"
Util.tint_icon(sniper_item, SNIPER_TINT)

data:extend({ sniper_item })

data:extend({
    {
        type = "recipe",
        name = "td-sniper-turret",
        category = "crafting",
        enabled = true,
        energy_required = 15,
        ingredients = {
            { type = "item", name = "iron-plate",   amount = 15 },
            { type = "item", name = "steel-plate",  amount = 10 },
            { type = "item", name = "copper-plate", amount = 10 },
        },
        results = {
            { type = "item", name = "td-sniper-turret", amount = 1 },
        },
    },
})
