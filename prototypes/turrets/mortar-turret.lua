-- MORTAR TURRET
-- Slow-firing, high area damage. Effective against swarm biters arriving in
-- dense clusters; less efficient against single armored targets.

local Util         = require("prototypes.utility.util")

local MORTAR_TINT  = { r = 1.0, g = 0.5, b = 0.1, a = 1.0 }

local mortar = table.deepcopy(data.raw["ammo-turret"]["gun-turret"])
mortar.name = "td-mortar-turret"
mortar.minable.result = "td-mortar-turret"
mortar.attack_parameters.cooldown = mortar.attack_parameters.cooldown * 8
mortar.attack_parameters.range = 24
mortar.attack_parameters.ammo_category = "td-mortar-shell"
mortar.collision_box = { { -0.9, -0.9 }, { 0.9, 0.9 } }
mortar.selection_box = { { -1.0, -1.0 }, { 1.0, 1.0 } }
Util.tint_graphics(mortar, MORTAR_TINT)

data:extend({ mortar })

local mortar_item = table.deepcopy(data.raw.item["gun-turret"])
mortar_item.name = "td-mortar-turret"
mortar_item.place_result = "td-mortar-turret"
mortar_item.order = "a[turret]-b[td-mortar-turret]"
Util.tint_icon(mortar_item, MORTAR_TINT)

data:extend({ mortar_item })

data:extend({
    {
        type = "recipe",
        name = "td-mortar-turret",
        category = "crafting",
        enabled = true,
        energy_required = 10,
        ingredients = {
            { type = "item", name = "iron-plate",   amount = 20 },
            { type = "item", name = "copper-plate", amount = 10 },
            { type = "item", name = "steel-plate",  amount = 5 },
        },
        results = {
            { type = "item", name = "td-mortar-turret", amount = 1 },
        },
    },
})
