-- TANK SPITTER  (dark red)
-- Ranged counterpart to the Tank Biter - high HP, slow, heavy resistances,
-- but attacks from range like a vanilla spitter. Cloned from big-spitter to
-- avoid needing custom assets. Health is a fraction of the melee Tank
-- Biter's since it doesn't need to survive being walked into.

local Util              = require("prototypes.utility.util")

local TANK_TINT          = { r = 0.9, g = 0.12, b = 0.12, a = 1.0 }

local tank_spitter       = table.deepcopy(data.raw["unit"]["big-spitter"])
tank_spitter.name        = "td-tank-spitter"
tank_spitter.max_health  = math.floor(settings.startup["td-tank-health"].value * 0.75)
tank_spitter.movement_speed = 0.08
tank_spitter.resistances  = {
    { type = "physical",  percent = 60 },
    { type = "explosion", percent = 30 },
}

Util.tint_biter_animations(tank_spitter, TANK_TINT)

data:extend({ tank_spitter })

Util.apply_biter_attack_config("td-tank-spitter", { cooldown_factor = 1.8, damage_factor = 4.0 })
