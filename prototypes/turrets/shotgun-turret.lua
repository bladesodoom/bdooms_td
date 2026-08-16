-- SHOTGUN TURRET
-- Very short range, fires a pellet spread per shot. Devastating up close,
-- falls off hard past its short max range. Effective against dense swarms
-- that get in close; wasted on distant single targets.

local Util          = require("prototypes.utility.util")

local SHOTGUN_TINT  = { r = 0.85, g = 0.2, b = 0.75, a = 1.0 }

local shotgun_turret                           = table.deepcopy(data.raw
    ["ammo-turret"]["gun-turret"])
shotgun_turret.name                            = "td-shotgun-turret"
shotgun_turret.minable.result                  = "td-shotgun-turret"
shotgun_turret.attack_parameters.range         = 12
shotgun_turret.attack_parameters.min_range     = 0
shotgun_turret.attack_parameters.ammo_category = "td-shotgun-shell"
Util.tint_graphics(shotgun_turret, SHOTGUN_TINT)

data:extend({ shotgun_turret })

local shotgun_turret_item = table.deepcopy(data.raw.item["gun-turret"])
shotgun_turret_item.name = "td-shotgun-turret"
shotgun_turret_item.place_result = "td-shotgun-turret"
shotgun_turret_item.order = "a[turret]-d[td-shotgun-turret]"
Util.tint_icon(shotgun_turret_item, SHOTGUN_TINT)

data:extend({ shotgun_turret_item })

local shotgun_turret_recipe = table.deepcopy(data.raw.recipe["gun-turret"])
shotgun_turret_recipe.name = "td-shotgun-turret"
shotgun_turret_recipe.enabled = true
shotgun_turret_recipe.results = { {
    type = "item",
    name = "td-shotgun-turret",
    amount = 1
} }

data:extend({ shotgun_turret_recipe })
