-- TANK BITER  (dark red)
-- High HP, very slow, heavy physical and explosion resistance. Cloned from
-- vanilla big-biter to avoid needing custom assets.

local Util             = require("prototypes.utility.util")

local TANK_TINT        = { r = 0.9, g = 0.12, b = 0.12, a = 1.0 }

local tank_biter       = table.deepcopy(data.raw["unit"]["big-biter"])
tank_biter.name        = "td-tank-biter"
tank_biter.max_health  = settings.startup["td-tank-health"].value
tank_biter.movement_speed = 0.08
tank_biter.resistances  = {
    { type = "physical",  percent = 60},
    { type = "explosion", percent = 30},
}

Util.tint_biter_animations(tank_biter, TANK_TINT)

data:extend({ tank_biter })

Util.apply_biter_attack_config("td-tank-biter", { cooldown_factor = 1.8, damage_factor = 4.0 })
