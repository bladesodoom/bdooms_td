-- RAPID TURRET
-- Fast single-target fire, low per-shot damage. Effective against tough
-- individual targets; struggles against dense swarms.

local Util          = require("prototypes.utility.util")

local RAPID_TINT    = { r = 0.3, g = 0.8, b = 1.0, a = 1.0 }

local rapid_turret                           = table.deepcopy(data.raw
    ["ammo-turret"]["gun-turret"])
rapid_turret.name                            = "td-rapid-turret"
rapid_turret.minable.result                  = "td-rapid-turret"
rapid_turret.attack_parameters.cooldown      = rapid_turret.attack_parameters
    .cooldown * 0.5
rapid_turret.attack_parameters.ammo_category = "td-rapid-bullet"
Util.tint_graphics(rapid_turret, RAPID_TINT)

data:extend({ rapid_turret })

local rapid_turret_item = table.deepcopy(data.raw.item["gun-turret"])
rapid_turret_item.name = "td-rapid-turret"
rapid_turret_item.place_result = "td-rapid-turret"
rapid_turret_item.order = "a[turret]-a[td-rapid-turret]"
Util.tint_icon(rapid_turret_item, RAPID_TINT)

data:extend({ rapid_turret_item })

local rapid_turret_recipe = table.deepcopy(data.raw.recipe["gun-turret"])
rapid_turret_recipe.name = "td-rapid-turret"
rapid_turret_recipe.enabled = true
rapid_turret_recipe.results = { {
    type = "item",
    name = "td-rapid-turret",
    amount = 1
} }

data:extend({ rapid_turret_recipe })
